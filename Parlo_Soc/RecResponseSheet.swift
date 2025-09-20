//
//  RecResponseSheet.swift
//  echo
//
//  Created by Max Eisenberg on 9/6/25.
//

import SwiftUI
import AVFoundation
import Speech

struct RecResponseSheet: View {
    
    @StateObject private var audioManager = AudioManager()
    @Binding var step: ResponseFlowStep
    
    let promptTitle: String
    
    @Binding var responseData: ResponseData
    
    @State var recording = false
    @State var responseTranscript = ""
    @State var audioFile: URL?
    @State private var permissionGranted = false
    @State private var speechPermissionGranted = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration = 0
    @State private var showPermissionAlert = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
        
            Text(promptTitle)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.txt)
            

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
                            VStack(spacing: 8) {
                                Text("Tap to start recording")
                                    .foregroundStyle(.gray)
                                
                                if !speechPermissionGranted {
                                    Text("Speech recognition disabled")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                )
            
      
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
                    
                    if speechPermissionGranted {
                        Text("• Live transcription")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.green)
                    }
                }
            }
            
          
            if !responseTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcript:")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.txt)
                        
                        if recording && speechPermissionGranted {
                            Text("(Live)")
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                    
                    ScrollView {
                        Text(responseTranscript)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(.txt)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.bgLight.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 120)
                }
            }
            
            Spacer()
            
   
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
            } else if !speechPermissionGranted {
                VStack(spacing: 8) {
                    Text("Speech recognition permission needed for transcription")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                    
                    Button("Enable Transcription") {
                        requestSpeechPermission()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            

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
            print("Transcript updated in UI: '\(newValue)'")
        }
        .onDisappear {
            if recording {
                stopRecording()
            }
        }
        .alert("Permissions Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone and speech recognition permissions in Settings to use this feature.")
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                print("Microphone permission: \(granted)")
                
                if !granted {
                    self.showPermissionAlert = true
                }
            }
        }
    }
    
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechPermissionGranted = (status == .authorized)
                print("Speech recognition permission: \(status)")
                
                if status == .denied || status == .restricted {
                    self.showPermissionAlert = true
                }
            }
        }
    }
    
    func startRecording() {
        guard permissionGranted else {
            print("Recording permission not granted")
            showPermissionAlert = true
            return
        }
        
        print("Starting recording...")
        print("Speech recognition available: \(speechPermissionGranted)")

        // Clear previous data
        responseTranscript = ""
        audioManager.transcript = ""
        recordingDuration = 0
        audioFile = nil

        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
        
        // Start audio manager with both transcription and monitoring
        audioManager.start(transcribe: speechPermissionGranted, monitor: true)
        
        // Start file recording
        audioFile = audioManager.startRecordingToFile()
        
        recording = true
        UIApplication.shared.isIdleTimerDisabled = true
        
        print("Recording started successfully")
        print("  - File: \(audioFile?.lastPathComponent ?? "none")")
        print("  - Live transcription: \(speechPermissionGranted ? "enabled" : "disabled")")
    }
    
    func stopRecording() {
        print("Stopping recording...")
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        recording = false
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Stop audio manager (this stops both transcription and amplitude monitoring)
        audioManager.stop()
        
        // Short delay for file completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Stop file recording
            let finalAudioFile = self.audioManager.stopRecordingToFile()
            
            if let finalFile = finalAudioFile {
                self.audioFile = finalFile
                print("Final audio file: \(finalFile.lastPathComponent)")
                
                // Validate file
                if FileManager.default.fileExists(atPath: finalFile.path) {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: finalFile.path)
                        let fileSize = attributes[.size] as? Int64 ?? 0
                        print("Final file size: \(fileSize) bytes")
                        
                        if fileSize > 1000 {
                            print("Audio file ready for playback")
                        } else {
                            print("Warning: Audio file seems too small")
                            self.audioFile = nil
                        }
                    } catch {
                        print("Error checking final file: \(error)")
                        self.audioFile = nil
                    }
                } else {
                    print("Warning: Final audio file does not exist")
                    self.audioFile = nil
                }
            } else {
                print("Warning: No audio file returned from stopRecording")
                self.audioFile = nil
            }
            
            // Get final transcript from audio manager
            let finalTranscript = self.audioManager.transcript
            if !finalTranscript.isEmpty {
                self.responseTranscript = finalTranscript
            }
            
            // Update response data
            self.responseData.transcript = self.responseTranscript
            self.responseData.audioFile = self.audioFile
            
            print("Recording session completed:")
            print("  Duration: \(self.recordingDuration)s")
            print("  Final transcript: '\(self.responseTranscript)'")
            print("  Audio file: \(self.audioFile?.lastPathComponent ?? "none")")
            print("  Has content: \(!self.responseTranscript.isEmpty || self.audioFile != nil)")

            // Move to next step if we have content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !self.responseTranscript.isEmpty || self.audioFile != nil {
                    print("Moving to config step")
                    self.step = .config
                } else {
                    print("No content captured - staying on recording screen")
                }
            }
        }
    }
}

struct ResponseData {
    var transcript: String = ""
    var audioFile: URL? = nil
}
