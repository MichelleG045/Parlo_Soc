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
                            Text("Tap to start recording")
                                .foregroundStyle(.gray)
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
                }
            }
            
          
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
    
    func startRecording() {
        guard permissionGranted else {
            print("Recording permission not granted")
            return
        }
        
        print("Starting recording...")

        responseTranscript = ""
        recordingDuration = 0
        audioFile = nil
  
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
        
        // Start audio manager for amplitude monitoring
        audioManager.start(transcribe: speechPermissionGranted, monitor: true)
        
        // Start file recording
        audioFile = audioManager.startRecordingToFile()
        
        recording = true
        UIApplication.shared.isIdleTimerDisabled = true
        
        print("Recording started - File: \(audioFile?.lastPathComponent ?? "none")")
    }
    
    func stopRecording() {
        print("Stopping recording...")
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        recording = false
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Stop audio manager and wait for file to be written
        audioManager.stop()
        
        // Longer delay to ensure file is completely written
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Now stop file recording
            let finalAudioFile = self.audioManager.stopRecordingToFile()
            
            if let finalFile = finalAudioFile {
                self.audioFile = finalFile
                print("Final audio file: \(finalFile.lastPathComponent)")
                
                // Additional verification
                if FileManager.default.fileExists(atPath: finalFile.path) {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: finalFile.path)
                        let fileSize = attributes[.size] as? Int64 ?? 0
                        print("Final file size: \(fileSize) bytes")
                        
                        if fileSize > 1000 { // Minimum reasonable file size
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
            
            // Get final transcript
            self.responseTranscript = self.audioManager.transcript
            
            // Update response data
            self.responseData.transcript = self.responseTranscript
            self.responseData.audioFile = self.audioFile
            
            print("Recording stopped:")
            print("  Duration: \(self.recordingDuration)s")
            print("  Transcript: '\(self.responseTranscript)'")
            print("  Audio file: \(self.audioFile?.lastPathComponent ?? "none")")

            // Move to next step after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.responseTranscript.isEmpty || self.audioFile != nil {
                    self.step = .config
                } else {
                    print("No content to proceed with - staying on recording screen")
                }
            }
        }
    }
}

struct ResponseData {
    var transcript: String = ""
    var audioFile: URL? = nil
}
