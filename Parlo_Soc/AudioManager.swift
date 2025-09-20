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

class AudioManager: NSObject, ObservableObject {
    
    @Published var amplitudes: [CGFloat] = Array(repeating: 0.1, count: 30)
    @Published var transcript = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var enableTranscription = false
    
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var amplitudeTimer: Timer?

    func start(transcribe: Bool = true, monitor: Bool = true) {
        stop()
        enableTranscription = transcribe

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
            print("Audio session configured for recording")
        } catch {
            print("Audio session error:", error)
            return
        }
    }

    func stop() {
        // Stop amplitude monitoring
        amplitudeTimer?.invalidate()
        amplitudeTimer = nil
        
        // Stop recorder if running
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
            print("Recorder stopped in stop() method")
        }

        // Configure session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            print("Audio session switched to playback mode")
        } catch {
            print("Error changing audio session category:", error)
        }
        
        print("Audio manager stopped")
    }

    func startRecordingToFile() -> URL? {
        // Stop any existing recording first
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording-\(Date().timeIntervalSince1970).m4a"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // Use simpler, more reliable settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
            
            let success = recorder?.record() ?? false
            
            if success {
                recordingURL = fileURL
                startAmplitudeMonitoring()
                print("File recording started successfully: \(filename)")
                return fileURL
            } else {
                print("Failed to start recording")
                return nil
            }
        } catch {
            print("File recording error: \(error)")
            return nil
        }
    }
    
    private func startAmplitudeMonitoring() {
        amplitudeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.recorder, recorder.isRecording else { return }
            
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            
            // Convert dB to linear scale (0-1)
            let normalizedValue = pow(10, averagePower / 20)
            let amplitude = CGFloat(max(0.1, min(1.0, normalizedValue * 5)))
            
            DispatchQueue.main.async {
                if self.amplitudes.count >= 30 {
                    self.amplitudes.removeFirst()
                }
                self.amplitudes.append(amplitude)
            }
        }
    }
    
    func stopRecordingToFile() -> URL? {
        amplitudeTimer?.invalidate()
        amplitudeTimer = nil
        
        guard let recorder = recorder else {
            print("No recorder found")
            return recordingURL
        }
        
        if recorder.isRecording {
            recorder.stop()
            print("Recording stopped, file saved to: \(recorder.url.lastPathComponent)")
        }
        
        let url = recorder.url
        
        // Wait a moment for the file to be fully written
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify the file was created and has content
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("Recording file size: \(fileSize) bytes")
                
                if fileSize > 0 {
                    print("File recording completed successfully")
                    
                    // Process speech recognition on the completed file
                    if enableTranscription {
                        processRecordedFileForSpeech(url: url)
                    }
                    
                    self.recorder = nil
                    return url
                } else {
                    print("Warning: Recording file is empty")
                    self.recorder = nil
                    return nil
                }
            } catch {
                print("Error checking file attributes: \(error)")
                self.recorder = nil
                return nil
            }
        } else {
            print("Warning: Recording file does not exist")
            self.recorder = nil
            return nil
        }
    }
    
    private func processRecordedFileForSpeech(url: URL) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognizer not available for file processing")
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result, result.isFinal {
                DispatchQueue.main.async {
                    self?.transcript = result.bestTranscription.formattedString
                    print("Speech recognition completed: \(result.bestTranscription.formattedString)")
                }
            }
            
            if let error = error {
                print("Speech recognition error for file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Audio recording finished successfully: \(flag)")
        if !flag {
            print("Recording failed - this may cause playback issues")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recording encode error: \(error)")
        }
    }
}
