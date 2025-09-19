//
//  SavedResponsesSheet.swift
//  Parlo_Soc
//
//  Created by Michelle Gurovith on 9/19/25.
//

import SwiftUI

struct SavedResponsesSheet: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if let responses = appData.savedResponses[appData.viewingAsUser],
                   !responses.isEmpty {
                    ForEach(responses, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.promptText)
                                .font(.headline)
                                .foregroundStyle(.txt)

                            ForEach(item.media, id: \.id) { media in
                                if let text = media.text {
                                    Text(text)
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                } else if let url = media.url {
                                    Text("Media: \(url.lastPathComponent)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("No responses saved yet for this user.")
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Saved Responses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

