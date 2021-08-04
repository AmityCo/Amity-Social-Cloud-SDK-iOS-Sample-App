//
//  AmityCustomViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 10/18/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import SwiftUI

protocol AmityCustomViewControllerDelegate: AnyObject {
    func amityCustom(_ viewController: AmityCustomViewController, willSendCustomDataWithData data: [String: Any])
    func amityCustom(_ viewController: AmityCustomViewController, willUpdateCustomDataWithData data: [String: Any], onMessage message: AmityMessage?)
    func amityCustom(_ viewController: AmityCustomViewController, willSendVoiceMessageWithData audioFileURL: URL, fileName: String)
}

final class AmityCustomViewController: UIViewController {

    @IBOutlet private weak var keyField: UITextField!
    @IBOutlet private weak var valueField: UITextField!
    
    @IBOutlet weak var voiceMessageLabel: UILabel!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playRecordButton: UIButton!
    @IBOutlet weak var sendRecordButton: UIButton!
    
    weak var delegate: AmityCustomViewControllerDelegate?
    
    private var message: AmityMessage?
    
    let audioHandler = AudioMessageHandler()
    
    var isRecordingAudio = false
    var isPlayingAudio = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        voiceMessageLabel.text = "-"
        recordButton.addTarget(self, action: #selector(onRecordAudioButtonTap), for: .touchUpInside)
        playRecordButton.addTarget(self, action: #selector(onPlayAudioButtonTap), for: .touchUpInside)
        sendRecordButton.addTarget(self, action: #selector(onSendAudioMessageButtonTap), for: .touchUpInside)
        
        if let message = message, let data = message.data?["data"] as? [String: Any] {
            keyField.text = data["key"] as? String
            valueField.text = data["value"] as? String
        }
        
        audioHandler.initializePermissionForRecording()
        audioHandler.didUpdateTime = { [weak self] time in
            self?.voiceMessageLabel.text = time
        }
    }
    
    @objc func onRecordAudioButtonTap() {
        guard audioHandler.canRecordAudio else { return }
        
        if isRecordingAudio {
            audioHandler.stopRecording()
            recordButton.setTitle("Start Recording", for: .normal)
            
            isRecordingAudio = false
        } else {
            audioHandler.prepareForRecording()
            audioHandler.startRecording()
            recordButton.setTitle("Stop Recording", for: .normal)
            
            isRecordingAudio = true
        }
    }
    
    @objc func onPlayAudioButtonTap() {
        if isPlayingAudio {
            audioHandler.stopPlayingAudioRecording()
            playRecordButton.setTitle("Start Playing", for: .normal)
            
            isPlayingAudio = false
        } else {
            audioHandler.prepareAudioPlayer(url: audioHandler.recordingURL)
            audioHandler.playAudioRecording()
            playRecordButton.setTitle("Stop Playing", for: .normal)
            
            isPlayingAudio = true
        }
    }
    
    @objc func onSendAudioMessageButtonTap() {
        guard audioHandler.isRecordingAvailable,
            let audioURL = audioHandler.recordingURL,
            let audioData = try? Data(contentsOf: audioURL) else { return }
        
        let fileName = audioURL.lastPathComponent
        delegate?.amityCustom(self, willSendVoiceMessageWithData: audioURL, fileName: fileName)
    }
    
    func setMessage(message: AmityMessage) {
        self.message = message
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        
        let controller = UIHostingController(rootView: CustomMessageView(sendButtonAction: { [weak self] input in
            guard !input.isEmpty else { return }
            
            guard let strongSelf = self else { return }
            
            if let parentMessage = strongSelf.message {
                strongSelf.delegate?.amityCustom(strongSelf, willUpdateCustomDataWithData: input, onMessage: parentMessage)
                strongSelf.dismiss(animated: true, completion: nil)
            } else {
                strongSelf.delegate?.amityCustom(strongSelf, willSendCustomDataWithData: input)
                strongSelf.dismiss(animated: true, completion: nil)
            }
        }))
        
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    static func makeViewController() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "AmityCustomViewController")
        return vc
    }
    
}
