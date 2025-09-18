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
    
    /// Backing store for the feed list shown in UI (mock version).
    @Published var feed: [FeedItem] = []
    
    // MARK: - Create Response
    func createResponse(
        promptId: String,
        promptText: String,
        media: [SocialResponse],
        author: SocialResponseAuthor,
        visibility: Visibility
    ) async throws {
        
        // Mock insert into local feed
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
        feed.insert(item, at: 0) // newest first
    }
    
    // MARK: - Load Feed
    func loadFeed(filter: FeedFilter, userID: String, limit: Int = 30) async {
        
        // Mock filter
        switch filter {
        case .all:
            break
        case .friends:
            feed = feed.filter { $0.visibility == .friends }
        case .myEntries:
            feed = feed.filter { $0.author.uid == userID }
        }
    }
    
    // MARK: - Toggle Like
    func toggleLike(responseId: String, userId: String) async {
        
        // Mock like/unlike
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
        
        // Mock add comment
        if let idx = feed.firstIndex(where: { $0.id == responseId }) {
            var item = feed[idx]
            let comment = SocialComment(
                id: UUID().uuidString,
                author: author,
                text: text,
                createdAt: Date(),
                likeCount: 0
            )
            item.comments.append(comment)
            item.commentCount += 1
            feed[idx] = item
        }
    }
    
    // MARK: - Toggle Comment Like
    func toggleCommentLike(commentId: String, userId: String) async {
        for (feedIndex, var feedItem) in feed.enumerated() {
            if let commentIndex = feedItem.comments.firstIndex(where: { $0.id == commentId }) {
                var comment = feedItem.comments[commentIndex]
                
                // Use UserDefaults to track who liked what (simple mock solution)
                let likeKey = "comment_like_\(commentId)_\(userId)"
                let hasLiked = UserDefaults.standard.bool(forKey: likeKey)
                
                if hasLiked {
                    comment.likeCount = max(0, comment.likeCount - 1)
                    UserDefaults.standard.set(false, forKey: likeKey)
                } else {
                    comment.likeCount += 1
                    UserDefaults.standard.set(true, forKey: likeKey)
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
        
        // Mock return comments from memory
        if let item = feed.first(where: { $0.id == responseId }) {
            completion(item.comments)
        } else {
            completion([])
        }
    }
}

/// Mocked PFP fetch – Firestore/Storage disabled for now.
func fetchUserPFP(userID: String) async -> UIImage? {
    // Mock: always return nil for now
    return nil
}
