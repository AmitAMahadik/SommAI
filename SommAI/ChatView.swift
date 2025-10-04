//
//  ChatView.swift
//  SommAI
//
//  Created by Mahadik, Amit on 10/4/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @State private var input = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: msg.role == .assistant ? "wineglass" : "person")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)

                                Text(msg.text)
                                    .padding(10)
                                    .background(msg.role.bubbleBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Spacer(minLength: 0)
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: vm.messages) {
                    if let last = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            if let err = vm.errorMessage {
                Text(err).foregroundColor(.red).padding(.horizontal)
            }

            HStack(spacing: 8) {
                TextField("Describe the dish (e.g., truffle risotto)…", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .disabled(vm.isLoading)

                Button {
                    let q = input
                    input = ""
                    focused = false
                    vm.send(q)
                } label: {
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .imageScale(.medium)
                    }
                }
                .disabled(vm.isLoading)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
        }
        .navigationTitle("SommAI")
    }
}

private extension ChatMessage.Role {
    var bubbleBackground: AnyShapeStyle {
        switch self {
        case .assistant:
            return AnyShapeStyle(.ultraThinMaterial)
        default:
            return AnyShapeStyle(Color(UIColor.secondarySystemFill))
        }
    }
}

#Preview {
    ChatView()
}
