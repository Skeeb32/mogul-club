import SwiftUI
import UIKit

struct CommunityPostCard: View {
    let post: ClubPost
    @ObservedObject var store: ClubsStore
    @State private var showComments = false
    @State private var showEdit = false
    @State private var showReport = false
    @State private var showReportComplete = false
    @State private var copiedLink = false
    private var author: ClubDemoUser { store.user(post.authorID) }
    private var commentsCount: Int { store.comments(for: post.id).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                NavigationLink { UserProfileView(user: author, store: store) } label: { CommunityAvatar(user: author, size: 42) }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    NavigationLink { UserProfileView(user: author, store: store) } label: { Text(author.displayName).font(.subheadline.weight(.bold)).foregroundStyle(.primary) }.buttonStyle(.plain)
                    HStack(spacing: 5) { Text("@\(author.username)"); Text("·"); Text(post.createdAt.formatted(.relative(presentation: .named))) }
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Label(post.kind.title, systemImage: post.kind.icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(ClubStyle.emerald)
                Menu {
                    if post.authorID == store.currentUserID { Button("Edit post", systemImage: "pencil") { showEdit = true } }
                    if post.authorID == store.currentUserID || store.canModerate(post.clubID) { Button("Delete post", systemImage: "trash", role: .destructive) { store.deletePost(post.id) } }
                    Button("Copy post link", systemImage: "link") { UIPasteboard.general.string = "https://mogul.club/posts/\(post.id)"; copiedLink = true }
                    Button("Report post", systemImage: "flag", role: .destructive) { showReport = true }
                } label: { Image(systemName: "ellipsis").padding(5).contentShape(Rectangle()) }
                    .accessibilityLabel("Post options")
            }
            if post.isPinned { Label("Pinned by club moderators", systemImage: "pin.fill").font(.caption2.weight(.semibold)).foregroundStyle(ClubStyle.emerald) }
            Text(post.content).font(.subheadline).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            if let imageURL = post.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() }
                    else { ZStack { ClubStyle.emerald.opacity(0.12); Image(systemName: "photo").font(.largeTitle).foregroundStyle(ClubStyle.emerald) } }
                }.frame(height: 190).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityLabel("Photo shared in this post")
            }
            if let linkURL = post.linkURL, let url = URL(string: linkURL) { Link(destination: url) { Label("Open shared resource", systemImage: "link").font(.caption.weight(.semibold)) } }
            if post.kind == .poll { PollChoicesView(post: post, store: store) }
            if post.kind == .event, let event = store.events.first(where: { $0.clubID == post.clubID && Calendar.current.isDate($0.date, inSameDayAs: post.createdAt) }) { ClubEventCard(event: event, store: store) }
            HStack(spacing: 12) {
                if post.likedBy.count + store.reactions.filter({ $0.postID == post.id }).count > 0 {
                    Label("\(post.likedBy.count + store.reactions.filter({ $0.postID == post.id }).count)", systemImage: "heart.fill").foregroundStyle(.secondary)
                }
                let emojiCounts = ["🔥", "👏", "💡"].filter { store.reactionCount(post, emoji: $0) > 0 }
                ForEach(emojiCounts, id: \.self) { emoji in Text("\(emoji) \(store.reactionCount(post, emoji: emoji))").font(.caption2) }
                Spacer()
                Button { showComments = true } label: { Text("\(commentsCount) comments").font(.caption).foregroundStyle(.secondary) }
                    .buttonStyle(.plain).accessibilityIdentifier("open-comments-\(post.id)")
            }.font(.caption2)
            Divider()
            HStack(spacing: 0) {
                Button { store.toggleLike(post.id) } label: { Label(store.hasLiked(post.id) ? "Liked" : "Like", systemImage: store.hasLiked(post.id) ? "heart.fill" : "heart").foregroundStyle(store.hasLiked(post.id) ? .red : .secondary) }
                    .accessibilityIdentifier("like-\(post.id)")
                Spacer()
                Menu {
                    ForEach(["🔥", "👏", "💡", "❤️", "😂"], id: \.self) { emoji in Button("\(emoji)  React", systemImage: "face.smiling") { store.toggleReaction(post.id, emoji: emoji) } }
                } label: { Label("React", systemImage: "face.smiling").foregroundStyle(.secondary) }.accessibilityLabel("React to post")
                Spacer()
                Button { showComments = true } label: { Label("Comment", systemImage: "bubble.right").foregroundStyle(.secondary) }
                Spacer()
                ShareLink(item: URL(string: "https://mogul.club/posts/\(post.id)")!) { Label("Share", systemImage: "square.and.arrow.up").foregroundStyle(.secondary) }
            }.font(.caption.weight(.semibold)).buttonStyle(.plain)
        }
        .padding(14).background(.background, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showComments) { ClubPostCommentsSheet(post: post, store: store) }
        .sheet(isPresented: $showEdit) { EditPostSheet(post: post, store: store) }
        .confirmationDialog("Report this post?", isPresented: $showReport, titleVisibility: .visible) {
            Button("Send to club moderators", role: .destructive) { store.reportPost(post.id); showReportComplete = true }
            Button("Cancel", role: .cancel) { }
        } message: { Text("A fictional demo report will be added for moderator review. It does not contact an external service.") }
        .alert(copiedLink ? "Link copied" : "", isPresented: $copiedLink) { Button("OK") { } }
        .alert("Report recorded", isPresented: $showReportComplete) { Button("OK") { } } message: { Text("The demo report was recorded locally.") }
    }
}

struct PollChoicesView: View {
    let post: ClubPost
    @ObservedObject var store: ClubsStore
    private var selectedOption: Int? { store.vote(for: post.id) }
    private var totalVotes: Int { post.pollOptions.indices.reduce(0) { $0 + store.voteCount(postID: post.id, option: $1) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(post.pollOptions.enumerated()), id: \.offset) { index, option in
                Button { store.vote(postID: post.id, option: index) } label: {
                    HStack(spacing: 8) {
                        Text(option).font(.caption.weight(.semibold))
                        Spacer()
                        if selectedOption != nil || totalVotes > 0 { Text("\(totalVotes == 0 ? 0 : store.voteCount(postID: post.id, option: index) * 100 / max(totalVotes, 1))%").font(.caption2.monospacedDigit()) }
                        if selectedOption == index { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding(10).background(selectedOption == index ? ClubStyle.emerald.opacity(0.14) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(alignment: .leading) { if totalVotes > 0 { GeometryReader { proxy in Rectangle().fill(ClubStyle.emerald.opacity(0.12)).frame(width: proxy.size.width * CGFloat(store.voteCount(postID: post.id, option: index)) / CGFloat(max(totalVotes, 1))) }.clipShape(RoundedRectangle(cornerRadius: 9)).allowsHitTesting(false) } }
                }.buttonStyle(.plain).disabled(selectedOption != nil || !store.isMember(post.clubID)).accessibilityIdentifier("poll-\(post.id)-\(index)")
            }
            Text("\(totalVotes) votes · \(selectedOption == nil ? "Vote once" : "Your vote is in")").font(.caption2).foregroundStyle(.secondary)
        }.padding(10).background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ClubEventCard: View {
    let event: ClubEvent
    @ObservedObject var store: ClubsStore
    var isPast = false
    var body: some View {
        HStack(spacing: 12) {
            ClubIdentityAvatar(url: event.imageURL, initials: event.title.initials, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.bold)).lineLimit(2)
                Text(event.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                Label(event.location, systemImage: event.isOnline ? "video" : "mappin.and.ellipse").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Text("Hosted by \(store.user(event.hostID).displayName) · \(store.rsvpCount(event)) going").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            if isPast { Text("Past").font(.caption2.weight(.semibold)).foregroundStyle(.secondary) }
            else {
                Button(store.hasRSVP(event.id) ? "Going" : "RSVP") { store.toggleRSVP(event.id) }
                    .font(.caption.weight(.bold)).padding(.horizontal, 11).padding(.vertical, 8)
                    .background(store.hasRSVP(event.id) ? Color(.secondarySystemBackground) : ClubStyle.emerald, in: Capsule())
                    .foregroundStyle(store.hasRSVP(event.id) ? Color.primary : Color.white)
                    .disabled(!store.isMember(event.clubID))
                    .accessibilityIdentifier("rsvp-\(event.id)")
            }
        }.padding(11).background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ClubPostCommentsSheet: View {
    let post: ClubPost
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var replyingTo: ClubComment?
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(store.rootComments(for: post.id)) { comment in
                            commentRow(comment)
                            ForEach(store.comments(for: post.id).filter { $0.parentID == comment.id }) { reply in commentRow(reply, isReply: true) }
                        }
                    }.padding(15)
                }
                if !store.isMember(post.clubID) {
                    Text("Join the club to comment.").font(.caption).foregroundStyle(.secondary).padding(14).frame(maxWidth: .infinity).background(.bar)
                } else {
                    VStack(spacing: 5) {
                        if let replyingTo { HStack { Text("Replying to \(store.user(replyingTo.authorID).displayName)").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Cancel") { self.replyingTo = nil }.font(.caption) } }
                        HStack(spacing: 8) {
                            CommunityAvatar(user: store.currentUser, size: 34)
                            TextField(replyingTo == nil ? "Write a comment…" : "Write a reply…", text: $text, axis: .vertical).lineLimit(1...4).textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("comment-input")
                            Button { submit() } label: { Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundStyle(ClubStyle.emerald) }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityLabel("Send comment")
                        }
                    }.padding(12).background(.bar)
                }
            }
            .navigationTitle("Comments").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    @ViewBuilder private func commentRow(_ comment: ClubComment, isReply: Bool = false) -> some View {
        let author = store.user(comment.authorID)
        HStack(alignment: .top, spacing: 9) {
            if isReply { Rectangle().fill(Color(.separator)).frame(width: 2).padding(.leading, 8).padding(.trailing, 3) }
            NavigationLink { UserProfileView(user: author, store: store) } label: { CommunityAvatar(user: author, size: 34) }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) { Text(author.displayName).font(.caption.weight(.bold)); Text(comment.createdAt.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.secondary) }
                Text(comment.content).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Button { store.toggleCommentLike(comment.id) } label: { Label("\(comment.likedBy.count)", systemImage: comment.likedBy.contains(store.currentUserID) ? "heart.fill" : "heart") }.foregroundStyle(comment.likedBy.contains(store.currentUserID) ? .red : .secondary)
                    if !isReply { Button("Reply") { replyingTo = comment }.foregroundStyle(.secondary) }
                }.font(.caption2.weight(.semibold))
            }
            Spacer(minLength: 0)
        }.padding(10).background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
    private func submit() { if store.addComment(postID: post.id, text: text, parentID: replyingTo?.id) { text = ""; replyingTo = nil } }
}

struct CreatePostSheet: View {
    let club: DemoClub
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: ClubPostKind = .text
    @State private var content = ""
    @State private var imageURL = ""
    @State private var linkURL = ""
    @State private var options = ["", ""]
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Post type") {
                    Picker("Format", selection: $kind) { ForEach(ClubPostKind.allCases) { Text($0.title).tag($0) } }
                }
                Section("Your post") {
                    TextField(kind == .question ? "Ask your question…" : "What would you like to share?", text: $content, axis: .vertical).lineLimit(4...9).accessibilityIdentifier("post-content")
                    if kind == .image { TextField("Image URL (optional)", text: $imageURL).keyboardType(.URL).textInputAutocapitalization(.never) }
                    if kind == .link { TextField("https://…", text: $linkURL).keyboardType(.URL).textInputAutocapitalization(.never) }
                }
                if kind == .poll {
                    Section("Poll options") {
                        ForEach(options.indices, id: \.self) { index in TextField("Option \(index + 1)", text: $options[index]) }
                        Button("Add option") { if options.count < 6 { options.append("") } }.disabled(options.count >= 6)
                    }
                }
                if let error { Section { Text(error).font(.caption).foregroundStyle(.red) } }
                Section { Text("This content is saved to this device as fictional demo community data. It is not sent to other users.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Create a post").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Post") { submit() }.fontWeight(.bold).accessibilityIdentifier("publish-post") }
            }
        }
    }
    private func submit() {
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { error = "Add a little more to your post."; return }
        if kind == .link, !linkURL.isEmpty, URL(string: linkURL)?.scheme == nil { error = "Enter a valid link starting with https://."; return }
        guard store.makePost(clubID: club.id, kind: kind, text: content, imageURL: imageURL, linkURL: linkURL, options: options) else { error = "Join the club and complete all required fields first."; return }
        dismiss()
    }
}

struct EditPostSheet: View {
    let post: ClubPost
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    init(post: ClubPost, store: ClubsStore) { self.post = post; self.store = store; _content = State(initialValue: post.content) }
    var body: some View {
        NavigationStack {
            Form { Section("Edit post") { TextField("Post content", text: $content, axis: .vertical).lineLimit(5...10) } }
                .navigationTitle("Edit post").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { if store.editPost(post.id, text: content) { dismiss() } } } }
        }
    }
}

struct CreateClubSheet: View {
    @ObservedObject var store: ClubsStore
    let onCreated: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var category = "House Hacking"
    @State private var coverURL = ""
    @State private var avatarURL = ""
    @State private var visibility: ClubVisibility = .public
    @State private var rule1 = "Be respectful and constructive."
    @State private var rule2 = "Share useful context and credit others."
    @State private var welcome = ""
    @State private var error: String?
    private let categories = ["Luxury Homes", "House Hacking", "Market Talk", "Multifamily", "Short-Term Rentals", "First-Time Investors", "Renovation", "Wholesaling", "Property Management", "Financial Freedom", "Commercial", "Design & Architecture"]
    var body: some View {
        NavigationStack {
            Form {
                Section("Club basics") {
                    TextField("Club name (required)", text: $name).accessibilityIdentifier("new-club-name")
                    TextField("Description (required)", text: $description, axis: .vertical).lineLimit(3...6).accessibilityIdentifier("new-club-description")
                    Picker("Category", selection: $category) { ForEach(categories, id: \.self) { Text($0) } }
                    Picker("Visibility", selection: $visibility) { ForEach(ClubVisibility.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                }
                Section("Club artwork") {
                    TextField("Cover image URL (optional)", text: $coverURL).keyboardType(.URL).textInputAutocapitalization(.never)
                    TextField("Club avatar URL (optional)", text: $avatarURL).keyboardType(.URL).textInputAutocapitalization(.never)
                    Text("Leave blank to use a color and initials fallback.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Community rules") { TextField("Rule 1", text: $rule1); TextField("Rule 2", text: $rule2) }
                Section("Welcome message (optional)") { TextField("Say hello to new members", text: $welcome, axis: .vertical).lineLimit(2...4) }
                if let error { Section { Text(error).font(.caption).foregroundStyle(.red) } }
                Section { Text("You will be the owner. The new community and its posts are stored locally on this device for demo purposes.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Create a club").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Create") { create() }.fontWeight(.bold).accessibilityIdentifier("save-new-club") } }
        }
    }
    private func create() {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { error = "Club name must have at least 3 characters."; return }
        guard description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12 else { error = "Add a description of at least 12 characters."; return }
        let chosenCover = validImageURL(coverURL) ?? ""
        let chosenAvatar = validImageURL(avatarURL) ?? ""
        guard (coverURL.isEmpty || !chosenCover.isEmpty), (avatarURL.isEmpty || !chosenAvatar.isEmpty) else { error = "Image URLs must start with https://."; return }
        if let id = store.createClub(name: name, description: description, category: category, coverURL: chosenCover, avatarURL: chosenAvatar, visibility: visibility, rules: [rule1, rule2]) {
            if !welcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { _ = store.makePost(clubID: id, kind: .announcement, text: welcome) }
            dismiss(); onCreated(id)
        } else { error = "Check the required fields and try again." }
    }
    private func validImageURL(_ text: String) -> String? { guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme == "https" else { return nil }; return url.absoluteString }
}

struct DemoUserPickerSheet: View {
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    private var personas: [(String, String, String)] { [("Regular member", "user_001", "A member of a couple of clubs."), ("Club owner", store.clubs[0].creatorID, "Club owner with moderation controls."), ("Moderator", store.clubs[0].moderatorIDs[0], "Moderator in the featured community."), ("Active member", "user_010", "Frequent contributor across clubs."), ("New member", "user_072", "A fresh account with no club memberships.")] }
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Switch between fictional demo accounts to explore different memberships and permissions. This does not change your real signed-in account.").font(.caption).foregroundStyle(.secondary) }
                Section("Demo personas") {
                    ForEach(personas, id: \.1) { persona in userRow(id: persona.1, title: persona.0, subtitle: persona.2) }
                }
                Section("All demo profiles") {
                    ForEach(store.users.filter { !personas.map(\.1).contains($0.id) }) { user in userRow(id: user.id, title: user.displayName, subtitle: "@\(user.username)") }
                }
            }.navigationTitle("Switch demo user").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    private func userRow(id: String, title: String, subtitle: String) -> some View {
        let user = store.user(id)
        return Button { store.switchUser(to: id); dismiss() } label: {
            HStack(spacing: 10) { CommunityAvatar(user: user, size: 42); VStack(alignment: .leading) { Text(title).font(.subheadline.weight(.semibold)); Text(subtitle).font(.caption).foregroundStyle(.secondary) }; Spacer(); if store.currentUserID == id { Image(systemName: "checkmark.circle.fill").foregroundStyle(ClubStyle.emerald) } }
        }.buttonStyle(.plain)
    }
}

struct NotificationsSheet: View {
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                if store.currentNotices().isEmpty { ContentUnavailableView("You’re all caught up", systemImage: "bell", description: Text("Community notifications will appear here.")) }
                ForEach(store.currentNotices()) { notice in
                    Button { store.markRead(notice.id); if let id = notice.clubID { dismiss(); NotificationCenter.default.post(name: .openDemoClub, object: id) } } label: {
                        HStack(alignment: .top, spacing: 11) {
                            CommunityAvatar(user: store.user(notice.actorID), size: 40)
                            VStack(alignment: .leading, spacing: 4) { Text("\(store.user(notice.actorID).displayName) \(notice.message)").font(.subheadline); Text(notice.createdAt.formatted(.relative(presentation: .named))).font(.caption).foregroundStyle(.secondary) }
                            Spacer(minLength: 0)
                            if !notice.isRead { Circle().fill(ClubStyle.emerald).frame(width: 8, height: 8) }
                        }.padding(.vertical, 4)
                    }.buttonStyle(.plain)
                }
                .onDelete { offsets in let current = store.currentNotices(); for index in offsets { store.dismissNotice(current[index].id) } }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Mark all read") { store.markAllRead() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

extension Notification.Name { static let openDemoClub = Notification.Name("mogul.openDemoClub") }

struct MediaViewerSheet: View {
    let post: ClubPost
    @ObservedObject var store: ClubsStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ClubCover(url: post.imageURL ?? "", height: 360)
                    HStack(spacing: 9) { CommunityAvatar(user: store.user(post.authorID), size: 38); VStack(alignment: .leading) { Text(store.user(post.authorID).displayName).font(.subheadline.weight(.semibold)); Text(post.createdAt.formatted(.relative(presentation: .named))).font(.caption).foregroundStyle(.secondary) } }
                    Text(post.content).font(.body)
                    Label("Original club post", systemImage: "text.bubble").font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                }.padding(18)
            }.background(Color(.systemGroupedBackground)).navigationTitle("Club media").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct UserProfileView: View {
    let user: ClubDemoUser
    @ObservedObject var store: ClubsStore
    @State private var selectedPost: ClubPost?
    @State private var showMessageNotice = false
    private var joined: [DemoClub] { store.joinedClubs(for: user.id) }
    private var recentPosts: [ClubPost] { store.posts.filter { $0.authorID == user.id }.sorted { $0.createdAt > $1.createdAt }.prefix(8).map { $0 } }
    private var mutualClubs: [DemoClub] { let theirs = Set(joined.map(\.id)); return store.joinedClubs().filter { theirs.contains($0.id) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DemoNotice()
                profileHeader
                interestsSection
                mutualClubsSection
                recentPostsSection
            }.padding(17).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }.background(Color(.systemGroupedBackground)).navigationTitle(user.displayName).navigationBarTitleDisplayMode(.inline)
            .alert("Messaging isn’t enabled", isPresented: $showMessageNotice) { Button("OK") { } } message: { Text("This demo has no private messaging backend, so no external messages are sent.") }
    }

    private var profileHeader: some View {
        VStack(spacing: 9) {
            CommunityAvatar(user: user, size: 88)
            Text(user.displayName).font(.title2.weight(.bold))
            Text("@\(user.username)").font(.subheadline).foregroundStyle(.secondary)
            Text(user.bio).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary)
            HStack(spacing: 24) {
                profileMetric(value: store.followerCount(user.id), label: "followers")
                profileMetric(value: store.followingCount(user.id), label: "following")
                profileMetric(value: joined.count, label: "clubs")
            }.padding(.vertical, 5)
            if user.id != store.currentUserID { followAndMessageButtons }
        }.padding(19).frame(maxWidth: .infinity).background(.background, in: RoundedRectangle(cornerRadius: 17))
    }

    private func profileMetric(value: Int, label: String) -> some View {
        VStack { Text("\(value)").font(.headline); Text(label).font(.caption).foregroundStyle(.secondary) }
    }

    private var followAndMessageButtons: some View {
        HStack {
            Button(store.isFollowing(user.id) ? "Following" : "Follow") { store.toggleFollow(user.id) }
                .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).padding(11)
                .background(store.isFollowing(user.id) ? Color(.secondarySystemBackground) : ClubStyle.emerald, in: Capsule())
                .foregroundStyle(store.isFollowing(user.id) ? Color.primary : Color.white)
                .accessibilityIdentifier("follow-user")
            Button { showMessageNotice = true } label: {
                Label("Message", systemImage: "bubble.left").font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(11).overlay(Capsule().stroke(.secondary.opacity(0.35)))
            }.accessibilityIdentifier("profile-message")
        }.buttonStyle(.plain)
    }

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 8) { Text("Interests").font(.headline); FlowTagRow(tags: user.interests) }
            .padding(15).background(.background, in: RoundedRectangle(cornerRadius: 15))
    }

    private var mutualClubsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text("Mutual clubs").font(.headline); Spacer(); Text("\(mutualClubs.count)").font(.caption).foregroundStyle(.secondary) }
            if mutualClubs.isEmpty { Text("You and \(user.displayName) don’t share any clubs yet.").font(.caption).foregroundStyle(.secondary) }
            ForEach(mutualClubs) { club in
                HStack(spacing: 8) { ClubIdentityAvatar(url: club.avatarURL, initials: club.name.initials, size: 32); Text(club.name).font(.caption.weight(.semibold)) }
            }
        }.padding(15).background(.background, in: RoundedRectangle(cornerRadius: 15))
    }

    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Recent posts").font(.headline)
            if recentPosts.isEmpty { Text("No posts yet.").font(.caption).foregroundStyle(.secondary) }
            ForEach(recentPosts) { post in CommunityPostCard(post: post, store: store) }
        }
    }
}

struct FlowTagRow: View {
    let tags: [String]
    var body: some View { LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .leading)], alignment: .leading, spacing: 7) { ForEach(tags, id: \.self) { tag in Text(tag).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 7).background(ClubStyle.emerald.opacity(0.1), in: Capsule()).foregroundStyle(ClubStyle.emerald) } } }
}
