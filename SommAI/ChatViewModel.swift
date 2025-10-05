//
//  ChatViewModel.swift
//  SommAI
//
//  Created by Mahadik, Amit on 10/4/25.
//


import Foundation
internal import Combine

private struct ResponseEnvelope: Decodable {
    let response: String?
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // CHANGE THIS to your API (use http://127.0.0.1:8000 for Simulator)
    private let baseURL = URL(string: "https://demo-container.jollybay-d8b41412.westus.azurecontainerapps.io")!

    func send(_ prompt: String, sessionID: String? = nil) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(.init(role: .user, text: trimmed))
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }

            do {
                var req = URLRequest(url: baseURL.appendingPathComponent("/ask"))
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = AskRequest(query: trimmed, session_id: sessionID)
                req.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                // Prefer structured JSON, then fallback
                let decoder = JSONDecoder()
                if let a = try? decoder.decode(AskResponse.self, from: data), let text = a.answer {
                    messages.append(.init(role: .assistant, text: text))
                } else if let r = try? decoder.decode(ResponseEnvelope.self, from: data), let text = r.response {
                    messages.append(.init(role: .assistant, text: text))
                } else if let raw = String(data: data, encoding: .utf8) {
                    // Sometimes the backend returns a JSON string; try to parse it
                    if let innerData = raw.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any],
                       let text = (obj["response"] as? String) ?? (obj["answer"] as? String) {
                        messages.append(.init(role: .assistant, text: text))
                    } else {
                        messages.append(.init(role: .assistant, text: raw))
                    }
                } else {
                    throw URLError(.cannotDecodeRawData)
                }
            } catch {
                self.errorMessage = "Request failed: \(error.localizedDescription)"
            }
        }
    }
}
