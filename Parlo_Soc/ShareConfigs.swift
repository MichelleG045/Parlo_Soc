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
    
    // MARK: - Create Post Function with PROPER FILTER HANDLING
    private func createPost() {
        print("📝 Creating post from \(currentFilter.title) tab...")
        
        // Get transcript from recording
        let transcript = AppDataHolder.shared.lastTranscript
        print("   Transcript: '\(transcript)'")
        
        // Build media array starting with text
        var media: [SocialResponse] = []
        
        if !transcript.isEmpty {
            let textResponse = SocialResponse(kind: .text, text: transcript, url: nil)
            media.append(textResponse)
            print("   ✅ Added text media")
        }
        
        // Add audio if user chose to include it
        if includeAudio, let audioURL = AppDataHolder.shared.lastAudioFile {
            let audioResponse = SocialResponse(kind: .audio, text: nil, url: audioURL)
            media.append(audioResponse)
            print("   ✅ Added audio media: \(audioURL.lastPathComponent)")
        } else {
            print("   ⏭️ Audio not included")
        }
        
        // Create author with FORCED current-user ID for consistent filtering
        let author = SocialResponseAuthor(
            name: appData.name.isEmpty ? "You" : appData.name,
            uid: "current-user", // FORCE this to always be current-user
            socialID: appData.socialID.isEmpty ? "@you" : appData.socialID
        )
        
        print("   👤 Author: \(author.name) (uid: '\(author.uid)')")
        print("   📍 Posting from: \(currentFilter.title) tab")
        
        // Create the post with PROPER FILTER CONTEXT
        Task {
            do {
                guard let repo = appData.repo else {
                    print("❌ Repository not found")
                    return
                }
                
                // 🔑 STEP 1: MARK PROMPT AS COMPLETED FIRST (this unblurs everything)
                let promptKey = "current-user_completed_today-prompt"
                UserDefaults.standard.set(true, forKey: promptKey)
                print("🔓 UNBLURRED: Prompt marked as completed for current-user")
                
                // 🔑 STEP 2: CREATE THE POST
                try await repo.createResponse(
                    promptId: "today-prompt",
                    promptText: "what are you happy about",
                    media: media,
                    author: author,
                    visibility: makePublic ? .everyone : .friends
                )
                
                print("✅ Post created successfully!")
                
                DispatchQueue.main.async {
                    // 🔑 STEP 3: FORCE UI TO RE-RENDER (unblurs everything immediately)
                    appData.objectWillChange.send()
                    print("🔄 UI refreshed - everything should be unblurred now")
                    
                    // 🔑 STEP 4: CALL THE REFRESH CALLBACK (refreshes current tab properly)
                    self.onResponsePosted()
                    print("📱 Current tab (\(self.currentFilter.title)) will be refreshed with proper filtering")
                    
                    // Expected behavior after posting:
                    switch self.currentFilter {
                    case .friends:
                        print("   → Friends tab: Should show friends' posts only (YOUR post excluded)")
                    case .all:
                        print("   → All tab: Should show friends' posts only (YOUR post excluded)")
                    case .myEntries:
                        print("   → My Responses tab: Should show YOUR post only")
                    }
                    
                    // Close the sheet
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
