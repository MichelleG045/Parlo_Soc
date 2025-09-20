//
//  ShareConfigs.swift
//  echo
//
//  Created by Max Eisenberg on 9/6/25.
//

import SwiftUI

struct ShareConfigs: View {
    
    @Binding var step: ResponseFlowStep
    @EnvironmentObject var appData: AppData

    let currentFilter: FeedFilter
    let onResponsePosted: () -> Void
    let responseData: ResponseData
    
    @State private var shareWithFriends: Bool = true
    @State private var makePublic: Bool = false
    @State private var includeAudio: Bool = true
    @State private var allowComments: Bool = true
    @State private var allowReactions: Bool = true
    @State private var allowBookmark: Bool = true
    @State private var isPosting = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
           
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Response:")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.txt)
                
                if !responseData.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Text:")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.gray)
                        Text(responseData.transcript)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.txt)
                            .padding(8)
                            .background(.bgLight.opacity(0.3))
                            .cornerRadius(8)
                            .lineLimit(4)
                    }
                }
                
                if let audioFile = responseData.audioFile {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.blue)
                        Text("Audio recording (\(audioFile.lastPathComponent))")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                }
                
                if responseData.transcript.isEmpty && responseData.audioFile == nil {
                    Text("No content to share")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(.bgLight.opacity(0.1))
            .cornerRadius(12)
            
            Text("Choose how your response is shared and viewed. You can change these defaults in settings.")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.gray)
            
            VStack(spacing: 12) {
                row("person.2.fill", "Only your friends", $shareWithFriends)
                row("globe.americas.fill", "Everyone on Parlo", $makePublic)
                if responseData.audioFile != nil {
                    row("mic.fill", "Include audio recording", $includeAudio)
                }
            }

            .onChange(of: makePublic) { _, newValue in
                if newValue {
                    shareWithFriends = true
                    print("Public enabled -> Friends auto-enabled")
                }
            }
            .onChange(of: shareWithFriends) { _, newValue in
                if !newValue {
                    makePublic = false
                    print("Friends disabled -> Public auto-disabled")
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                if makePublic {
                    Text("Everyone on Parlo will see this (including friends)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.blue)
                } else if shareWithFriends {
                    Text("Only your friends will see this")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.green)
                } else {
                    Text("No one will see this (not recommended)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            

            VStack(spacing: 20) {
          
                Button {
                    createPost()
                } label: {
                    HStack {
                        if isPosting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundStyle(.bgDark)
                            Text("Sharing...")
                        } else {
                            Text("Share Response")
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.bgDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.txt)
                    .cornerRadius(16)
                }
                .disabled(!shareWithFriends || isPosting || !hasValidContent())
                
      
                Button {
                    step = .record
                } label: {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Go Back")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.txt)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.bgLight.opacity(0.80))
                    .cornerRadius(16)
                }
                .disabled(isPosting)
            }
            
        }
        .padding()
        .background(.bgDark)
    }
    
    private func hasValidContent() -> Bool {
        let hasText = !responseData.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAudio = responseData.audioFile != nil
        let willIncludeAudio = includeAudio && hasAudio
        
        return hasText || willIncludeAudio
    }

    private func createPost() {
        guard !isPosting else { return }
        isPosting = true
        
        print("=== CREATING POST DEBUG ===")
        print("Raw transcript: '\(responseData.transcript)'")
        print("Audio file: \(responseData.audioFile?.lastPathComponent ?? "none")")
        print("Include audio setting: \(includeAudio)")
        
        let transcript = responseData.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Cleaned transcript: '\(transcript)'")
        print("Transcript length: \(transcript.count)")
        
 
        let hasText = !transcript.isEmpty
        let hasAudio = responseData.audioFile != nil
        let willIncludeAudio = includeAudio && hasAudio
        
        print("Content analysis:")
        print("  Has text: \(hasText)")
        print("  Has audio file: \(hasAudio)")
        print("  Will include audio: \(willIncludeAudio)")
        print("  Can post: \(hasText || willIncludeAudio)")
        

        guard hasText || willIncludeAudio else {
            print("   ERROR: No content to post")
            isPosting = false
            return
        }
        
        var media: [SocialResponse] = []
        
        
        if hasText {
            let textMedia = SocialResponse(kind: .text, text: transcript, url: nil)
            media.append(textMedia)
            print("   ✓ Added text media: '\(transcript)' (ID: \(textMedia.id))")
        } else {
            print("   ✗ No text to add - transcript is empty")
        }
        
       
        if willIncludeAudio {
            if let audioURL = responseData.audioFile, FileManager.default.fileExists(atPath: audioURL.path) {
                let audioMedia = SocialResponse(kind: .audio, text: nil, url: audioURL)
                media.append(audioMedia)
                print("   ✓ Added audio media: \(audioURL.lastPathComponent) (ID: \(audioMedia.id))")
            } else {
                print("   ✗ Audio file doesn't exist or is nil")
            }
        } else {
            print("   ✗ Audio not included (toggle: \(includeAudio), hasFile: \(hasAudio))")
        }
        
        print("Final media array:")
        for (index, mediaItem) in media.enumerated() {
            print("  [\(index)] \(mediaItem.kind): text='\(mediaItem.text ?? "nil")' url=\(mediaItem.url?.lastPathComponent ?? "nil")")
        }
        

        guard !media.isEmpty else {
            print("   ERROR: No media items created")
            isPosting = false
            return
        }

        let activeID = appData.viewingAsUser
        let displayName = appData.availableUsers.first(where: { $0.0 == activeID })?.1 ?? "Unknown"
        let displayHandle: String

        if activeID == "current-user" {
            displayHandle = "@you"
        } else {
            displayHandle = "@\(activeID.replacingOccurrences(of: "user-", with: ""))"
        }

        let author = SocialResponseAuthor(
            name: displayName,
            uid: activeID,
            socialID: displayHandle
        )

        let finalVisibility: Visibility
        if makePublic {
            finalVisibility = .everyone
            print("   VISIBILITY: Everyone (public + friends)")
        } else if shareWithFriends {
            finalVisibility = .friends
            print("   VISIBILITY: Friends only")
        } else {
            finalVisibility = .friends
            print("   FALLBACK: Friends only")
        }
        
        print("   Author: \(author.name) (uid: '\(author.uid)')")
        print("   Final media count: \(media.count)")
        
        Task {
            do {
                guard let repo = appData.repo else {
                    print("Repository not found")
                    DispatchQueue.main.async {
                        self.isPosting = false
                    }
                    return
                }
                
                let promptKey = "\(appData.viewingAsUser)_completed_today-prompt"
                UserDefaults.standard.set(true, forKey: promptKey)
                print("UNBLURRED: Prompt marked as completed for \(appData.viewingAsUser)")
                
                try await repo.createResponse(
                    promptId: "today-prompt",
                    promptText: "what are you happy about",
                    media: media,
                    author: author,
                    visibility: finalVisibility
                )
                
                print("Post created successfully with \(media.count) media items")
                
                await repo.loadFeed(filter: currentFilter, userID: appData.viewingAsUser, limit: 30)
                print("Feed refreshed after posting")
                
                DispatchQueue.main.async {
                    self.isPosting = false
                    appData.objectWillChange.send()
                    self.onResponsePosted()
                    dismiss()
                }
                
            } catch {
                print("Error creating post: \(error)")
                DispatchQueue.main.async {
                    self.isPosting = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func row(_ icon: String, _ title: String, _ isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.bgLight.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(.txt)
                    .imageScale(.medium)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.txt)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.txt)
                .disabled(!shareWithFriends && icon == "globe.americas.fill")
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .opacity((!shareWithFriends && icon == "globe.americas.fill") ? 0.5 : 1.0)
    }
}
