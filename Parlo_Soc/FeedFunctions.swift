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
    
    // MARK: - Create Response
    func createResponse(
        promptId: String,
        promptText: String,
        media: [SocialResponse],
        author: SocialResponseAuthor,
        visibility: Visibility
    ) async throws {
        
        print("Repository creating response...")
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
        
        // Add to master list (newest first)
        allPosts.insert(item, at: 0)
        
        // Add to current display feed (newest first)
        feed.insert(item, at: 0)
        
        print("Post added to feed. Total posts: \(allPosts.count)")
    }
    
    // MARK: - Load Feed with Proper Filtering
    func loadFeed(filter: FeedFilter, userID: String, limit: Int = 30) async {
        
        switch filter {
        case .all:
            // Show all posts (friends + user's own posts)
            feed = allPosts
        case .friends:
            // Show only friends' posts (exclude user's own posts)
            feed = allPosts.filter { $0.author.uid != userID }
        case .myEntries:
            // Show only user's posts
            feed = allPosts.filter { $0.author.uid == userID }
        }
        
        print("Feed loaded with \(feed.count) items for filter: \(filter)")
        print("   All posts count: \(allPosts.count)")
        print("   Filter: \(filter)")
        print("   User ID: \(userID)")
    }
    
    // MARK: - Toggle Like
    func toggleLike(responseId: String, userId: String) async {
        
        // Update in both master list and display list
        if let idx = allPosts.firstIndex(where: { $0.id == responseId }) {
            var item = allPosts[idx]
            if item.likes.contains(userId) {
                item.likes.remove(userId)
                item.likeCount -= 1
            } else {
                item.likes.insert(userId)
                item.likeCount += 1
            }
            allPosts[idx] = item
        }
        
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
        let hasLiked = UserDefaults.standard.bool(forKey: likeKey)
        
        // Update in master list
        for (feedIndex, var feedItem) in allPosts.enumerated() {
            if let commentIndex = feedItem.comments.firstIndex(where: { $0.id == commentId }) {
                var comment = feedItem.comments[commentIndex]
                
                if hasLiked {
                    comment.likeCount = max(0, comment.likeCount - 1)
                    UserDefaults.standard.set(false, forKey: likeKey)
                } else {
                    comment.likeCount += 1
                    UserDefaults.standard.set(true, forKey: likeKey)
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
                
                if hasLiked {
                    comment.likeCount = max(0, comment.likeCount - 1)
                } else {
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
        return UserDefaults.standard.bool(forKey: likeKey)
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
    
    // MARK: - Mock Data for Testing
    func createMockData() {
        let mockResponses = [
            // Friend 1 - Text + Audio
            FeedItem(
                id: "mock-1",
                author: SocialResponseAuthor(name: "Sarah Chen", uid: "user-sarah", socialID: "@sarah_c"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "I'm really happy about finally finishing my garden project! Been working on it for months and seeing the flowers bloom is so rewarding."),
                    SocialResponse(kind: .audio, text: nil, url: URL(string: "file://mock-audio-sarah.m4a"))
                ],
                visibility: .friends,
                likeCount: 8,
                commentCount: 3,
                comments: [
                    SocialComment(id: "comment-1", author: SocialResponseAuthor(name: "Mike", uid: "user-mike", socialID: "@mike_j"), text: "Your garden looks amazing!", createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(), likeCount: 2),
                    SocialComment(id: "comment-2", author: SocialResponseAuthor(name: "Lisa", uid: "user-lisa", socialID: "@lisa_k"), text: "So proud of you! Can't wait to see it in person", createdAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(), likeCount: 1)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date()),
                likes: ["user-mike", "user-lisa", "user-tom", "current-user"]
            ),
            
            // Friend 2 - Text Only
            FeedItem(
                id: "mock-2",
                author: SocialResponseAuthor(name: "Alex Rivera", uid: "user-alex", socialID: "@alex_r"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Got accepted into my dream graduate program! Still can't believe it's real. All those late study nights finally paid off.")
                ],
                visibility: .friends,
                likeCount: 12,
                commentCount: 5,
                comments: [
                    SocialComment(id: "comment-3", author: SocialResponseAuthor(name: "Maya", uid: "user-maya", socialID: "@maya_p"), text: "CONGRATULATIONS!! This is huge!", createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(), likeCount: 3),
                    SocialComment(id: "comment-4", author: SocialResponseAuthor(name: "David", uid: "user-david", socialID: "@david_l"), text: "You totally deserve this! Your hard work shows", createdAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date(), likeCount: 1)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date()),
                likes: ["user-maya", "user-david", "user-sarah", "user-tom"]
            ),
            
            // Friend 3 - Audio Heavy
            FeedItem(
                id: "mock-3",
                author: SocialResponseAuthor(name: "Jordan Kim", uid: "user-jordan", socialID: "@jordan_k"),
                promptId: "today-prompt",
                promptText: "what are you happy about",
                media: [
                    SocialResponse(kind: .text, text: "Just had the most amazing conversation with my grandmother about her childhood stories."),
                    SocialResponse(kind: .audio, text: nil, url: URL(string: "file://mock-audio-jordan.m4a"))
                ],
                visibility: .friends,
                likeCount: 6,
                commentCount: 1,
                comments: [
                    SocialComment(id: "comment-5", author: SocialResponseAuthor(name: "Emma", uid: "user-emma", socialID: "@emma_w"), text: "Family stories are the best treasures", createdAt: Calendar.current.date(byAdding: .minute, value: -20, to: Date()) ?? Date(), likeCount: 0)
                ],
                createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                lastActivityAt: Calendar.current.date(byAdding: .minute, value: -20, to: Date()),
                likes: ["user-emma", "user-sarah", "current-user"]
            )
        ]
        
        // Set both master and display lists
        allPosts = mockResponses
        feed = mockResponses // Start by showing all
        print("Mock data created: \(allPosts.count) posts loaded")
    }
}

/// Mocked PFP fetch – Firestore/Storage disabled for now.
func fetchUserPFP(userID: String) async -> UIImage? {
    // Mock: always return nil for now
    return nil
}
