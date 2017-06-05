/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import JSQMessagesViewController
import AVFoundation
import ConversationV1
import SpeechToTextV1
import TextToSpeechV1

class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    var conversation: Conversation!
    var speechToText: SpeechToText!
    var textToSpeech: TextToSpeech!
    
    var audioPlayer: AVAudioPlayer?
    var workspace = Credentials.ConversationWorkspace
    var context: Context?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        setupSender()
        setupWatsonServices()
        startConversation()
    }
}

// MARK: Watson Services
extension ViewController {
    
    /// Instantiate the Watson services
    func setupWatsonServices() {
        conversation = Conversation(
            username: Credentials.ConversationUsername,
            password: Credentials.ConversationPassword,
            version: "2017-05-26"
        )
        speechToText = SpeechToText(
            username: Credentials.SpeechToTextUsername,
            password: Credentials.SpeechToTextPassword
        )
        textToSpeech = TextToSpeech(
            username: Credentials.TextToSpeechUsername,
            password: Credentials.TextToSpeechPassword
        )
    }
    
    /// Present an error message
    func failure(error: Error) {
        let alert = UIAlertController(
            title: "Watson Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
    }
    
    /// Start a new conversation
    func startConversation() {
        conversation.message(
            withWorkspace: workspace,
            failure: failure,
            success: presentResponse
        )
    }
    
    /// Present a conversation reply and speak it to the user
    func presentResponse(_ response: MessageResponse) {
        guard let text = response.output.text.first else { return }
        context = response.context // save context to continue conversation
        
        // synthesize and speak the response
        textToSpeech.synthesize(text, failure: failure) { audio in
            self.audioPlayer = try! AVAudioPlayer(data: audio)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
        }
        
        // create message
        let message = JSQMessage(
            senderId: User.watson.rawValue,
            displayName: User.getName(User.watson),
            text: text
        )
        
        // add message to chat window
        if let message = message {
            self.messages.append(message)
            DispatchQueue.main.async { self.finishSendingMessage() }
        }
    }
    
    /// Start transcribing microphone audio
    func startTranscribing() {
        audioPlayer?.stop()
        var settings = RecognitionSettings(contentType: .opus)
        settings.continuous = true
        settings.interimResults = true
        speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
            self.inputToolbar.contentView.textView.text = results.bestTranscript
            self.inputToolbar.toggleSendButtonEnabled()
        }
    }
    
    /// Stop transcribing microphone audio
    func stopTranscribing() {
        speechToText.stopRecognizeMicrophone()
    }
}

// MARK: Configuration
extension ViewController {
    
    func setupInterface() {
        // bubbles
        let factory = JSQMessagesBubbleImageFactory()
        let incomingColor = UIColor.jsq_messageBubbleLightGray()
        let outgoingColor = UIColor.jsq_messageBubbleGreen()
        incomingBubble = factory!.incomingMessagesBubbleImage(with: incomingColor)
        outgoingBubble = factory!.outgoingMessagesBubbleImage(with: outgoingColor)
        
        // avatars
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // microphone button
        let microphoneButton = UIButton(type: .custom)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone-hollow"), for: .normal)
        microphoneButton.setImage(#imageLiteral(resourceName: "microphone"), for: .highlighted)
        microphoneButton.addTarget(self, action: #selector(startTranscribing), for: .touchDown)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpInside)
        microphoneButton.addTarget(self, action: #selector(stopTranscribing), for: .touchUpOutside)
        inputToolbar.contentView.leftBarButtonItem = microphoneButton
    }
    
    func setupSender() {
        senderId = User.me.rawValue
        senderDisplayName = User.getName(User.me)
    }
    
    override func didPressSend(
        _ button: UIButton!,
        withMessageText text: String!,
        senderId: String!,
        senderDisplayName: String!,
        date: Date!)
    {
        let message = JSQMessage(
            senderId: User.me.rawValue,
            senderDisplayName: User.getName(User.me),
            date: date,
            text: text
        )
        
        if let message = message {
            self.messages.append(message)
            self.finishSendingMessage(animated: true)
        }
        
        // send text to conversation service
        let request = MessageRequest(text: text, context: context)
        conversation.message(
            withWorkspace: workspace,
            request: request,
            failure: failure,
            success: presentResponse
        )
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // required by super class
    }
}

// MARK: Collection View Data Source
extension ViewController {
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int)
        -> Int
    {
        return messages.count
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageData!
    {
        return messages[indexPath.item]
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageBubbleImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageBubbleImageDataSource!
    {
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        let bubble = (isOutgoing) ? outgoingBubble : incomingBubble
        return bubble
    }
    
    override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        avatarImageDataForItemAt indexPath: IndexPath!)
        -> JSQMessageAvatarImageDataSource!
    {
        let message = messages[indexPath.item]
        return User.getAvatar(message.senderId)
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = super.collectionView(
            collectionView,
            cellForItemAt: indexPath
        )
        let jsqCell = cell as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        let isOutgoing = (message.senderId == senderId)
        jsqCell.textView.textColor = (isOutgoing) ? .white : .black
        return jsqCell
    }
}
