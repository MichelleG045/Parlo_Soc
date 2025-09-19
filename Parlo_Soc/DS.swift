//
//  DS.swift
//  echo
//
//  Created by Max Eisenberg on 5/6/25.
//

import Foundation
import SwiftUI

class AppData: ObservableObject {
    
    

    @Published var signedIn = false
    @Published var userID = "current-user"
    @Published var viewingAsUser = "current-user"
    @Published var name: String = "You"
    @Published var phone: String = ""
    @Published var pfp: UIImage? = nil
    
    @Published var selectedTab = 0
    @Published var firstEntryRecorded = false
    @Published var hasSeenOnboarding = false
    @Published var subscribed = false
    @Published var recording = false
    @Published var startRecording = false
    
    @Published var onboardingStartTime: Date?
    
    @Published var dynamicPrompt = false
    
    @Published var lastUpdatedCompanionInsight: Date? = nil
    
    
    @Published var weeklyGoal = 3
    @Published var monthlyGoal = 20
    
    
    @Published var spotifyConnected = false
    @Published var listeningContext: String? = nil
    @Published var weeklyPlaylist: [SongInfo] = []
    @Published var weeklyPlaylistID: String?
    @Published var lastPlaylistRefresh: Date?
    @Published var playlistRefreshInProgress: Bool = false

    @Published var journalEntries: [Date: [JournalEntry]] = [:]
    @Published var wordDict: [String : Int] = [:]
    @Published var journalingPrompts: [String] = []
        
    @Published var useReason: Int = 0
    @Published var selectedLanguage: String = Locale.current.identifier
    
    @Published var notifPrompted: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var notificationTask: [String: Any] = [:]
    @Published var notifyTime: String? = nil
    
    @Published var weeklyInsights: WeekInsight? = nil
    @Published var monthlyInsights: MonthInsight? = nil
    
    @Published var availableBadges: [Badge] = []
    @Published var userBadges: [String] = []
    
    
    @Published var completedPrompts: [String] = []
    @Published var cachedPFP: [String: UIImage] = [:]
    @Published var socialRepo: SocialRepository?
    @Published var socialID: String = "@you"
    @Published var friends: [NetworkFriend] = []
    @Published var cachedFriendPFP: [String : UIImage] = [:]
    @Published var cachedNetworkInsights: [String : Date] = [:]
    
    @Published var defaultAudience = "friends"
    
    @Published var repo: MainSocialFeedRepository?
    
    @Published var savedResponses: [String: [FeedItem]] = [:]


    let availableUsers = [
        ("current-user", "You"),
        ("user-sarah", "Sarah Chen"),
        ("user-alex", "Alex Rivera"),
        ("user-jordan", "Jordan Kim")
    ]
    
}


struct JournalEntry: Identifiable, Codable {
    
    let id: String
    let date: String
    var transcript: String
    
    let summary: Summary
    let mood: Mood
    let analysis: Analysis
    let themes: [String]
    let selfInsightScore: Double
    
    var hr: Int?
    var sleep: Int?
    
    let songList: [[String: String]]?
    var songInfo: [SongInfo]?
    
    struct Summary: Codable {
        let transcriptSummary: String
        let notablePhrases: [String]
    }
    
    struct Mood: Codable {
        let primaryTone: String
        let moodScore: Double
        let emotionalArc: String
        let toneColor: String
    }
    
    struct Analysis: Codable {
        let question: String
        let inspiredBy: [String]
    }

    var photos: [JournalPhoto]? = nil
    struct JournalPhoto: Codable, Identifiable {
        let id: String
        let url: String
    }
}

struct SongInfo: Codable, Hashable {
    let title: String
    let artist: String
    let cover: String
    let spotifyUrl: String
}


extension JournalEntry {
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: date)
    }
}


struct JournalComment: Identifiable, Codable, Hashable {
    let id: String
    let comment: String
    let author: String
    let timestamp: Date
}



let HardcodedPrompts: [String] = [
    "What's on your mind?",
    "How was today?",
    "Anything special happen?",
    "Are you frustrated?",
    "One good thing today?",
    "Let's hear it!",
    "What stood out today?",
    "What are you feeling?",
    "What's been bothering you?",
    "What made you smile?",
    "Anything you'd change today?",
    "What's your energy like?",
    "What's taking space mentally?",
    "Any surprises today?",
    "What's next for you?",
    "Want to vent something?",
    "Did you feel seen?",
    "What's weighing on you?",
    "What felt meaningful today?",
    "Say whatever you want",
    "What's lingering today?",
    "Name a small win",
    "What's been repeating lately?",
    "Any moments of calm?",
    "What drained your energy?",
    "Something you're avoiding?",
    "Where's your focus today?",
    "Who crossed your mind?",
    "Something you're proud of?",
    "Any weird dreams?",
    "What made you pause?",
    "Anything feel unresolved?",
    "What are you learning?",
    "What made you laugh?",
    "Describe your mood shift",
    "Something that felt real?",
    "What's the background noise?",
    "A thought you noticed?",
    "How did you connect?",
    "What's been helping lately?"
]
