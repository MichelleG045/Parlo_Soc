//
//  SocialDS.swift
//  echo
//
//  Created by Max Eisenberg on 9/12/25.
//

import Foundation
import SwiftUI
import CryptoKit

// MARK: - Users & Friends

public struct ParloUser: Identifiable, Hashable, Codable {
    public var id: String
    public var name: String
    public var socialId: String
    public var pfpUrl: String?
    public var phone: String?
}

public enum RequestStatus: String, Codable, CaseIterable {
    case pending, accepted, declined, canceled
}

public struct FriendRequest: Identifiable, Hashable, Codable {
    public var id: String
    public var fromUserId: String
    public var toUserId: String
    public var status: RequestStatus
    public var createdAt: Date
    public var updatedAt: Date

    public static func docId(_ from: String, _ to: String) -> String { "\(from)_\(to)" }
}

// MARK: - Notifications

struct SocialNotification: Identifiable, Hashable, Codable {
    let id: String
    let kind: SocialNotificationKind
    let fromUserId: String
    let pfpUrl: String?
    let displayName: String
    let responseId: String
    let createdAt: Date
    let commentPreview: String?
}

enum SocialNotificationKind: String, Codable, Hashable {
    case like
    case comment
}

// MARK: - Prompts & Feed

struct SocialPrompt {
    let id: String
    let prompt: String
    let createdAt: Date
    let expiresAt: Date
}

struct FeedItem: Codable, Identifiable, Hashable {
    var id: String
    let author: SocialResponseAuthor
    let promptId: String
    let promptText: String
    let media: [SocialResponse]
    let visibility: Visibility
    var likeCount: Int
    var commentCount: Int
    var comments: [SocialComment] = []
    let createdAt: Date
    let lastActivityAt: Date?
    var likes: Set<String> = []
}

struct SocialResponseAuthor: Codable, Hashable {
    let name: String
    let uid: String
    let socialID: String
}

enum Visibility: String, Codable {
    case everyone
    case friends
}

// MARK: - Response Media

struct SocialResponse: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    enum Kind: String, Codable { case text, audio, image, video }
    
    let kind: Kind
    let text: String?
    let url: URL?
    
    init(kind: Kind, text: String? = nil, url: URL? = nil) {
        self.kind = kind
        self.text = text
        self.url = url
    }
}

// MARK: - Comments

struct SocialComment: Codable, Identifiable, Hashable {
    var id: String
    let author: SocialResponseAuthor
    let text: String
    let createdAt: Date
    var likeCount: Int
}

// MARK: - Friends

struct NetworkFriend: Identifiable, Hashable {
    let id: UUID
    let userID: String
    let name: String
    let pfp: UIImage?
}

// MARK: - Insights

struct NetworkInsights: Codable {
    let summary: String
    let insights: Insights
    let questions: [String]
}

struct Insights: Codable {
    let themes: [SharedTheme]
    let contrasts: [Contrast]
    let sentiment: Sentiment
    let trends: [Trend]
    let outliers: [Outlier]
}

struct SharedTheme: Codable, Identifiable {
    var id: String { theme }
    let theme: String
    let keywords: [String]
    let count: Int
    let participants: [String]
    let example_quotes: [String]
}

struct Contrast: Codable, Identifiable {
    var id: UUID = UUID()
    let dimension: String
    let groups: [ContrastGroup]
}

struct ContrastGroup: Codable, Identifiable {
    var id: UUID = UUID()
    let label: String
    let participants: [String]
    let evidence: [String]
}

struct Sentiment: Codable {
    let overall: String
    let scores: SentimentScores
}

struct SentimentScores: Codable {
    let positive: Double
    let neutral: Double
    let negative: Double
}

struct Trend: Codable, Identifiable {
    var id: String { theme }
    let theme: String
    let direction: String
    let evidence: [String]
}

struct Outlier: Codable, Identifiable {
    var id: UUID = UUID()
    let participant: String
    let reason: String
    let evidence: String
}

// MARK: - Social ID Helper

let base62chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
let base62 = Array(base62chars)

func createSocialID(from uuid: String) -> String {
    let hash = SHA256.hash(data: Data(uuid.utf8))
    let first4 = hash.prefix(4)
    let value = first4.reduce(0) { ($0 << 8) | UInt64($1) }
    return encodeBase62(from: value)
}

func encodeBase62(from value: UInt64) -> String {
    var num = value
    var result = ""
    
    repeat {
        let index = Int(num % 62)
        result = String(base62[index]) + result
        num /= 62
    } while num > 0
    
    return result.padding(toLength: 6, withPad: "0", startingAt: 0)
}
