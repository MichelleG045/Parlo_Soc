//
//  FeedFunctions.swift (Mock Only)
//  echo / Parlo_Social
//
//  Created by Max Eisenberg on 9/15/25.
//

import Foundation
import UIKit  // ADD THIS LINE
// import FirebaseFirestore
// import FirebaseStorage

@MainActor
final class MainSocialFeedRepository: ObservableObject {
    // private let db = Firestore.firestore()
    // private let collection = "social_responses"
    
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
        // 🔹 Firestore write (disabled for now)
        /*
        let ref = db.collection(collection).document()
        let item = FeedItem(...)
        try ref.setData(from: item)
        */
        
        // 🔹 Mock insert into local feed
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
        // 🔹 Firestore read (disabled for now)
        /*
        var query = db.collection(collection)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
        ...
        */
        
        // 🔹 Mock filter
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
        // 🔹 Firestore like/unlike (disabled for now)
        /*
        let responseRef = db.collection(collection).document(responseId)
        let likeRef = responseRef.collection("likes").document(userId)
        ...
        */
        
        // 🔹 Mock like/unlike
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
        // 🔹 Firestore add comment (disabled for now)
        /*
        let responseRef = db.collection(collection).document(responseId)
        let commentsRef = responseRef.collection("comments")
        let newRef = commentsRef.document()
        let comment = SocialComment(...)
        try newRef.setData(from: comment)
        try await responseRef.updateData(...)
        */
        
        // 🔹 Mock add comment
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
    
    // MARK: - Fetch Comments
    func fetchComments(responseId: String, completion: @escaping ([SocialComment]) -> Void) {
        // 🔹 Firestore snapshot listener (disabled for now)
        /*
        let commentsRef = db.collection(collection)
            .document(responseId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
        commentsRef.addSnapshotListener { snapshot, error in ... }
        */
        
        // 🔹 Mock return comments from memory
        if let item = feed.first(where: { $0.id == responseId }) {
            completion(item.comments)
        } else {
            completion([])
        }
    }
}

/// Mocked PFP fetch – Firestore/Storage disabled for now.
func fetchUserPFP(userID: String) async -> UIImage? {
    // 🔹 Firestore/Storage profile fetch (disabled for now)
    /*
    let snapshot = try await Firestore.firestore()
        .collection("users")
        .document(userID)
        .getDocument()
    ...
    */
    
    // 🔹 Mock: always return nil for now
    return nil
}
