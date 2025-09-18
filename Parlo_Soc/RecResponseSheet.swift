//
//  RecResponseSheet.swift
//  echo
//
//  Created by Max Eisenberg on 9/6/25.
//

import SwiftUI
import AVFoundation
import Speech

// 🔹 Temporary holder to pass data between steps
class AppDataHolder {
    static let shared = AppDataHolder()
    var lastTranscript: String = ""
    var lastAudioFile: URL? = nil
}

struct RecResponseSheet: View {
    
    @StateObject private var audioManager = AudioManager()
    @Binding var step: ResponseFlowStep
    
    let promptTitle: String
    
    @State var recording = false
    @State var responseTranscript = ""
    @State var audioFile: URL?
    @State private var permissionGranted = false
    @State private var speechPermissionGranted = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration = 0
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
        
            Text(promptTitle)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.txt)
            
            // waveform
            RoundedRectangle(cornerRadius: 15)
                .fill(.bgLight.opacity(0.6))
                .frame(height: 110)
                .overlay(
                    Group {
                        if recording {
                            HStack {
                                ForEach(0..<audioManager.amplitudes.count, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .frame(width: 3, height: max(3.5, audioManager.amplitudes[i] * 60))
                                        .foregroundStyle(.txt.opacity(0.75))
                                        .animation(.easeInOut(duration: 0.1), value: audioManager.amplitudes[i])
                                }
                            }
                        } else {
                            Text("Tap to start recording")
                                .foregroundStyle(.gray)
                        }
                    }
                )
            
            // Recording status
            if recording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(recording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: recording)
                    
                    Text("Recording... \(formatDuration(recordingDuration))")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.red)
                }
            }
            
            // Show transcript if available
            if !responseTranscript.isEmpty {
                ScrollView {
                    Text(responseTranscript)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(.txt)
                        .padding()
                        .background(.bgLight.opacity(0.3))
                        .cornerRadius(12)
                }
                .frame(maxHeight: 100)
            }
            
            Spacer()
            
            // Permission status
            if !permissionGranted {
                VStack(spacing: 8) {
                    Text("Microphone permission required")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Button("Grant Permission") {
                        requestMicrophonePermission()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // CTA button
            Button {
                if !recording {
                    startRecording()
                } else {
                    stopRecording()
                }
            } label: {
                HStack {
                    Image(systemName: recording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundStyle(recording ? .white : .txt)
                    Text(recording ? "Stop Recording" : "Start Recording")
                        .foregroundStyle(recording ? .white : .txt)
                }
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding()
                .background(recording ? Color.red : .bgLight)
                .cornerRadius(16)
            }
            .disabled(!permissionGranted)
            .buttonStyle(.plain)
            
        }
        .background(Color(.bgDark).ignoresSafeArea(.all))
        .padding()
        .onAppear {
            requestMicrophonePermission()
            requestSpeechPermission()
        }
        .onChange(of: audioManager.transcript) { _, newValue in
            responseTranscript = newValue
        }
        .onDisappear {
            if recording {
                stopRecording()
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Permissions
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                print("Microphone permission: \(granted)")
            }
        }
    }
    
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechPermissionGranted = (status == .authorized)
                print("Speech recognition permission: \(status)")
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard permissionGranted else {
            print("Recording permission not granted")
            return
        }
        
        print("Starting recording...")
        
        // Reset state
        responseTranscript = ""
        recordingDuration = 0
        
        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
        
        // Start audio recording
        audioFile = audioManager.startRecordingToFile()
        audioManager.start(transcribe: speechPermissionGranted, monitor: true)
        
        recording = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func stopRecording() {
        print("Stopping recording...")
        
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Stop audio
        audioManager.stop()
        audioFile = audioManager.stopRecordingToFile()
        
        recording = false
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Get final transcript
        responseTranscript = audioManager.transcript
        
        // Save data
        AppDataHolder.shared.lastTranscript = responseTranscript
        AppDataHolder.shared.lastAudioFile = audioFile
        
        print("Recording stopped. Duration: \(recordingDuration)s, Transcript: '\(responseTranscript)'")
        
        // Auto-advance if we have content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !responseTranscript.isEmpty || audioFile != nil {
                step = .config
            }
        }
    }
}
