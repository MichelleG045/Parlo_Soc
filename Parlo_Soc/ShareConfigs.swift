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

    // NEW: Accept current filter and refresh callback
    let currentFilter: FeedFilter
    let onResponsePosted: () -> Void
    
    @State private var shareWithFriends: Bool = true
    @State private var makePublic: Bool = false
    @State private var includeAudio: Bool = true
    @State private var allowComments: Bool = true
    @State private var allowReactions: Bool = true
    @State private var allowBookmark: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Choose how your response is shared and viewed. You can change these defaults in settings.")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.gray)
            
            VStack(spacing: 12) {
                row("person.2.fill", "Only your friends", $shareWithFriends)
                row("globe.americas.fill", "Everyone on Parlo", $makePublic)
                row("mic.fill", "Include audio recording", $includeAudio)
            }
            .onChange(of: makePublic) { _, newValue in
                if newValue { shareWithFriends = true }
            }
            .onChange(of: shareWithFriends) { _, newValue in
                if !newValue && !makePublic { makePublic = true }
            }
            
            Spacer()
            
            // action buttons
            VStack(spacing: 20) {
                // submit - WITH PROPER FILTER HANDLING
                Button {
                    createPost()
                } label: {
                    HStack {
                        Text("Share Response")
                        Image(systemName: "paperplane.fill")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.bgDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.txt)
                    .cornerRadius(16)
                }
                
                // delete/back
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
            }
            
        }
        .padding()
        .background(.bgDark)
    }
    
    // MARK: - Create Post Function
    private func createPost() {
        print("📝 Creating post from \(currentFilter.title) tab...")
        
        // Get transcript from recording
        let transcript = AppDataHolder.shared.lastTranscript
        print("   Transcript: '\(transcript)'")
        
        // Build media array
        var media: [SocialResponse] = []
        
        if !transcript.isEmpty {
            media.append(SocialResponse(kind: .text, text: transcript, url: nil))
            print("   ✅ Added text media")
        }
        
        if includeAudio, let audioURL = AppDataHolder.shared.lastAudioFile {
            media.append(SocialResponse(kind: .audio, text: nil, url: audioURL))
            print("   ✅ Added audio media: \(audioURL.lastPathComponent)")
        } else {
            print("   ⏭️ Audio not included")
        }
        
        // Map viewingAsUser → display name & handle
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

        
        print("   👤 Author: \(author.name) (uid: '\(author.uid)')")
        print("   📍 Posting from: \(currentFilter.title) tab")
        
        Task {
            do {
                guard let repo = appData.repo else {
                    print("❌ Repository not found")
                    return
                }
                
                // Mark prompt as completed for this user
                let promptKey = "\(appData.viewingAsUser)_completed_today-prompt"
                UserDefaults.standard.set(true, forKey: promptKey)
                print("🔓 UNBLURRED: Prompt marked as completed for \(appData.viewingAsUser)")
                
                // Create the post
                try await repo.createResponse(
                    promptId: "today-prompt",
                    promptText: "what are you happy about",
                    media: media,
                    author: author,
                    visibility: makePublic ? .everyone : .friends
                )
                
                print("✅ Post created successfully!")
                
                DispatchQueue.main.async {
                    appData.objectWillChange.send()
                    self.onResponsePosted()
                    dismiss()
                }
                
            } catch {
                print("❌ Error creating post: \(error)")
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
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

