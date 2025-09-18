//
//  AmplitudeBar.swift
//  echo
//
//  Created by Max Eisenberg on 5/5/25.
//

import SwiftUI


struct WaveformView: View {
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            ForEach(audioManager.amplitudes.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 3, height: max(3.5, audioManager.amplitudes[i] * 60))
                    .foregroundStyle(.txt.opacity(0.75))
            }
        }
        .animation(.interpolatingSpring(duration: 0.10), value: audioManager.amplitudes)
    }
}
