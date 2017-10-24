# Simple Chat

This tutorial teaches you how to build a cognitive app with [IBM Watson](https://www.ibm.com/watson/) and the [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk). It combines the [Speech to Text](https://www.ibm.com/watson/developercloud/speech-to-text.html), [Conversation](https://www.ibm.com/watson/developercloud/conversation.html), and [Text to Speech](https://www.ibm.com/watson/developercloud/text-to-speech.html) services to build a voice-to-voice chat app.

![The Simple Chat app in action](tutorial-images/simple-chat.gif)

## Contents

1. [Project Setup](#project-setup)
2. [Provision Services](#provision-services)
3. [Organize Credentials](#organize-credentials)
4. [Create Conversation Workspace](#create-conversation-workspace)
5. [Simple Chat Playground](#simple-chat-playground)
6. [Simple Chat App](#simple-chat-app)
7. [Resources](#resources)

## Project Setup

Before starting the tutorial, be sure to checkout the `tutorial` branch. We also need to download the Watson Swift SDK dependency for use in our code. (The dependency will be loaded twice, once as a Git submodule for use in an Xcode playground, and again with Carthage for use in an iOS app.)

```
$ git clone https://github.com/watson-developer-cloud/simple-chat-swift.git
$ cd simple-chat-swift/simple-chat
$ git checkout tutorial
$ git submodule init
$ git submodule update
$ carthage update --platform iOS
```

## Provision Services

Our chat app will use the Speech to Text, Conversation, and Text to Speech services. We need to provision each service before using it in our app.

You will need to [sign up for a Bluemix account](https://console.ng.bluemix.net/registration/) if you do not already have one.

To provision each service:

1. Open the [Bluemix services dashboard](https://console.ng.bluemix.net/dashboard/services).
2. Select the "Create Service" button.
3. Select the "Watson" category from the left-hand menu.
4. Select the service to provision.
5. Select "Create" to continue. (The default configuration options are fine for this tutorial.)

Repeat these steps to provision instances of the Speech to Text, Conversation, and Text to Speech services.

## Organize Credentials

Each of the services you provisioned has its own username and password credentials. Let's collect them in a `Credentials.swift` file for our application to reference.

Start by renaming the `Credentials.swift.example` file in your project directory to `Credentials.swift`. Then open `Credentials.swift` in Xcode. This file will record our service credentials.

1. Open the [Bluemix services dashboard](https://console.ng.bluemix.net/dashboard/services).
2. Select the service whose credentials you would like to record.
3. Select "Service credentials" from the left-hand navigation menu.
4. Select "View credentials".
5. Copy the username and password into `Credentials.swift`.

Repeat these steps to copy the username and password credentials for the Speech to Text, Conversation, and Text to Speech services.

## Create Conversation Workspace

The Conversation service uses workspaces to maintain separate dialog flows and training data. We will use a sample workspace for our app.

1. Select your Conversation instance from the [Bluemix services dashboard](https://console.ng.bluemix.net/dashboard/services).
2. Click the "Launch tool" button.
3. Select the "Car Dashboard - Sample" to create a new workspace.
4. Select the bottom icon of the left-hand navigation menu to return to the list of workspaces.
5. Select the ellipsis on the top-right corner of the "Car Dashboard - Sample" workspace.
6. Select "View Details" then copy the "Workspace ID".
7. Paste the workspace id into your `Credentials.swift` file.

## Simple Chat Playground

Before building our app, let's experiment with the Watson Swift SDK in an Xcode playground. The playground environment will allow us to quickly get up-and-running and immediately see the effects of our code.

We will explore each component of our voice-to-voice chat app independently before combining them:

1. Transcribe audio to text using Speech to Text.
2. Send the text to Conversation and receive a text reply.
3. Synthesize the text reply to spoken word using Text to Speech.

To get started, open `Playground.xcworkspace`. This workspace already includes the playground and Watson Swift SDK, but we need to add credentials. Include your `Credentials.swift` file by dragging-and-dropping it onto the playground's `Sources` directory.

The Watson frameworks must be built before they can be used. Select the `SpeechToTextV1` scheme from the dropdown on the Xcode toolbar, then press the play button to build it. Do the same for the `ConversationV1` and `TextToSpeechV1` schemes.

Now that your playground environment is configured, we are ready to write some code!

### Speech to Text

Let's start by using the Speech to Text service to transcribe an audio recording. We will transcribe the `TurnRadioOn.wav` recording located in the `Resources` directory.

Open the `Speech to Text` playground page. This playground page already contains code to configure the playground environment, instantiate the `SpeechToText` class, and load the audio recording.

Add the following code to transcribe the recording to text:

```swift
// Transcribe audio recording
let settings = RecognitionSettings(contentType: .wav)
speechToText.recognize(audio: recording, settings: settings) { text in
    print(text.bestTranscript)
}
```

The `speechToText.recognize` function sends the recording to the service. We use the `settings` object to specify the WAV format of our audio recording. The completion handler assigns the service's recognition results to `text` then prints the `bestTranscript` to the console.

You should see the following transcription in the debug console: " turn the radio on ".

### Conversation

Now that we have transcribed the recording to text, we can send the transcription to the Conversation service. 

Open the `Conversation` playground page. This playground page already contains code to configure the playground environment, instantiate the `Conversation` class, and set the workspace.

To start a new conversation with the service, we need to send an empty message. The service will respond with a greeting, along with a `context` object that captures the conversation's state. Subsequent messages must include the `context` object to continue the conversation.

Add the following code to start a new conversation:

```swift
// Start conversation
conversation.message(workspaceID: workspace) { response in
    print(response.context.conversationID)
    print(response.output.text.joined())
}
```

A unique `conversationID` should be printed to the console, along with the following greeting: "Hi. It looks like a nice drive today. What would you like me to do?"

After starting a new conversation, we can send the transcription. Remember that we must include the `context` object to continue the same conversation.

Add the code below to continue the conversation and send the transcription:

```swift
// Start conversation
conversation.message(workspaceID: workspace) { response in
    print(response.context.conversationID)
    print(response.output.text.joined())
    
    // Continue conversation
    let input = InputData(text: " turn the radio on ")
    let request = MessageRequest(input: input, context: response.context)
    conversation.message(workspaceID: workspace, request: request) { response in
        print(response.output.text.joined())
    }
}
```

The service's reply should be printed to the console: "Sure thing! Which genre would you prefer? Jazz is my personal favorite."

### Text to Speech

Let's synthesize the text reply to spoken word using the Text to Speech service.

Open the `Text to Speech` playground page. This playground page already contains code to configure the playground environment, instantiate the `TextToSpeech` class, and declare an `AVAudioPlayer` object.

Add the following code to synthesize the text reply to spoken word:

```swift
// Synthesize text to spoken word
let text = "Sure thing! Which genre would you prefer? Jazz is my personal favorite."
textToSpeech.synthesize(text) { audio in
    audioPlayer = try! AVAudioPlayer(data: audio)
    audioPlayer?.prepareToPlay()
    audioPlayer?.play()
}
```

The `textToSpeech.synthesize` function requests WAV audio data from the service. The audio data is passed to the completion handler, which constructs an `AVAudioPlayer` object to play it.

### Chat Bot

Now that we've explored each service independently, let's combine them to make a voice-to-voice chat bot.

Open the `Chat Bot` playground page. This playground page demonstrates how to chain the services together, using the output of one service as the input of another.

Executing this page should print the following lines in the debug console:

```
Transcription:  turn the radio on 
Reply: Sure thing! Which genre would you prefer? Jazz is my personal favorite.
```

The playground environment allowed us to experiment with each service, quickly get up-and-running, and immediately see the effects of our code. Now let's apply what we've learned to build an iOS app with voice-to-voice chat.

## Simple Chat App

Let's build a voice-to-voice chat app using the Speech to Text, Conversation, and Text to Speech services. Our app will:

1. Transcribe audio to text using Speech to Text.
2. Send the text to Conversation and receive a text reply.
3. Synthesize the text reply to spoken word using Text to Speech.

We will build our application by modifying a provided starter app.

### Starter App

The provided starter app already includes the user interface and Watson Swift SDK. It will be helpful to understand the starter app before modifying it.

To view the starter app, open `Simple Chat.xcworkspace` in Xcode. Copy your `Credentials.swift` file into the `Simple Chat` folder, then run the app in the simulator. Open `ViewController.swift` in Xcode to skim the provided code.

### Conversation Greeting

Let's add support for the Conversation service to our application. This will enable users to send a text message and receive a text reply.

Our application already has a `startConversation` stub that is executed by `viewDidLoad`. Add the following code to the `startConversation` function to start a new conversation each time our app is loaded:

```swift
/// Start a new conversation
func startConversation() {
    conversation.message(
        workspaceID: workspace,
        failure: failure,
        success: presentResponse
    )
}
```

The response from the Conversation service is handled by the `presentResponse` stub. Let's add the following code to `presentResponse` to extract the text reply and add it to the chat window:

```swift
/// Present a conversation reply and speak it to the user
func presentResponse(_ response: MessageResponse) {
    let text = response.output.text.joined()
    context = response.context // save context to continue conversation
    
    // TODO: synthesize and speak the response
    
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
```

If you run the app, you should now see a greeting from the Conversation service: "Hi. It looks like a nice drive today. What would you like me to do?"

### Conversation Messages

Now that we start a new conversation every time our app loads, let's modify the `didPressSend` function to send text messages to the Conversation service.

Add the following code to the end of the `didPressSend` function:

```swift
// send text to conversation service
let input = InputData(text: text)
let request = MessageRequest(input: input, context: context)
conversation.message(
    workspaceID: workspace,
    request: request,
    failure: failure,
    success: presentResponse
)
```

If you run the app, you should be able to converse with the Conversation service. Now we have a working text-to-text chat app!

### Text to Speech

Let's extend our text-to-text chat app with voice support. We will synthesize each text reply to spoken word using the Text to Speech service.

Add the following code to the `presentResponse` function to speak the response:

```swift
// synthesize and speak the response
textToSpeech.synthesize(text, failure: failure) { audio in
    self.audioPlayer = try! AVAudioPlayer(data: audio)
    self.audioPlayer?.prepareToPlay()
    self.audioPlayer?.play()
}
```

If you run the app, you should hear Watson speak the Conversation greeting.

### Speech to Text

Let's add support for the Speech to Text service to enable users to speak their message. The microphone button is already configured to execute the `startTranscribing` stub when pressed down, and the `stopTranscribing` stub when released.

Add the following code to the `startTranscribing` function to recognize microphone audio:

```swift
/// Start transcribing microphone audio
func startTranscribing() {
    audioPlayer?.stop()
    var settings = RecognitionSettings(contentType: .opus)
    settings.interimResults = true
    speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
        self.inputToolbar.contentView.textView.text = results.bestTranscript
        self.inputToolbar.toggleSendButtonEnabled()
    }
}
```

This `settings` object defines a configuration for our Speech to Text request. In this case, it identifies the audio format as Opus. The `interimResults` property enables our app to receive results as they are processed, instead of waiting for the entire audio recording to upload. Note that the entire audio stream will be transcribed until it terminates.

To stop recognizing microphone audio when the button is released, add the following code to the `stopTranscribing` function:

```swift
/// Stop transcribing microphone audio
func stopTranscribing() {
    speechToText.stopRecognizeMicrophone()
}
```

Run the application to play with your complete voice-to-voice chat app!

## Resources

Watson Developer Cloud:
- [Watson Developer Cloud](https://www.ibm.com/watson/developercloud/)
- [Watson Developer Cloud GitHub](https://github.com/watson-developer-cloud)
- [Watson Developer Cloud Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)

Watson Swift SDK:
- [Readme](https://github.com/watson-developer-cloud/swift-sdk/blob/master/README.md)
- [Quick Start Guide](https://github.com/watson-developer-cloud/swift-sdk/blob/master/docs/quickstart.md)
- [Sample Apps](https://github.com/watson-developer-cloud/swift-sdk#sample-applications)
- [Documentation](http://watson-developer-cloud.github.io/swift-sdk/)

Swift@IBM:
- [Swift@IBM Developer Center](https://developer.ibm.com/swift/)
- [Kitura Developer Center](https://developer.ibm.com/swift/kitura/)
