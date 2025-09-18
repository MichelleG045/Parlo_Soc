//
//  AudioManager.swift
//  echo
//
//  Created by Max Eisenberg on 6/10/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import SwiftUI

class AudioManager: ObservableObject {
    
    @Published var amplitudes: [CGFloat] = Array(repeating: 0.1, count: 30)
    @Published var transcript = ""

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var enableTranscription = false
    private var enableAmplitude = false
    
    // 🔹 Recorder for saving audio file
    private var recorder: AVAudioRecorder?

    func start(transcribe: Bool = true, monitor: Bool = true) {
        stop() // Ensure clean state
        
        enableTranscription = transcribe
        enableAmplitude = monitor

        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session error:", error)
            return
        }

        // Setup speech recognition if enabled
        if transcribe && recognizer?.isAvailable == true {
            setupSpeechRecognition()
        }
        
        // Setup audio engine
        setupAudioEngine()
    }
    
    private func setupSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        guard let recognizer = recognizer else {
            print("❌ Speech recognizer not available")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
            if let error = error {
                print("❌ Speech recognition error:", error.localizedDescription)
            }
        }
        print("✅ Speech recognition setup complete")
    }
    
    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Remove any existing tap
        inputNode.removeTap(onBus: 0)
        
        // Install new tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Send audio to speech recognition
            if self.enableTranscription {
                self.recognitionRequest?.append(buffer)
            }

            // Process amplitude for visualization
            if self.enableAmplitude {
                self.processAmplitude(from: buffer)
            }
        }

        // Start audio engine
        do {
            try audioEngine.start()
            print("✅ Audio engine started")
        } catch {
            print("❌ Audio engine error:", error)
        }
    }

    func stop() {
        // Stop speech recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ Error deactivating audio session:", error)
        }
        
        print("✅ Audio manager stopped")
    }

    private func processAmplitude(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS (Root Mean Square) for amplitude
        let rms = sqrt((0..<frameLength).reduce(0) { $0 + pow(channelData[$1], 2) } / Float(frameLength))
        let normalized = CGFloat(min(max(rms * 100, 0.1), 1.0)) // Increased sensitivity
        
        DispatchQueue.main.async {
            // Shift array and add new value
            if self.amplitudes.count >= 30 {
                self.amplitudes.removeFirst()
            }
            self.amplitudes.append(normalized)
        }
    }
    
    // MARK: - 🔹 Audio File Recording
    
    func startRecordingToFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording-\(Date().timeIntervalSince1970).m4a"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.record()
            print("✅ File recording started: \(filename)")
            return fileURL
        } catch {
            print("❌ File recording error:", error)
            return nil
        }
    }
    
    func stopRecordingToFile() -> URL? {
        guard let recorder = recorder else { return nil }
        
        recorder.stop()
        let url = recorder.url
        self.recorder = nil
        
        print("✅ File recording stopped")
        return url
    }
}
