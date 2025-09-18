// MainFeed
// Made by Max Eisenberg
// SwiftUI

import SwiftUI
import Combine
import Shimmer
import AVKit

struct MainSocialFeed: View {
    @EnvironmentObject var appData: AppData
    @StateObject private var repo = MainSocialFeedRepository()
    
    @State private var filter: FeedFilter = .friends
    @State private var showResponseSheet = false
    
    @State var todaysPrompt = SocialPrompt(
        id: "today-prompt",
        prompt: "what are you happy about",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
    )
    
    @State private var now = Date()
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color("bgDark").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    filterBar
                    todayPromptCard
                        .padding(.bottom)
                    
                    // Feed display - enabled
                    LazyVStack(spacing: 16) {
                        ForEach(repo.feed) { item in
                            FeedCard(
                                item: item,
                                currentPromptId: todaysPrompt.id,
                                hasAnsweredCurrentPrompt: appData.completedPrompts.contains(todaysPrompt.id)
                            )
                            .environmentObject(appData)
                        }
                    }
                }
                .padding(.top)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            if appData.repo == nil {
                appData.repo = repo
            }
            Task { await repo.loadFeed(filter: filter, userID: appData.userID, limit: 30) }
        }
        .onChange(of: filter) { _ in
            Task { await repo.loadFeed(filter: filter, userID: appData.userID, limit: 30) }
        }
        .sheet(isPresented: $showResponseSheet) {
            ResponseManager(promptTitle: todaysPrompt.prompt)
                .environmentObject(appData)
        }
    }
    
    // filter bar
    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(FeedFilter.allCases, id: \.self) { f in
                Button { filter = f } label: {
                    Text(f.title)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.txt)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(f == filter ? Color.bgLight : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(f == filter ? .clear : .txt.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // daily prompt card
    @ViewBuilder
    private var todayPromptCard: some View {
        let hasAnswered = appData.completedPrompts.contains(todaysPrompt.id)
        
        VStack(alignment: .leading, spacing: 20) {
            // header
            HStack {
                Text("Today's Question")
                Spacer()
                HStack {
                    Image(systemName: "clock")
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, Int(todaysPrompt.expiresAt.timeIntervalSince(context.date)))
                        Text("\(format(remaining))")
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.gray)
            
            Text(todaysPrompt.prompt)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.txt)
                .multilineTextAlignment(.leading)
            
            // Always show the Share Response button
            Button {
                print("Share Response button tapped")
                showResponseSheet = true
            } label: {
                Text(hasAnswered ? "Add Another Response" : "Share Response")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.txt))
                    .foregroundStyle(.bgDark)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%d:%02d", m, s)
    }
}

struct FeedCard: View {
    @EnvironmentObject var appData: AppData
    let item: FeedItem
    let currentPromptId: String
    let hasAnsweredCurrentPrompt: Bool
    
    @State private var bookmarked = false
    @State private var showCommentsSheet = false
    @State var loadingPFP = false
    @State var userPFP: UIImage? = nil
    @State var liked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // user info
            HStack(spacing: 10) {
                Group {
                    if loadingPFP {
                        Circle().fill(.gray.opacity(0.30))
                            .frame(width: 35, height: 35)
                            .shimmering(active: true)
                    } else if let pfp = userPFP {
                        Image(uiImage: pfp)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundStyle(.gray)
                    }
                }
                .onAppear {
                    Task {
                        loadingPFP = true
                        if let cached = appData.cachedFriendPFP[item.author.uid] {
                            userPFP = cached
                        } else {
                            let fetched = await fetchUserPFP(userID: item.author.uid)
                            userPFP = fetched
                            if let fetched { appData.cachedFriendPFP[item.author.uid] = fetched }
                        }
                        loadingPFP = false
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.author.name)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.txt)
                    
                    Text(item.author.socialID)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.createdAt, style: .date)
                    Text(item.createdAt, style: .time)
                }
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.gray)
            }
            
            // response content with blur logic
            ZStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.promptText)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.txt)
                    
                    ForEach(item.media, id: \.id) { media in
                        switch media.kind {
                        case .text:
                            if let text = media.text {
                                Text(text)
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.txt)
                            }
                        case .audio:
                            if let url = media.url {
                                AudioPlayerView(url: url)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    
                    // reactions
                    HStack(spacing: 20) {
                        Button {
                            liked.toggle()
                            Task {
                                if let repo = appData.repo {
                                    await repo.toggleLike(responseId: item.id, userId: appData.userID)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: liked ? "heart.fill" : "heart")
                                    .foregroundStyle(liked ? .txt : .gray)
                                Text("\(item.likeCount)")
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        Button {
                            showCommentsSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "message")
                                    .foregroundStyle(.gray)
                                Text("\(item.commentCount)")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .sheet(isPresented: $showCommentsSheet) {
                            CommentsSheet(feedItem: item)
                                .environmentObject(appData)
                        }
                        
                        Spacer()
                        
                        Button {
                            bookmarked.toggle()
                        } label: {
                            Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(bookmarked ? .txt : .gray)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
                .padding()
                .background(.bgLight)
                .cornerRadius(16)
                .blur(radius: !hasAnsweredCurrentPrompt ? 3 : 0)
                .opacity(!hasAnsweredCurrentPrompt ? 0.80 : 1)
                
                // lock overlay - only show if user hasn't answered
                if !hasAnsweredCurrentPrompt {
                    VStack(spacing: 15) {
                        Image(systemName: "lock.fill")
                        Text("Respond to View")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.txt)
                }
            }
        }
        .padding()
    }
}

enum FeedFilter: CaseIterable {
    case friends, all, myEntries
    
    var title: String {
        switch self {
        case .friends: "Friends"
        case .all: "All"
        case .myEntries: "My Responses"
        }
    }
}

private extension Date {
    func timeAgoString(now: Date = .now) -> String {
        let seconds = Int(now.timeIntervalSince(self))
        if seconds < 60 { return "Just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }
}

// MARK: - Simple Audio Player View
struct AudioPlayerView: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            Button {
                togglePlay()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.txt)
            }
            Text(url.lastPathComponent)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.gray)
        }
        .onDisappear {
            player?.stop()
            isPlaying = false
        }
    }
    
    private func togglePlay() {
        if let player, player.isPlaying {
            player.stop()
            isPlaying = false
        } else {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
                isPlaying = true
            } catch {
                print("Audio playback failed:", error)
            }
        }
    }
}

// MARK: - Comments Sheet
struct CommentsSheet: View {
    @EnvironmentObject var appData: AppData
    let feedItem: FeedItem
    
    @State private var newCommentText = ""
    @State private var comments: [SocialComment] = []
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - without cancel button
                HStack {
                    Spacer()
                    
                    Text("Comments")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.txt)
                    
                    Spacer()
                    
                    Text("\(comments.count)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(.bgDark)
                
                Divider()
                    .background(.gray.opacity(0.3))
                
                // Original post preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feedItem.author.name)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.txt)
                            
                            Text(feedItem.author.socialID)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    Text(feedItem.promptText)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.txt.opacity(0.8))
                        .lineLimit(2)
                }
                .padding()
                .background(.bgLight.opacity(0.3))
                
                Divider()
                    .background(.gray.opacity(0.3))
                
                // Comments list
                if comments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "message")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        Text("No comments yet")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        Text("Be the first to share your thoughts!")
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment, onLikeChanged: refreshComments)
                                    .environmentObject(appData)
                            }
                        }
                        .padding()
                    }
                }
                
                // Comment input
                VStack(spacing: 0) {
                    Divider()
                        .background(.gray.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        // User avatar
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray)
                        
                        // Text input
                        TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(.txt)
                            .lineLimit(1...4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.bgLight.opacity(0.6))
                            .cornerRadius(20)
                        
                        // Send button
                        Button {
                            submitComment()
                        } label: {
                            Image(systemName: isSubmitting ? "hourglass" : "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(canSubmit ? .txt : .gray)
                                .rotationEffect(.degrees(isSubmitting ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: isSubmitting)
                        }
                        .disabled(!canSubmit || isSubmitting)
                    }
                    .padding()
                    .background(.bgDark)
                }
            }
            .background(.bgDark)
        }
        .onAppear {
            loadComments()
        }
    }
    
    private var canSubmit: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadComments() {
        if let repo = appData.repo,
           let currentFeedItem = repo.feed.first(where: { $0.id == feedItem.id }) {
            comments = currentFeedItem.comments.sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    private func refreshComments() {
        loadComments()
    }
    
    private func submitComment() {
        guard canSubmit, !isSubmitting else { return }
        
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isSubmitting = true
        
        let author = SocialResponseAuthor(
            name: appData.name.isEmpty ? "You" : appData.name,
            uid: appData.userID.isEmpty ? "current-user" : appData.userID,
            socialID: appData.socialID.isEmpty ? "@you" : appData.socialID
        )
        
        Task {
            await appData.repo?.addComment(
                responseId: feedItem.id,
                author: author,
                text: trimmedText
            )
            
            DispatchQueue.main.async {
                self.newCommentText = ""
                self.isSubmitting = false
                self.loadComments()
            }
        }
    }
}

struct CommentRow: View {
    @EnvironmentObject var appData: AppData
    let comment: SocialComment
    let onLikeChanged: () -> Void
    @State private var liked = false
    @State private var currentLikeCount: Int
    
    init(comment: SocialComment, onLikeChanged: @escaping () -> Void) {
        self.comment = comment
        self.onLikeChanged = onLikeChanged
        self._currentLikeCount = State(initialValue: comment.likeCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Comment header
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.author.name)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.txt)
                    
                    Text(comment.author.socialID)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text(comment.createdAt.timeAgoString())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.gray)
            }
            
            // Comment text
            Text(comment.text)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.txt)
                .fixedSize(horizontal: false, vertical: true)
            
            // Comment actions
            HStack(spacing: 16) {
                Button {
                    Task {
                        await appData.repo?.toggleCommentLike(commentId: comment.id, userId: appData.userID)
                        
                        DispatchQueue.main.async {
                            self.liked = appData.repo?.hasUserLikedComment(commentId: comment.id, userId: appData.userID) ?? false
                            
                            if let repo = appData.repo,
                               let feedItem = repo.feed.first(where: { $0.comments.contains(where: { $0.id == comment.id }) }),
                               let updatedComment = feedItem.comments.first(where: { $0.id == comment.id }) {
                                self.currentLikeCount = updatedComment.likeCount
                            }
                            
                            self.onLikeChanged()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                        Text("\(currentLikeCount)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(liked ? .red : .gray)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            liked = appData.repo?.hasUserLikedComment(commentId: comment.id, userId: appData.userID) ?? false
            currentLikeCount = comment.likeCount
        }
    }
}
