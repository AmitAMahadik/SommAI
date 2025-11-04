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
        // If the prompt is empty, use a fixed recommendation prompt instead.
        let effectivePrompt: String = trimmed.isEmpty ? "Recommend a good wine pairing for the current time in California" : trimmed

        messages.append(.init(role: .user, text: effectivePrompt))
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }

            do {
                var req = URLRequest(url: baseURL.appendingPathComponent("/ask"))
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = AskRequest(query: effectivePrompt, session_id: sessionID)
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

    /// Builds a sensible default query for wine pairing based on the current local time.
    /// This supports triggering from the iPhone Action Button via a Shortcut that calls `send("")`.
    private static func defaultWinePairingPrompt(date: Date = .now) -> String {
        let segment = timeOfDaySegment(for: date)
        let timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        return "Suggest an ideal wine pairing for \(segment) (around \(timeString) local time). " +
               "Give a concise pick with grape/style, region, rough price band, and one quick snack/meal pairing."
    }

    /// Maps the current hour to a human-friendly time-of-day segment used in prompts.
    private static func timeOfDaySegment(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "morning brunch/light fare"
        case 11..<16: return "midday/lunch"
        case 16..<19: return "late afternoon/apéro"
        case 19..<22: return "dinner/evening"
        default: return "late night"
        }
    }
}

