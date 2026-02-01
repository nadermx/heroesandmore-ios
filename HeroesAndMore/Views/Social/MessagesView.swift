import SwiftUI

struct MessagesView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadConversations() }
                }
            } else if conversations.isEmpty {
                EmptyStateView(
                    icon: "message",
                    title: "No Messages",
                    message: "Your conversations will appear here"
                )
            } else {
                List(conversations) { conversation in
                    NavigationLink {
                        ConversationView(conversationId: conversation.id, otherUser: conversation.otherUser)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Messages")
        .task {
            await loadConversations()
        }
        .refreshable {
            await loadConversations()
        }
    }

    private func loadConversations() async {
        isLoading = true
        error = nil

        do {
            let response = try await SocialService.shared.getConversations()
            conversations = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: conversation.otherUser.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.username)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .medium)

                    Spacer()

                    if let date = conversation.lastMessageAt {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
    }
}

struct ConversationView: View {
    let conversationId: Int
    let otherUser: ConversationUser

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var newMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, otherUser: otherUser.username)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Message input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser.username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
        }
    }

    private func loadMessages() async {
        isLoading = true

        do {
            let response = try await SocialService.shared.getMessages(conversationId: conversationId)
            messages = response.results.reversed()
        } catch {}

        isLoading = false
    }

    private func sendMessage() async {
        let content = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        newMessage = ""

        // Note: In a real app, you'd need the user ID, not conversation ID
        // This is simplified for the example
    }
}

struct MessageBubble: View {
    let message: Message
    let otherUser: String

    var isFromMe: Bool {
        message.sender != otherUser
    }

    var body: some View {
        HStack {
            if isFromMe { Spacer() }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromMe ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isFromMe ? .white : .primary)
                    .cornerRadius(16)

                if let date = message.created {
                    Text(date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !isFromMe { Spacer() }
        }
    }
}

#Preview {
    NavigationStack {
        MessagesView()
    }
}
