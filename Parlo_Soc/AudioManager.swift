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

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var enableTranscription = false
    private var isStopped = false
    
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var amplitudeTimer: Timer?

    func start(transcribe: Bool = true, monitor: Bool = true) {
        stop()
        enableTranscription = transcribe
        transcript = ""
        isStopped = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("Audio session configured for recording")
        } catch {
            print("Audio session error:", error)
            return
        }

        if transcribe && recognizer?.isAvailable == true {
            setupSpeechRecognition()
        }
        
        if monitor {
            setupAudioEngine()
        }
    }
    
    private func setupSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        guard let recognizer = recognizer else {
            print("Speech recognizer not available")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self, !self.isStopped else {
                print("Ignoring speech recognition update - already stopped")
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    if !self.isStopped {
                        self.transcript = result.bestTranscription.formattedString
                        print("Live transcript update: '\(result.bestTranscription.formattedString)'")
                    }
                }
            }
            if let error = error {
                print("Speech recognition error:", error.localizedDescription)
            }
        }
        print("Speech recognition setup complete")
    }
    
    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            if self.enableTranscription && !self.isStopped {
                self.recognitionRequest?.append(buffer)
            }

            if true {
                self.processAmplitude(from: buffer)
            }
        }

        do {
            try audioEngine.start()
            print("Audio engine started")
        } catch {
            print("Audio engine error:", error)
        }
    }
    
    private func processAmplitude(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        let rms = sqrt((0..<frameLength).reduce(0) { $0 + pow(channelData[$1], 2) } / Float(frameLength))
        let normalized = CGFloat(min(max(rms * 100, 0.1), 1.0))
        
        DispatchQueue.main.async {
            if self.amplitudes.count >= 30 {
                self.amplitudes.removeFirst()
            }
            self.amplitudes.append(normalized)
        }
    }

    func stop() {
    
        isStopped = true
        
        let finalTranscript = transcript
        print("Capturing transcript before stop: '\(finalTranscript)'")
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
            print("Recorder stopped in stop() method")
        }
        transcript = finalTranscript
        print("Preserved transcript after stop: '\(transcript)'")

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            print("Audio session switched to playback mode")
        } catch {
            print("Error changing audio session category:", error)
        }
        
        print("Audio manager stopped with final transcript: '\(transcript)'")
    }

    func startRecordingToFile() -> URL? {
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording-\(Date().timeIntervalSince1970).m4a"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.prepareToRecord()
            
            let success = recorder?.record() ?? false
            
            if success {
                recordingURL = fileURL
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
    
    func stopRecordingToFile() -> URL? {
        guard let recorder = recorder else {
            print("No recorder found")
            return recordingURL
        }
        
        if recorder.isRecording {
            recorder.stop()
            print("Recording stopped, file saved to: \(recorder.url.lastPathComponent)")
        }
        
        let url = recorder.url
        

        Thread.sleep(forTimeInterval: 0.3)

        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("Recording file size: \(fileSize) bytes")
                
                if fileSize > 0 {
                    print("File recording completed successfully")
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
}
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
