import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [Notification] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadNotifications() }
                }
            } else if notifications.isEmpty {
                EmptyStateView(
                    icon: "bell",
                    title: "No Notifications",
                    message: "You're all caught up!"
                )
            } else {
                List {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                            .swipeActions {
                                Button("Read") {
                                    Task {
                                        try? await AlertService.shared.markNotificationRead(id: notification.id)
                                        await loadNotifications()
                                    }
                                }
                                .tint(.brandCrimson)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mark All Read") {
                    Task {
                        try? await AlertService.shared.markAllNotificationsRead()
                        await loadNotifications()
                    }
                }
            }
        }
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
    }

    private func loadNotifications() async {
        isLoading = true
        error = nil

        do {
            let response = try await AlertService.shared.getNotifications()
            notifications = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct NotificationRow: View {
    let notification: Notification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)

                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let date = notification.created {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(.brandCrimson)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch notification.type {
        case "new_bid": return "gavel"
        case "outbid": return "exclamationmark.triangle"
        case "offer": return "hand.raised"
        case "order_shipped": return "shippingbox"
        case "message": return "message"
        case "price_alert": return "chart.line.uptrend.xyaxis"
        default: return "bell"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "new_bid": return .brandMint
        case "outbid": return .brandGold
        case "offer": return .brandCyan
        case "order_shipped": return .brandCyan
        case "message": return .brandCyan
        case "price_alert": return .brandMint
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
