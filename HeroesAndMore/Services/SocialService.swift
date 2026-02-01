import Foundation

actor SocialService {
    static let shared = SocialService()

    private init() {}

    // MARK: - Feed

    func getFeed(page: Int = 1) async throws -> PaginatedResponse<FeedItem> {
        return try await APIClient.shared.request(
            path: "/social/feed/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    // MARK: - Following/Followers

    func getFollowing(page: Int = 1) async throws -> PaginatedResponse<FollowUser> {
        return try await APIClient.shared.request(
            path: "/social/following/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getFollowers(page: Int = 1) async throws -> PaginatedResponse<FollowUser> {
        return try await APIClient.shared.request(
            path: "/social/followers/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func followUser(userId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/social/follow/\(userId)/",
            method: .post
        )
    }

    func unfollowUser(userId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/social/follow/\(userId)/",
            method: .delete
        )
    }

    // MARK: - Messages

    func getConversations(page: Int = 1) async throws -> PaginatedResponse<Conversation> {
        return try await APIClient.shared.request(
            path: "/social/messages/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getMessages(conversationId: Int, page: Int = 1) async throws -> PaginatedResponse<Message> {
        return try await APIClient.shared.request(
            path: "/social/messages/\(conversationId)/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func sendMessage(toUserId: Int, content: String) async throws -> Message {
        struct SendRequest: Codable {
            let toUserId: Int
            let content: String

            enum CodingKeys: String, CodingKey {
                case toUserId = "to_user_id"
                case content
            }
        }

        return try await APIClient.shared.request(
            path: "/social/messages/send/",
            method: .post,
            body: SendRequest(toUserId: toUserId, content: content)
        )
    }

    // MARK: - Forums

    func getForumCategories() async throws -> [ForumCategory] {
        return try await APIClient.shared.request(path: "/social/forums/")
    }

    func getThreads(categoryId: Int? = nil, page: Int = 1) async throws -> PaginatedResponse<ForumThread> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "category", value: String(categoryId)))
        }

        return try await APIClient.shared.request(
            path: "/social/forums/threads/",
            queryItems: queryItems
        )
    }

    func getThread(id: Int) async throws -> ForumThread {
        return try await APIClient.shared.request(path: "/social/forums/threads/\(id)/")
    }

    func getThreadPosts(threadId: Int, page: Int = 1) async throws -> PaginatedResponse<ForumPost> {
        return try await APIClient.shared.request(
            path: "/social/forums/threads/\(threadId)/posts/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func createThread(categoryId: Int, title: String, content: String) async throws -> ForumThread {
        struct CreateRequest: Codable {
            let categoryId: Int
            let title: String
            let content: String

            enum CodingKeys: String, CodingKey {
                case categoryId = "category_id"
                case title, content
            }
        }

        return try await APIClient.shared.request(
            path: "/social/forums/threads/",
            method: .post,
            body: CreateRequest(categoryId: categoryId, title: title, content: content)
        )
    }

    func replyToThread(threadId: Int, content: String) async throws -> ForumPost {
        struct ReplyRequest: Codable {
            let content: String
        }

        return try await APIClient.shared.request(
            path: "/social/forums/threads/\(threadId)/posts/",
            method: .post,
            body: ReplyRequest(content: content)
        )
    }
}
