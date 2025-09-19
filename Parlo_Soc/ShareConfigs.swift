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
                // submit - NOW WITH WORKING LOGIC
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
        print("Creating post...")
        
        // Get transcript from recording
        let transcript = AppDataHolder.shared.lastTranscript
        print("Transcript: '\(transcript)'")
        
        // Build media array starting with text
        var media: [SocialResponse] = []
        
        if !transcript.isEmpty {
            let textResponse = SocialResponse(kind: .text, text: transcript, url: nil)
            media.append(textResponse)
            print("Added text media")
        }
        
        // Add audio if user chose to include it
        if includeAudio, let audioURL = AppDataHolder.shared.lastAudioFile {
            let audioResponse = SocialResponse(kind: .audio, text: nil, url: audioURL)
            media.append(audioResponse)
            print("Added audio media: \(audioURL.lastPathComponent)")
        } else {
            print("Audio not included")
        }
        
        // Create author
        let author = SocialResponseAuthor(
            name: appData.name.isEmpty ? "You" : appData.name,
            uid: appData.userID.isEmpty ? "current-user" : appData.userID,
            socialID: appData.socialID.isEmpty ? "@you" : appData.socialID
        )
        
        print("Author: \(author.name) (\(author.socialID))")
        
        // Create the post
        Task {
            do {
                guard let repo = appData.repo else {
                    print("Repository not found")
                    return
                }
                
                try await repo.createResponse(
                    promptId: "today-prompt",
                    promptText: "what are you happy about",
                    media: media,
                    author: author,
                    visibility: makePublic ? .everyone : .friends
                )
                
                print("Post created successfully!")
                
                // Mark prompt as completed (for unlock mechanism)
                DispatchQueue.main.async {
                    if !appData.completedPrompts.contains("today-prompt") {
                        appData.completedPrompts.append("today-prompt")
                        print("Prompt marked as completed")
                    }
                    
                    // Close the sheet
                    dismiss()
                }
                
            } catch {
                print("Error creating post: \(error)")
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
