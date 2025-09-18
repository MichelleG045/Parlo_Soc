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
    @State private var allowComments: Bool = true
    @State private var allowReactions: Bool = true
    @State private var allowBookmark: Bool = true
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Choose how your response is shared and viewed. You can change these defaults in settings.")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.gray)
            
            VStack(spacing: 12) {
                row("person.2.fill", "Only your friends", $shareWithFriends)
                row("globe.americas.fill", "Everyone on Parlo", $makePublic)
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
                // submit
                Button {
                    let transcript = AppDataHolder.shared.lastTranscript
                    let transcriptResp = SocialResponse(kind: .text, text: transcript, url: nil)
                    
                    var media = [transcriptResp]
                    if let url = AppDataHolder.shared.lastAudioFile {
                        let audioResp = SocialResponse(kind: .audio, text: nil, url: url)
                        media.append(audioResp)
                    }
                    
                    let author = SocialResponseAuthor(
                        name: appData.name,
                        uid: appData.userID,
                        socialID: appData.socialID
                    )
                    
                    Task {
                        if let repo = appData.repo {
                            try? await repo.createResponse(
                                promptId: UUID().uuidString,
                                promptText: "Today's Prompt",
                                media: media,
                                author: author,
                                visibility: shareWithFriends ? .friends : .everyone
                            )
                        }
                    }
                    
                    step = .record
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
