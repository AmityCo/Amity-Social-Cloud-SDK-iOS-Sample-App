//
//  AudioMessageHandler.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/20/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AVFoundation

/*
 This is just a SAMPLE CODE for recording messages. This is NOT a PRODUCTION ready code.
 Please refrain yourself from copying the exact code for your usage.
 */

class AudioMessageHandler: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var canRecordAudio: Bool = false
    var isRecordingAvailable = false
    var recordTimer: Timer?
    var timeStr = "00:00:00"
    var isRecording: Bool = true
    var recordingURL: URL?
    
    var didUpdateTime: ((String) -> Void)?
    
    func initializePermissionForRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            canRecordAudio = true
        case AVAudioSessionRecordPermission.denied:
            canRecordAudio = false
        case AVAudioSessionRecordPermission.undetermined:
            // Request permission to record audio here
            AVAudioSession.sharedInstance().requestRecordPermission({ (isAllowed) in
                self.canRecordAudio = isAllowed
            })
        default:
            break
        }
    }
    
    func generateAudioFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "abcd" + "_audio_ios.m4a"
        
        let filePath = documentDirectory.appendingPathComponent(fileName)
        return filePath
    }
    
    func prepareForRecording() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
            ]
            recordingURL = generateAudioFileURL()
            audioRecorder = try? AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            Log.add(info: "Audio recording not available")
        }
    }
    
    func startRecording() {
        audioRecorder?.record()
        recordTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(updateAudioMeter(timer:)), userInfo:nil, repeats:true)
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        recordTimer?.invalidate()
        recordTimer = nil
    }

    @objc func updateAudioMeter(timer: Timer) {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        let hr = Int((recorder.currentTime / 60) / 60)
        let min = Int(recorder.currentTime / 60)
        let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
        timeStr = String(format: "%02d:%02d:%02d", hr, min, sec)
        
        didUpdateTime?(timeStr)
        
        recorder.updateMeters()
    }
    
    func prepareAudioPlayer(url: URL?) {
        guard let audioURL = url else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch{
            Log.add(info: "Audio player error")
        }
    }
    
    func playAudioRecording() {
        audioPlayer?.play()
    }
    
    func stopPlayingAudioRecording() {
        audioPlayer?.stop()
    }
    
    // Delegates
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecordingAvailable = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
    }
}

class ImageMessageHandler {
    
    public static let shared = ImageMessageHandler()
    
    let fileRepo = AmityFileRepository(client: AmityManager.shared.client!)
    let imageCache = NSCache<NSString, UIImage>()

    private init() {
        // Prevent initialization
    }
    
    func fetchImage(fileURL: String, completion: @escaping (UIImage?) -> Void) {
        
        if let image = imageCache.object(forKey: fileURL as NSString) {
            // Image is already in the cached, just grab and show it.
            completion(image)
            return
        }
        
        fileRepo.downloadImageAsData(fromURL: fileURL, size: .full) { [weak self] (image, size, error) in
            
            guard let image = image else {
                completion(nil)
                return
            }
            
            self?.imageCache.setObject(image, forKey: fileURL as NSString)
            
            completion(image)
        }
    }
    
}
