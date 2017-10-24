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
import ConversationV1

// Configure playground environment
PlaygroundPage.current.needsIndefiniteExecution = true
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

// Instantiate service
let conversation = Conversation(
    username: Credentials.ConversationUsername,
    password: Credentials.ConversationPassword,
    version: "2017-05-26"
)

// Set conversation workspace
let workspace = Credentials.ConversationWorkspace

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
