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

import Foundation
import JSQMessagesViewController

enum User: String {
    case me = "053496-4509-288"
    case watson = "053496-4509-289"
    
    static func getName(_ user: User) -> String {
        switch user {
        case .me: return "Me"
        case .watson: return "Watson"
        }
    }
    
    static func getAvatar(_ id: String) -> JSQMessagesAvatarImage? {
        let user = User(rawValue: id)!
        switch user {
        case .me: return nil
        case .watson: return avatarWatson
        }
    }
}

private let avatarWatson = JSQMessagesAvatarImageFactory.avatarImage(
    with: #imageLiteral(resourceName: "watson_avatar"),
    diameter: 24
)
