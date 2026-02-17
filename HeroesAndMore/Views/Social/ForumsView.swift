import SwiftUI

struct ForumsView: View {
    @State private var categories: [ForumCategory] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadCategories() }
                }
            } else if categories.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No Forums",
                    message: "Forums are not available"
                )
            } else {
                List(categories) { category in
                    NavigationLink {
                        ForumCategoryView(category: category)
                    } label: {
                        ForumCategoryRow(category: category)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Forums")
        .task {
            await loadCategories()
        }
    }

    private func loadCategories() async {
        isLoading = true
        error = nil

        do {
            categories = try await SocialService.shared.getForumCategories()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ForumCategoryRow: View {
    let category: ForumCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name)
                .fontWeight(.medium)

            if let description = category.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Label("\(category.threadCount)", systemImage: "text.bubble")
                Label("\(category.postCount)", systemImage: "message")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ForumCategoryView: View {
    let category: ForumCategory

    @State private var threads: [ForumThread] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadThreads() }
                }
            } else if threads.isEmpty {
                EmptyStateView(
                    icon: "text.bubble",
                    title: "No Threads",
                    message: "Be the first to start a discussion",
                    actionTitle: "New Thread"
                ) {
                    showCreateSheet = true
                }
            } else {
                List(threads) { thread in
                    NavigationLink {
                        ForumThreadView(thread: thread)
                    } label: {
                        ForumThreadRow(thread: thread)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadThreads()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateThreadSheet(categoryId: category.id) {
                Task { await loadThreads() }
            }
        }
    }

    private func loadThreads() async {
        isLoading = true
        error = nil

        do {
            let response = try await SocialService.shared.getThreads(categoryId: category.id)
            threads = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ForumThreadRow: View {
    let thread: ForumThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.brandGold)
                }

                Text(thread.title)
                    .fontWeight(.medium)

                if thread.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                AvatarView(url: thread.authorAvatarUrl, size: 20)
                Text(thread.author)
                    .font(.caption)

                Spacer()

                Label("\(thread.replyCount)", systemImage: "bubble.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(thread.viewCount)", systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastPost = thread.lastPostAt {
                Text("Last reply \(lastPost, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ForumThreadView: View {
    let thread: ForumThread

    @State private var posts: [ForumPost] = []
    @State private var isLoading = true
    @State private var replyText = ""

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            ForumPostView(post: post)
                        }
                    }
                    .padding()
                }
            }

            if !thread.isLocked {
                HStack(spacing: 12) {
                    TextField("Write a reply...", text: $replyText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await postReply() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        isLoading = true

        do {
            let response = try await SocialService.shared.getThreadPosts(threadId: thread.id)
            posts = response.results
        } catch {}

        isLoading = false
    }

    private func postReply() async {
        let content = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        do {
            let newPost = try await SocialService.shared.replyToThread(threadId: thread.id, content: content)
            posts.append(newPost)
            replyText = ""
        } catch {}
    }
}

struct ForumPostView: View {
    let post: ForumPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AvatarView(url: post.authorAvatarUrl, size: 40)

                VStack(alignment: .leading) {
                    Text(post.author)
                        .fontWeight(.medium)

                    if let date = post.created {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            Text(post.content)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CreateThreadSheet: View {
    let categoryId: Int
    var onCreated: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Thread Title", text: $title)
                }

                Section("Content") {
                    TextField("Write your post...", text: $content, axis: .vertical)
                        .lineLimit(5...15)
                }
            }
            .navigationTitle("New Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Post") {
                        Task { await createThread() }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isLoading)
                }
            }
        }
    }

    private func createThread() async {
        isLoading = true

        do {
            _ = try await SocialService.shared.createThread(
                categoryId: categoryId,
                title: title,
                content: content
            )
            onCreated()
            dismiss()
        } catch {}

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ForumsView()
    }
}
