//
//  Models.swift
//  SommAI
//
//  Created by Mahadik, Amit on 10/4/25.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

struct AskRequest: Codable {
    let query: String
    let session_id: String?  // keep for future, not required
}

struct AskResponse: Decodable {
    let answer: String?
}

