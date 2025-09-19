//
//  FeedFunctions.swift (Mock Only)
//  echo / Parlo_Social
//
//  Created by Max Eisenberg on 9/15/25.
//

import Foundation
import UIKit

@MainActor
final class MainSocialFeedRepository: ObservableObject {
    
    /// All posts (master list - never modified after creation)
    private var allPosts: [FeedItem] = []
    
    /// Filtered posts for display
    @Published var feed: [FeedItem] = []
    
    // Define friends vs strangers for filtering logic
    private let friendUIDs = ["user-sarah", "user-alex", "user-jordan"]
    
    // MARK: - Create Response
    func createResponse(
        promptId: String,
        promptText: String,
        media: [SocialResponse],
        author: SocialResponseAuthor,
        visibility: Visibility
    ) async throws {
        
        print("Repository creating response...")
        print("   Author: \(author.name) (uid: '\(author.uid)')")
        print("   Media count: \(media.count)")
        for (index, item) in media.enumerated() {
            print("   Media \(index): \(item.kind) - \(item.text ?? item.url?.lastPathComponent ?? "nil")")
        }
        
        // Create new post
        let item = FeedItem(
            id: UUID().uuidString,
            author: author,
            promptId: promptId,
            promptText: promptText,
            media: media,
            visibility: visibility,
            likeCount: 0,
            commentCount: 0,
            comments: [],
            createdAt: Date(),
            lastActivityAt: nil,
            likes: []
        )
        
        // Add to master list ONLY (newest first)
        allPosts.insert(item, at: 0)
        
        // DO NOT add to current feed display - let the filter logic handle it
        print("Post added to master list. Total posts: \(allPosts.count)")
        print("Current feed will be updated by filter logic")
    }
    
    // MARK: - Load Feed with FRIENDS vs STRANGERS Filtering
    func loadFeed(filter: FeedFilter, userID: String, limit: Int = 30) async {
        
        print("Loading feed with filter: \(filter)")
        print("Current userID: '\(userID)'")
        print("All posts authors:")
        for post in allPosts {
            let isFriend = friendUIDs.contains(post.author.uid)
            let relationship = post.author.uid == userID ? "YOU" : (isFriend ? "FRIEND" : "STRANGER")
            print("   - \(post.author.name) (uid: '\(post.author.uid)') - \(relationship)")
        }
        
        switch filter {
        case .all:
            // Show everyone's posts (friends + strangers) EXCEPT user's own posts
            feed = allPosts.filter { post in
                let isNotUser = post.author.uid != userID
                print("   ALL: \(post.author.name) - isNotUser: \(isNotUser)")
                return isNotUser
            }
            print("Showing ALL posts (friends + strangers, excluding user): \(feed.count)")
            
        case .friends:
            // Show ONLY friends' posts (exclude user + strangers)
            feed = allPosts.filter { post in
                let isNotUser = post.author.uid != userID
                let isFriend = friendUIDs.contains(post.author.uid)
                let showInFriends = isNotUser && isFriend
                print("   FRIENDS: \(post.author.name) - isNotUser: \(isNotUser), isFriend: \(isFriend), show: \(showInFriends)")
                return showInFriends
            }
            print("Showing FRIENDS posts only (excluding user + strangers): \(feed.count)")
            
        case .myEntries:
            // Show only user's posts
            feed = allPosts.filter { post in
                let isUser = post.author.uid == userID
                print("   MY ENTRIES: \(post.author.name) - isUser: \(isUser)")
                return isUser
            }
            print("Showing MY posts only: \(feed.count)")
        }
    }
    
    // MARK: - Toggle Like
    func toggleLike(responseId: String, userId: String) async {
        
        print("Toggling post like - responseId: \(responseId), userId: \(userId)")
        
        // Update in master list
        if let idx = allPosts.firstIndex(where: { $0.id == responseId }) {
            var item = allPosts[idx]
            
            print("   Post by \(item.author.name), current likes: \(item.likes), count: \(item.likeCount)")
            
            if item.likes.contains(userId) {
                item.likes.remove(userId)
                item.likeCount -= 1
                print("   Unliked post, new count: \(item.likeCount)")
            } else {
                item.likes.insert(userId)
                item.likeCount += 1
                print("   Liked post, new count: \(item.likeCount)")
            }
            allPosts[idx] = item
        }
        
        // Update in display list
        if let idx = feed.firstIndex(where: { $0.id == responseId }) {
            var item = feed[idx]
            if item.likes.contains(userId) {
                item.likes.remove(userId)
                item.likeCount -= 1
            } else {
                item.likes.insert(userId)
                item.likeCount += 1
            }
            feed[idx] = item
        }
    }
    
    // MARK: - Add Comment
    func addComment(responseId: String, author: SocialResponseAuthor, text: String) async {
        
        let comment = SocialComment(
            id: UUID().uuidString,
            author: author,
            text: text,
            createdAt: Date(),
            likeCount: 0
        )
        
        // Update in master list
        if let idx = allPosts.firstIndex(where: { $0.id == responseId }) {
            var item = allPosts[idx]
            item.comments.append(comment)
            item.commentCount += 1
            allPosts[idx] = item
        }
        
        // Update in display list
        if let idx = feed.firstIndex(where: { $0.id == responseId }) {
            var item = feed[idx]
            item.comments.append(comment)
            item.commentCount += 1
            feed[idx] = item
        }
    }
    
    // MARK: - Toggle Comment Like
    func toggleCommentLike(commentId: String, userId: String) async {
        let likeKey = "comment_like_\(commentId)_\(userId)"
        let wasLiked = UserDefaults.standard.bool(forKey: likeKey)
        
        print("Toggling comment like - commentId: \(commentId), wasLiked: \(wasLiked)")
        
        // Update in master list
        for (feedIndex, var feedItem) in allPosts.enumerated() {
            if let commentIndex = feedItem.comments.firstIndex(where: { $0.id == commentId }) {
                var comment = feedItem.comments[commentIndex]
                
                if wasLiked {
                    // Was liked, now unlike
                    comment.likeCount = max(0, comment.likeCount - 1)
                    UserDefaults.standard.set(false, forKey: likeKey)
                    print("   Unliked comment: \(comment.likeCount)")
                } else {
                    // Was not liked, now like
                    comment.likeCount += 1
                    UserDefaults.standard.set(true, forKey: likeKey)
                    print("   Liked comment: \(comment.likeCount)")
                }
                
                feedItem.comments[commentIndex] = comment
                allPosts[feedIndex] = feedItem
                break
            }
        }
        
        // Update in display list
        for (feedIndex, var feedItem) in feed.enumerated() {
            if let commentIndex = feedItem.comments.firstIndex(where: { $0.id == commentId }) {
                var comment = feedItem.comments[commentIndex]
                
                if wasLiked {
                    // Was liked, now unlike
                    comment.likeCount = max(0, comment.likeCount - 1)
                } else {
                    // Was not liked, now like
                    comment.likeCount += 1
                }
                
                feedItem.comments[commentIndex] = comment
                feed[feedIndex] = feedItem
                return
            }
        }
    }
    
    // MARK: - Check if user liked comment
    func hasUserLikedComment(commentId: String, userId: String) -> Bool {
        let likeKey = "comment_like_\(commentId)_\(userId)"
        let isLiked = UserDefaults.standard.bool(forKey: likeKey)
        return isLiked
    }
    
    // MARK: - Fetch Comments
    func fetchComments(responseId: String, completion: @escaping ([SocialComment]) -> Void) {
        
        // Look in both master and display lists
        if let item = allPosts.first(where: { $0.id == responseId }) {
            completion(item.comments)
        } else if let item = feed.first(where: { $0.id == responseId }) {
            completion(item.comments)
        } else {
            completion([])
        }
    }
    
    // MARK: - Mock Data with FRIENDS vs STRANGERS
    func createMockData() {
        // Clear all previous comment like states to ensure fresh start
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("comment_like_") {
                defaults.removeObject(forKey: key)
                print("Cleared UserDefaults key: \(key)")
            }
        }
        
        // Clear any existing prompt completion states for fresh testing
        for key in defaults.dictionaryRepresentation().keys {
            if key.contains("_completed_") {
                defaults.removeObject(forKey: key)
                print("Cleared prompt completion key: \(key)")
            }
        }
        
        // Mark completed prompts for friends + strangers (everyone has answered)
        let answeredUsers = ["user-sarah", "user-alex", "user-jordan", "stranger-emily", "stranger-mark", "stranger-david"]
        for userId in answeredUsers {
            let promptKey = "\(userId)_completed_today-prompt"
            UserDefaults.standard.set(true, forKey: promptKey)
            print("Marked prompt as completed for: \(userId)")
        }
        
        let mockResponses = [
            // FRIENDS POSTS
            FeedItem(
                id: "friend-1",
                author: SocialResponseAuthor(name: "Sarah Chen", uid: "user-sarah", socialID: "@sarah_c"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "I'm really happy about finally finishing my garden project! Been working on it for months and seeing the flowers bloom is so rewarding."),
                    SocialResponse(kind: .audio, text: nil, url: URL(string: "file://mock-audio-sarah.m4a"))
                ],
                visibility: .friends,
                likeCount: 3,
                commentCount: 2,
                comments: [
                    SocialComment(id: "comment-1", author: SocialResponseAuthor(name: "Mike", uid: "user-mike", socialID: "@mike_j"), text: "Your garden looks amazing!", createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(), likeCount: 0),
                    SocialComment(id: "comment-2", author: SocialResponseAuthor(name: "Lisa", uid: "user-lisa", socialID: "@lisa_k"), text: "So proud of you! Can't wait to see it in person", createdAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(), likeCount: 0)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date()),
                likes: ["user-mike", "user-lisa", "user-tom"]
            ),
            
            FeedItem(
                id: "friend-2",
                author: SocialResponseAuthor(name: "Alex Rivera", uid: "user-alex", socialID: "@alex_r"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Got accepted into my dream graduate program! Still can't believe it's real. All those late study nights finally paid off.")
                ],
                visibility: .friends,
                likeCount: 4,
                commentCount: 2,
                comments: [
                    SocialComment(id: "comment-3", author: SocialResponseAuthor(name: "Maya", uid: "user-maya", socialID: "@maya_p"), text: "CONGRATULATIONS!! This is huge!", createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(), likeCount: 0),
                    SocialComment(id: "comment-4", author: SocialResponseAuthor(name: "David", uid: "user-david", socialID: "@david_l"), text: "You totally deserve this! Your hard work shows", createdAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date(), likeCount: 0)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date()),
                likes: ["user-maya", "user-david", "user-sarah", "user-tom"]
            ),
            
            FeedItem(
                id: "friend-3",
                author: SocialResponseAuthor(name: "Jordan Kim", uid: "user-jordan", socialID: "@jordan_k"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Just had the most amazing conversation with my grandmother about her childhood stories."),
                    SocialResponse(kind: .audio, text: nil, url: URL(string: "file://mock-audio-jordan.m4a"))
                ],
                visibility: .friends,
                likeCount: 2,
                commentCount: 1,
                comments: [
                    SocialComment(id: "comment-5", author: SocialResponseAuthor(name: "Emma", uid: "user-emma", socialID: "@emma_w"), text: "Family stories are the best treasures", createdAt: Calendar.current.date(byAdding: .minute, value: -20, to: Date()) ?? Date(), likeCount: 0)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -20, to: Date()),
                likes: ["user-emma", "user-sarah"]
            ),
            
            // STRANGERS POSTS (Public posts from unknown users)
            FeedItem(
                id: "stranger-1",
                author: SocialResponseAuthor(name: "Emily Watson", uid: "stranger-emily", socialID: "@emily_w"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Just started my new job today! Excited for this new chapter and all the opportunities ahead.")
                ],
                visibility: .everyone,
                likeCount: 15,
                commentCount: 1,
                comments: [
                    SocialComment(id: "comment-6", author: SocialResponseAuthor(name: "Random User", uid: "random-1", socialID: "@random1"), text: "Congratulations on the new job!", createdAt: Calendar.current.date(byAdding: .minute, value: -25, to: Date()) ?? Date(), likeCount: 0)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -25, to: Date()),
                likes: ["random-1", "random-2", "random-3"]
            ),
            
            FeedItem(
                id: "stranger-2",
                author: SocialResponseAuthor(name: "Mark Johnson", uid: "stranger-mark", socialID: "@mark_j"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Finally finished reading my first novel in years! There's something magical about getting lost in a good story.")
                ],
                visibility: .everyone,
                likeCount: 8,
                commentCount: 0,
                comments: [],
                createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                lastActivityAt: nil,
                likes: ["random-4", "random-5"]
            ),
            
            FeedItem(
                id: "stranger-3",
                author: SocialResponseAuthor(name: "David Chen", uid: "stranger-david", socialID: "@david_c"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "My dog learned a new trick today! After weeks of training, he finally mastered 'shake hands'. Small victories!")
                ],
                visibility: .everyone,
                likeCount: 22,
                commentCount: 3,
                comments: [
                    SocialComment(id: "comment-7", author: SocialResponseAuthor(name: "Pet Lover", uid: "random-6", socialID: "@petlover"), text: "Dogs are the best! What breed?", createdAt: Calendar.current.date(byAdding: .minute, value: -40, to: Date()) ?? Date(), likeCount: 1),
                    SocialComment(id: "comment-8", author: SocialResponseAuthor(name: "Training Pro", uid: "random-7", socialID: "@trainer"), text: "Persistence pays off! Keep it up!", createdAt: Calendar.current.date(byAdding: .minute, value: -35, to: Date()) ?? Date(), likeCount: 0),
                    SocialComment(id: "comment-9", author: SocialResponseAuthor(name: "Dog Mom", uid: "random-8", socialID: "@dogmom"), text: "Aww this made my day!", createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(), likeCount: 2)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()),
                likes: ["random-6", "random-7", "random-8", "random-9"]
            )
        ]
        
        // Set both master and display lists
        allPosts = mockResponses
        feed = mockResponses // Start by showing all
        print("Mock data created: \(allPosts.count) posts loaded")
        print("FRIENDS vs STRANGERS test data:")
        print("  - FRIENDS: Sarah Chen, Alex Rivera, Jordan Kim (3 posts)")
        print("  - STRANGERS: Emily Watson, Mark Johnson, David Chen (3 posts)")
        print("  - 'Friends' tab should show only friends")
        print("  - 'All' tab should show friends + strangers")
        print("  - Test from different user perspectives!")
    }
}

/// Mocked PFP fetch – Firestore/Storage disabled for now.
func fetchUserPFP(userID: String) async -> UIImage? {
    // Mock: always return nil for now
    return nil
}
