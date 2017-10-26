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

import PlaygroundSupport
import AVFoundation
import SpeechToTextV1
import ConversationV1
import TextToSpeechV1

// Configure playground environment
PlaygroundPage.current.needsIndefiniteExecution = true
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

// Instantiate services
let speechToText = SpeechToText(
    username: Credentials.SpeechToTextUsername,
    password: Credentials.SpeechToTextPassword
)
let conversation = Conversation(
    username: Credentials.ConversationUsername,
    password: Credentials.ConversationPassword,
    version: "2017-05-26"
)
let textToSpeech = TextToSpeech(
    username: Credentials.TextToSpeechUsername,
    password: Credentials.TextToSpeechPassword
)

// Instantiate audio player
var audioPlayer: AVAudioPlayer?

// Set conversation workspace
let workspace = Credentials.ConversationWorkspace

// Load audio recording
let recordingPath = Bundle.main.path(forResource: "TurnRadioOn", ofType: "wav")!
let recording = URL(fileURLWithPath: recordingPath)

// Transcribe audio recording
let settings = RecognitionSettings(contentType: .wav)
speechToText.recognize(audio: recording, settings: settings) { text in
    print("Transcription: \(text.bestTranscript)")
    
    // Send transcription as conversation request
    conversation.message(workspaceID: workspace) { response in
        let input = InputData(text: text.bestTranscript)
        let request = MessageRequest(input: input, context: response.context)
        conversation.message(workspaceID: workspace, request: request) { response in
            let reply = response.output.text.joined()
            print("Reply: \(reply)")
            
            // Synthesize response to spoken word
            textToSpeech.synthesize(reply) { audio in
                audioPlayer = try! AVAudioPlayer(data: audio)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            }
        }
    }
}
