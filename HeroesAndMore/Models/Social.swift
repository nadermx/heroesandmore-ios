import Foundation

struct FeedItem: Codable, Identifiable {
    let id: Int
    let type: String
    let user: FeedUser
    let content: FeedContent
    let created: Date?
}

struct FeedUser: Codable {
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case username
        case avatarUrl = "avatar_url"
    }
}

struct FeedContent: Codable {
    let listingId: Int?
    let listingTitle: String?
    let listingImage: String?
    let collectionId: Int?
    let collectionName: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case message
        case listingId = "listing_id"
        case listingTitle = "listing_title"
        case listingImage = "listing_image"
        case collectionId = "collection_id"
        case collectionName = "collection_name"
    }
}

struct FollowUser: Codable, Identifiable {
    var id: String { username }
    let username: String
    let avatarUrl: String?
    let bio: String?
    let isFollowing: Bool

    enum CodingKeys: String, CodingKey {
        case username, bio
        case avatarUrl = "avatar_url"
        case isFollowing = "is_following"
    }
}

struct Conversation: Codable, Identifiable {
    let id: Int
    let otherUser: ConversationUser
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case otherUser = "other_user"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
    }
}

struct ConversationUser: Codable {
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case username
        case avatarUrl = "avatar_url"
    }
}

struct Message: Codable, Identifiable {
    let id: Int
    let sender: String
    let content: String
    let isRead: Bool
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, sender, content, created
        case isRead = "is_read"
    }
}

struct ForumCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let threadCount: Int
    let postCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case threadCount = "thread_count"
        case postCount = "post_count"
    }
}

struct ForumThread: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String
    let authorAvatarUrl: String?
    let category: ForumCategory?
    let replyCount: Int
    let viewCount: Int
    let isPinned: Bool
    let isLocked: Bool
    let lastPostAt: Date?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, author, category, created
        case authorAvatarUrl = "author_avatar_url"
        case replyCount = "reply_count"
        case viewCount = "view_count"
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case lastPostAt = "last_post_at"
    }
}

struct ForumPost: Codable, Identifiable {
    let id: Int
    let content: String
    let author: String
    let authorAvatarUrl: String?
    let created: Date?
    let updated: Date?

    enum CodingKeys: String, CodingKey {
        case id, content, author, created, updated
        case authorAvatarUrl = "author_avatar_url"
    }
}
