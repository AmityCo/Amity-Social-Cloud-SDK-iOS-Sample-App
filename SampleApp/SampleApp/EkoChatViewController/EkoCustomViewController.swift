//
//  EkoCustomViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 10/18/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

protocol EkoCustomViewControllerDelegate: AnyObject {
    func ekoCustom(_ viewController: EkoCustomViewController, willSendCustomDataWithData data: [String: Any])
    func ekoCustom(_ viewController: EkoCustomViewController, willUpdateCustomDataWithData data: [String: Any], onMessage message: EkoMessage?)
    
    func ekoCustom(_ viewController: EkoCustomViewController, willSendVoiceMessageWithData data: Data, fileName: String)
}

final class EkoCustomViewController: UIViewController {

    @IBOutlet private weak var keyField: UITextField!
    @IBOutlet private weak var valueField: UITextField!
    
    @IBOutlet weak var voiceMessageLabel: UILabel!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playRecordButton: UIButton!
    @IBOutlet weak var sendRecordButton: UIButton!
    
    weak var delegate: EkoCustomViewControllerDelegate?
    
    private var message: EkoMessage?
    
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
        delegate?.ekoCustom(self, willSendVoiceMessageWithData: audioData, fileName: fileName)
    }
    
    func setMessage(message: EkoMessage) {
        self.message = message
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        guard let key = keyField.text, let value = valueField.text,
            !key.isEmpty, !value.isEmpty else { return }
        
        let map: [String: Any] = [
            "key": key,
            "value": value
        ]
        
        if let message = message {
            delegate?.ekoCustom(self, willUpdateCustomDataWithData: map, onMessage: message)
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            delegate?.ekoCustom(self, willSendCustomDataWithData: map)
            navigationController?.popViewController(animated: true)
        }
    }
    
    static func makeViewController() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "EkoCustomViewController")
        return vc
    }
    
}
