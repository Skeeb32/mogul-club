import Foundation
import Combine

enum ClubPostKind: String, Codable, CaseIterable, Identifiable {
    case text, image, question, poll, announcement, event, link
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self { case .text: "text.bubble"; case .image: "photo"; case .question: "questionmark.bubble"; case .poll: "chart.bar"; case .announcement: "megaphone"; case .event: "calendar"; case .link: "link" }
    }
}

struct ClubDemoUser: Codable, Identifiable, Equatable {
    var id: String
    var username: String
    var displayName: String
    var avatarURL: String
    var bio: String
    var interests: [String]
}

struct DemoClub: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var slug: String
    var description: String
    var category: String
    var coverURL: String
    var avatarURL: String
    var creatorID: String
    var moderatorIDs: [String]
    var rules: [String]
    var isFeatured: Bool
    var visibility: ClubVisibility
    var createdAt: Date
    var interestTags: [String]
}

enum ClubVisibility: String, Codable, CaseIterable, Identifiable {
    case `public`, `private`
    var id: String { rawValue }
}

struct ClubMembership: Codable, Identifiable, Equatable {
    var id: String { "\(clubID):\(userID)" }
    var clubID: String
    var userID: String
    var role: ClubRole
    var joinedAt: Date
}

enum ClubRole: String, Codable { case owner, moderator, member }

struct ClubPost: Codable, Identifiable, Equatable {
    var id: String
    var clubID: String
    var authorID: String
    var kind: ClubPostKind
    var content: String
    var imageURL: String?
    var linkURL: String?
    var pollOptions: [String]
    var createdAt: Date
    var likedBy: [String]
    var reactions: [PostReaction]
    var isPinned: Bool
}

struct PostReaction: Codable, Identifiable, Equatable {
    var id: String { "\(postID):\(userID):\(emoji)" }
    var postID: String
    var userID: String
    var emoji: String
}

struct ClubComment: Codable, Identifiable, Equatable {
    var id: String
    var postID: String
    var authorID: String
    var parentID: String?
    var content: String
    var createdAt: Date
    var likedBy: [String]
}

struct PollBallot: Codable, Identifiable, Equatable {
    var id: String { "\(postID):\(userID)" }
    var postID: String
    var userID: String
    var optionIndex: Int
}

struct ClubEvent: Identifiable, Equatable {
    var id: String
    var clubID: String
    var title: String
    var description: String
    var imageURL: String
    var date: Date
    var location: String
    var hostID: String
    var attendeeIDs: [String]
    var isOnline: Bool
}

struct EventRSVP: Codable, Identifiable, Equatable {
    var id: String { "\(eventID):\(userID)" }
    var eventID: String
    var userID: String
}

struct ClubFollow: Codable, Identifiable, Equatable {
    var id: String { "\(followerID):\(followedID)" }
    var followerID: String
    var followedID: String
}

struct ClubNotice: Codable, Identifiable, Equatable {
    var id: String
    var recipientID: String
    var actorID: String
    var clubID: String?
    var postID: String?
    var message: String
    var createdAt: Date
    var isRead: Bool
}

private struct PersistedCommunity: Codable {
    var currentUserID: String
    var clubs: [DemoClub]
    var memberships: [ClubMembership]
    var posts: [ClubPost]
    var comments: [ClubComment]
    var ballots: [PollBallot]
    var reactions: [PostReaction]
    var follows: [ClubFollow]
    var rsvps: [EventRSVP]
    var notices: [ClubNotice]
}

@MainActor
final class ClubsStore: ObservableObject {
    @Published private(set) var currentUserID: String
    @Published private(set) var clubs: [DemoClub]
    @Published private(set) var memberships: [ClubMembership]
    @Published private(set) var posts: [ClubPost]
    @Published private(set) var comments: [ClubComment]
    @Published private(set) var ballots: [PollBallot]
    @Published private(set) var reactions: [PostReaction]
    @Published private(set) var follows: [ClubFollow]
    @Published private(set) var rsvps: [EventRSVP]
    @Published private(set) var notices: [ClubNotice]
    let users: [ClubDemoUser]
    let events: [ClubEvent]
    private let defaults: UserDefaults
    private let storageKey = "mogul.community.demo.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let seed = CommunitySeed.make()
        users = seed.users
        events = seed.events
        if let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode(PersistedCommunity.self, from: data) {
            currentUserID = seed.users.contains(where: { $0.id == saved.currentUserID }) ? saved.currentUserID : "user_001"
            clubs = saved.clubs.isEmpty ? seed.clubs : saved.clubs
            memberships = saved.memberships
            posts = saved.posts
            comments = saved.comments
            ballots = saved.ballots
            reactions = saved.reactions
            follows = saved.follows
            rsvps = saved.rsvps
            notices = saved.notices
        } else {
            currentUserID = "user_001"
            clubs = seed.clubs
            memberships = seed.memberships
            posts = seed.posts
            comments = seed.comments
            ballots = []
            reactions = []
            follows = seed.follows
            rsvps = []
            notices = seed.notices
        }
        // User profiles are deterministically regenerated; prune relationships if seed data changes.
        let userIDs = Set(seed.users.map(\.id))
        let clubIDs = Set(clubs.map(\.id))
        memberships.removeAll { !userIDs.contains($0.userID) || !clubIDs.contains($0.clubID) }
        posts.removeAll { !userIDs.contains($0.authorID) || !clubIDs.contains($0.clubID) }
        let postIDs = Set(posts.map(\.id))
        comments.removeAll { !postIDs.contains($0.postID) || !userIDs.contains($0.authorID) }
        ballots.removeAll { !postIDs.contains($0.postID) || !userIDs.contains($0.userID) }
        reactions.removeAll { !postIDs.contains($0.postID) || !userIDs.contains($0.userID) }
        follows.removeAll { !userIDs.contains($0.followerID) || !userIDs.contains($0.followedID) }
        let eventIDs = Set(seed.events.map(\.id))
        rsvps.removeAll { !eventIDs.contains($0.eventID) || !userIDs.contains($0.userID) }
    }

    var currentUser: ClubDemoUser { user(currentUserID) }
    func user(_ id: String) -> ClubDemoUser { users.first(where: { $0.id == id }) ?? users[0] }
    func club(_ id: String) -> DemoClub? { clubs.first(where: { $0.id == id }) }
    func isMember(_ clubID: String, userID: String? = nil) -> Bool { memberships.contains { $0.clubID == clubID && $0.userID == (userID ?? currentUserID) } }
    func role(in clubID: String, userID: String? = nil) -> ClubRole? { memberships.first { $0.clubID == clubID && $0.userID == (userID ?? currentUserID) }?.role }
    func memberCount(_ clubID: String) -> Int { memberships.filter { $0.clubID == clubID }.count }
    func posts(in clubID: String) -> [ClubPost] { posts.filter { $0.clubID == clubID }.sorted { $0.createdAt > $1.createdAt } }
    func comments(for postID: String) -> [ClubComment] { comments.filter { $0.postID == postID }.sorted { $0.createdAt < $1.createdAt } }
    func rootComments(for postID: String) -> [ClubComment] { comments(for: postID).filter { $0.parentID == nil } }
    func joinedClubs(for userID: String? = nil) -> [DemoClub] {
        let ids = Set(memberships.filter { $0.userID == (userID ?? currentUserID) }.map(\.clubID))
        return clubs.filter { ids.contains($0.id) }
    }
    func isFollowing(_ userID: String) -> Bool { follows.contains { $0.followerID == currentUserID && $0.followedID == userID } }
    func followerCount(_ userID: String) -> Int { follows.filter { $0.followedID == userID }.count }
    func followingCount(_ userID: String) -> Int { follows.filter { $0.followerID == userID }.count }
    func rsvpCount(_ event: ClubEvent) -> Int { event.attendeeIDs.count + rsvps.filter { $0.eventID == event.id }.count }
    func hasRSVP(_ eventID: String) -> Bool { rsvps.contains { $0.eventID == eventID && $0.userID == currentUserID } }
    func vote(for postID: String) -> Int? { ballots.first { $0.postID == postID && $0.userID == currentUserID }?.optionIndex }
    func hasLiked(_ postID: String) -> Bool { posts.first(where: { $0.id == postID })?.likedBy.contains(currentUserID) == true }
    func reactionCount(_ post: ClubPost, emoji: String) -> Int { post.reactions.filter { $0.emoji == emoji }.count + reactions.filter { $0.postID == post.id && $0.emoji == emoji }.count }
    func postCount(_ clubID: String) -> Int { posts.filter { $0.clubID == clubID }.count }
    func activityDate(_ clubID: String) -> Date { posts(in: clubID).first?.createdAt ?? .distantPast }

    func switchUser(to id: String) { guard users.contains(where: { $0.id == id }) else { return }; currentUserID = id; save() }
    func join(_ clubID: String) {
        guard club(clubID) != nil, !isMember(clubID) else { return }
        memberships.append(.init(clubID: clubID, userID: currentUserID, role: .member, joinedAt: .now)); save()
    }
    func leave(_ clubID: String) {
        guard role(in: clubID) != .owner else { return }
        memberships.removeAll { $0.clubID == clubID && $0.userID == currentUserID }; save()
    }
    func createClub(name: String, description: String, category: String, coverURL: String, avatarURL: String, visibility: ClubVisibility, rules: [String]) -> String? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.count >= 3, cleanName.count <= 60, cleanDescription.count >= 12, !category.isEmpty else { return nil }
        let base = cleanName.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: "-")
        var slug = base.isEmpty ? UUID().uuidString.lowercased() : base
        if clubs.contains(where: { $0.slug == slug }) { slug += "-\(UUID().uuidString.prefix(5).lowercased())" }
        let id = "club_\(UUID().uuidString.lowercased())"
        clubs.insert(DemoClub(id: id, name: cleanName, slug: slug, description: cleanDescription, category: category, coverURL: coverURL, avatarURL: avatarURL, creatorID: currentUserID, moderatorIDs: [], rules: rules.filter { !$0.isEmpty }, isFeatured: false, visibility: visibility, createdAt: .now, interestTags: [category]), at: 0)
        memberships.append(.init(clubID: id, userID: currentUserID, role: .owner, joinedAt: .now))
        save()
        return id
    }
    func makePost(clubID: String, kind: ClubPostKind, text: String, imageURL: String? = nil, linkURL: String? = nil, options: [String] = []) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isMember(clubID), !clean.isEmpty, clean.count <= 2_000 else { return false }
        if kind == .poll && options.filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count < 2 { return false }
        posts.insert(ClubPost(id: "post_\(UUID().uuidString.lowercased())", clubID: clubID, authorID: currentUserID, kind: kind, content: clean, imageURL: imageURL?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, linkURL: linkURL?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, pollOptions: options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }, createdAt: .now, likedBy: [], reactions: [], isPinned: false), at: 0)
        save(); return true
    }
    func editPost(_ id: String, text: String) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == id && $0.authorID == currentUserID }), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        posts[index].content = text.trimmingCharacters(in: .whitespacesAndNewlines); save(); return true
    }
    func deletePost(_ id: String) {
        guard let post = posts.first(where: { $0.id == id }), post.authorID == currentUserID || canModerate(post.clubID) else { return }
        posts.removeAll { $0.id == id }; comments.removeAll { $0.postID == id }; ballots.removeAll { $0.postID == id }; reactions.removeAll { $0.postID == id }; save()
    }
    func canModerate(_ clubID: String) -> Bool { let role = role(in: clubID); return role == .owner || role == .moderator }
    func removeMember(_ userID: String, from clubID: String) {
        guard canModerate(clubID), role(in: clubID, userID: userID) != .owner else { return }
        memberships.removeAll { $0.clubID == clubID && $0.userID == userID }; save()
    }
    func toggleLike(_ postID: String) {
        guard let index = posts.firstIndex(where: { $0.id == postID }), isMember(posts[index].clubID) else { return }
        let post = posts[index]
        if let i = posts[index].likedBy.firstIndex(of: currentUserID) { posts[index].likedBy.remove(at: i) } else { posts[index].likedBy.append(currentUserID) }
        if !post.likedBy.contains(currentUserID), post.authorID != currentUserID { recordNotice(recipient: post.authorID, actor: currentUserID, clubID: post.clubID, postID: post.id, message: "liked your post") }
        save()
    }
    func toggleReaction(_ postID: String, emoji: String) {
        guard let post = posts.first(where: { $0.id == postID }), isMember(post.clubID) else { return }
        if let i = reactions.firstIndex(where: { $0.postID == postID && $0.userID == currentUserID && $0.emoji == emoji }) { reactions.remove(at: i) }
        else { reactions.append(PostReaction(postID: postID, userID: currentUserID, emoji: emoji)); if post.authorID != currentUserID { recordNotice(recipient: post.authorID, actor: currentUserID, clubID: post.clubID, postID: post.id, message: "reacted \(emoji) to your post") } }
        save()
    }
    func addComment(postID: String, text: String, parentID: String? = nil) -> Bool {
        guard let post = posts.first(where: { $0.id == postID }), isMember(post.clubID) else { return false }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 1_000 else { return false }
        let comment = ClubComment(id: "comment_\(UUID().uuidString.lowercased())", postID: postID, authorID: currentUserID, parentID: parentID, content: clean, createdAt: .now, likedBy: [])
        comments.append(comment)
        let target = parentID.flatMap { parent in comments.first(where: { $0.id == parent })?.authorID } ?? post.authorID
        if target != currentUserID { recordNotice(recipient: target, actor: currentUserID, clubID: post.clubID, postID: post.id, message: parentID == nil ? "commented on your post" : "replied to your comment") }
        save(); return true
    }
    func toggleCommentLike(_ id: String) {
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return }
        guard posts.first(where: { $0.id == comments[index].postID }).map({ isMember($0.clubID) }) == true else { return }
        if let i = comments[index].likedBy.firstIndex(of: currentUserID) { comments[index].likedBy.remove(at: i) } else { comments[index].likedBy.append(currentUserID) }
        save()
    }
    func vote(postID: String, option: Int) {
        guard let post = posts.first(where: { $0.id == postID }), post.kind == .poll, post.pollOptions.indices.contains(option), isMember(post.clubID), vote(for: postID) == nil else { return }
        ballots.append(PollBallot(postID: postID, userID: currentUserID, optionIndex: option)); save()
    }
    func voteCount(postID: String, option: Int) -> Int { ballots.filter { $0.postID == postID && $0.optionIndex == option }.count }
    func toggleFollow(_ userID: String) { guard userID != currentUserID, users.contains(where: { $0.id == userID }) else { return }; if let index = follows.firstIndex(where: { $0.followerID == currentUserID && $0.followedID == userID }) { follows.remove(at: index) } else { follows.append(ClubFollow(followerID: currentUserID, followedID: userID)); recordNotice(recipient: userID, actor: currentUserID, clubID: nil, postID: nil, message: "started following you") }; save() }
    func toggleRSVP(_ eventID: String) { guard let event = events.first(where: { $0.id == eventID }), isMember(event.clubID) else { return }; if let index = rsvps.firstIndex(where: { $0.eventID == eventID && $0.userID == currentUserID }) { rsvps.remove(at: index) } else { rsvps.append(EventRSVP(eventID: eventID, userID: currentUserID)) }; save() }
    func markRead(_ id: String) { guard let index = notices.firstIndex(where: { $0.id == id && $0.recipientID == currentUserID }) else { return }; notices[index].isRead = true; save() }
    func dismissNotice(_ id: String) { notices.removeAll { $0.id == id && ($0.recipientID == currentUserID || $0.recipientID == "all") }; save() }
    func markAllRead() { for index in notices.indices where notices[index].recipientID == currentUserID { notices[index].isRead = true }; save() }
    func reportPost(_ postID: String) { guard let post = posts.first(where: { $0.id == postID }) else { return }; notices.insert(ClubNotice(id: "report_\(UUID().uuidString)", recipientID: "admin", actorID: currentUserID, clubID: post.clubID, postID: postID, message: "A community post was reported for moderator review.", createdAt: .now, isRead: false), at: 0); save() }
    func currentNotices() -> [ClubNotice] { notices.filter { $0.recipientID == currentUserID || $0.recipientID == "all" }.sorted { $0.createdAt > $1.createdAt } }

    private func recordNotice(recipient: String, actor: String, clubID: String?, postID: String?, message: String) {
        guard recipient != currentUserID else { return }
        notices.insert(ClubNotice(id: "notice_\(UUID().uuidString.lowercased())", recipientID: recipient, actorID: actor, clubID: clubID, postID: postID, message: message, createdAt: .now, isRead: false), at: 0)
    }

    private func save() {
        let state = PersistedCommunity(currentUserID: currentUserID, clubs: clubs, memberships: memberships, posts: posts, comments: comments, ballots: ballots, reactions: reactions, follows: follows, rsvps: rsvps, notices: notices)
        persist(state, to: defaults)
    }
    private func persist(_ state: PersistedCommunity, to defaults: UserDefaults) { if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: storageKey) } }
}

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
extension String { var initials: String { split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased() } }

private struct CommunitySeed {
    var users: [ClubDemoUser]
    var clubs: [DemoClub]
    var memberships: [ClubMembership]
    var posts: [ClubPost]
    var comments: [ClubComment]
    var follows: [ClubFollow]
    var notices: [ClubNotice]
    var events: [ClubEvent]

    static func make() -> CommunitySeed {
        let categories = ["Luxury Homes", "House Hacking", "Market Talk", "Multifamily", "Short-Term Rentals", "First-Time Investors", "Renovation", "Wholesaling", "Property Management", "Financial Freedom", "Commercial", "Design & Architecture"]
        let firstNames = ["Jordan", "Avery", "Morgan", "Riley", "Taylor", "Cameron", "Quinn", "Reese", "Parker", "Rowan", "Dakota", "Skyler", "Casey", "Jamie", "Emerson", "Finley", "Hayden", "Kendall", "Logan", "Micah", "Nico", "Oakley", "Payton", "River", "Sage", "Tatum", "Val", "Wren", "Alex", "Blair", "Chris", "Drew", "Elliot", "Frankie", "Gray", "Harper", "Indigo", "Jules", "Kai", "Lane", "Marley", "Noel", "Onyx", "Phoenix", "Remy", "Shiloh", "Teagan", "Uma", "Winter", "Yael", "Zion", "Arden", "Briar", "Cleo", "Devon", "Ellis", "Flynn", "Greer", "Hollis", "Ira", "Jess", "Kit", "Lennon", "Milan", "Nori", "Ollie", "Robin", "Sam", "Terry", "Umair", "Vesper", "West", "Zuri"]
        let surnames = ["Reed", "Brooks", "Hayes", "Bennett", "Cole", "Foster", "Price", "Wells", "Porter", "Lane", "Diaz", "Morgan", "Bell", "Perry", "Ross", "Stone", "Young", "Shah", "Cruz", "Gray"]
        let bios = ["Building a thoughtful real estate portfolio, one good question at a time.", "Curious investor, neighborhood watcher, and spreadsheet enthusiast.", "Sharing lessons from my latest renovation and rental projects.", "Here to learn from generous people and make better property decisions.", "Real estate learner focused on long-term, community-minded ownership.", "I enjoy comparing markets, design ideas, and practical operator tips."]
        let users = (0..<72).map { index -> ClubDemoUser in
            let display = "\(firstNames[index]) \(surnames[index % surnames.count])"
            return ClubDemoUser(id: String(format: "user_%03d", index + 1), username: "\(firstNames[index].lowercased())\(surnames[index % surnames.count].lowercased())\(index + 1)", displayName: display, avatarURL: "https://i.pravatar.cc/160?img=\(index + 1)", bio: bios[index % bios.count], interests: [categories[index % categories.count], categories[(index + 3) % categories.count]])
        }
        let definitions: [(String, String, String, String)] = [
            ("Billionaires Club", "Ambitious conversations about building durable wealth through real estate and disciplined ownership.", "Financial Freedom", "photo-1486406146926-c627a92ad1ab"),
            ("Millionaire Row", "A practical corner for investors mapping their next milestone and sharing what worked.", "Financial Freedom", "photo-1464822759023-fed622ff2c3b"),
            ("The Penthouse", "Explore exceptional homes, thoughtful design, and the details that make a property memorable.", "Luxury Homes", "photo-1600210492486-724fe5c67fb0"),
            ("The Mansion Mafia", "Big homes, bigger renovation ideas, and candid conversations about operating at scale.", "Luxury Homes", "photo-1600607687939-ce8a6c25118c"),
            ("The House of Hustle", "Swap real-world lessons on sourcing, underwriting, and sticking with the work.", "House Hacking", "photo-1600596542815-ffad4c1539a9"),
            ("The Brick & Boujee Club", "Where historic character meets modern ownership and ambitious design.", "Renovation", "photo-1600566753086-00f18fb6b3ea"),
            ("The Gated Community", "A friendly members club for conversations about neighborhoods, homes, and local markets.", "Market Talk", "photo-1600047509807-ba8f99d2cdde"),
            ("The Golden Keys", "Celebrate smart acquisitions and share the small steps that help a deal come together.", "First-Time Investors", "photo-1600585154340-be6161a56a0c"),
            ("The Luxury League", "Compare standout residences, hospitality, and the guest experiences behind premium stays.", "Luxury Homes", "photo-1600607687920-4e2a09cf159d"),
            ("The Mortgage Mafia", "Discuss financing basics, lender questions, and capital strategy in plain language.", "Market Talk", "photo-1600566753190-17f0baa2a6c3"),
            ("The Zillow Addicts", "Browse the listings, spot the potential, and bring your most interesting finds to the group.", "Market Talk", "photo-1600585154526-990dced4db0d"),
            ("The HOA Haters", "Talk through association rules, due diligence, and how to evaluate community restrictions.", "Property Management", "photo-1600607687644-c7171b42498f"),
            ("The House Party", "A lively place for open houses, neighborhood discoveries, and helpful introductions.", "First-Time Investors", "photo-1600566752355-35792bedcfea"),
            ("The Keys to the Kingdom", "Long-term thinkers comparing rental operations and responsible portfolio growth.", "Multifamily", "photo-1600607687939-ce8a6c25118c"),
            ("The Almost Rich Club", "A no-judgment community for early-stage investors learning the fundamentals together.", "First-Time Investors", "photo-1600596542815-ffad4c1539a9"),
            ("The Basement Billionaires", "Creative house hackers making the most of every square foot and first property.", "House Hacking", "photo-1600047509782-20d39509f26d"),
            ("The Cash Flow Clowns", "Make the numbers less intimidating with friendly rent math and operator stories.", "Financial Freedom", "photo-1600566753190-17f0baa2a6c3"),
            ("The No HOA Zone", "Share independent ownership tips and learn how to research local property rules.", "Property Management", "photo-1600585154340-be6161a56a0c"),
            ("The Plot Twisters", "Find overlooked potential in unusual lots, zoning conversations, and redevelopment ideas.", "Commercial", "photo-1600566753086-00f18fb6b3ea"),
            ("The Rent-Free Thinkers", "Challenge conventional wisdom and talk about housing, affordability, and ownership.", "Market Talk", "photo-1600210492486-724fe5c67fb0"),
            ("The Weekend Renovators", "Share before-and-afters, contractor lessons, and realistic renovation plans.", "Renovation", "photo-1600607687920-4e2a09cf159d"),
            ("STR Operators Circle", "Practical conversations about guest-ready homes and short-term rental operations.", "Short-Term Rentals", "photo-1600607687644-c7171b42498f"),
            ("Multifamily Field Notes", "Compare apartment operations, resident experience, and community-scale housing.", "Multifamily", "photo-1600566752355-35792bedcfea"),
            ("The Small Deal Society", "Build confidence with approachable conversations about modest, local acquisitions.", "Wholesaling", "photo-1600585154526-990dced4db0d")
        ]
        let clubs = definitions.enumerated().map { index, item in
            let creator = users[index % users.count].id
            return DemoClub(id: String(format: "club_%03d", index + 1), name: item.0, slug: item.0.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: "-"), description: item.1, category: item.2, coverURL: "https://images.unsplash.com/\(item.3)?auto=format&fit=crop&w=900&q=82", avatarURL: "https://i.pravatar.cc/160?img=\((index * 3) % 70 + 1)", creatorID: creator, moderatorIDs: [users[(index * 3 + 1) % users.count].id], rules: ["Be respectful and constructive.", "Share context and credit original creators.", "Keep advice educational; do your own due diligence."], isFeatured: index < 6, visibility: index % 7 == 5 ? .private : .public, createdAt: Calendar.current.date(byAdding: .day, value: -(index * 9 + 14), to: .now) ?? .now, interestTags: [item.2, categories[(index + 2) % categories.count]])
        }
        var memberships: [ClubMembership] = []
        for (clubIndex, club) in clubs.enumerated() {
            let count = 12 + clubIndex % 13
            for offset in 0..<count {
                let userIndex = offset == 0 ? clubIndex % users.count : (clubIndex * 3 + offset) % users.count
                let role: ClubRole = offset == 0 ? .owner : (offset == 1 ? .moderator : .member)
                memberships.append(ClubMembership(clubID: club.id, userID: users[userIndex].id, role: role, joinedAt: Calendar.current.date(byAdding: .day, value: -(offset * 5 + clubIndex), to: .now) ?? .now))
            }
        }
        for clubID in [clubs[0].id, clubs[4].id] where !memberships.contains(where: { $0.clubID == clubID && $0.userID == "user_001" }) { memberships.append(.init(clubID: clubID, userID: "user_001", role: .member, joinedAt: .now)) }
        memberships.removeAll { $0.userID == "user_072" }
        var posts: [ClubPost] = []
        var comments: [ClubComment] = []
        let contentSeeds = ["A small detail I check on every tour now: where does the afternoon sun land? It changes how a room feels.", "I put together a quick checklist from this week's research. What would you add before making an offer?", "Curious how everyone is thinking about maintenance reserves this year. Any systems that have helped?", "Sharing a lesson from a project that took longer than expected: build contingency into the schedule, not just the budget.", "Which neighborhood signal do you trust most when you are learning a new market?", "A reminder that the best deal is the one you understand. What question are you bringing to your next walk-through?"]
        let commentSeeds = ["Great point. I started asking that on every walkthrough.", "Thanks for sharing the context, this is useful.", "I had a similar experience last year and learned to budget extra time.", "Would love to hear a little more about how you approached it.", "Adding this to my research checklist. Appreciate it!", "Good question for the group. I am comparing notes too."]
        for (clubIndex, club) in clubs.enumerated() {
            let memberIDs = memberships.filter { $0.clubID == club.id }.map(\.userID)
            for postIndex in 0..<6 {
                let kind = ClubPostKind.allCases[(clubIndex + postIndex) % ClubPostKind.allCases.count]
                let postID = String(format: "post_%03d_%02d", clubIndex + 1, postIndex + 1)
                let author = memberIDs[(postIndex + 1) % memberIDs.count]
                let content = "\(contentSeeds[(clubIndex + postIndex) % contentSeeds.count]) \(postIndex == 0 ? "\(club.name) check-in:" : "")"
                let options = kind == .poll ? ["Location first", "Numbers first", "Condition first"] : []
                let photoIndex = (clubIndex + postIndex) % clubs.count
                posts.append(ClubPost(id: postID, clubID: club.id, authorID: author, kind: kind, content: content, imageURL: kind == .image ? clubs[photoIndex].coverURL : nil, linkURL: kind == .link ? "https://www.example.com/\(club.slug)" : nil, pollOptions: options, createdAt: Calendar.current.date(byAdding: .hour, value: -(clubIndex * 21 + postIndex * 9 + 1), to: .now) ?? .now, likedBy: Array(memberIDs.prefix((postIndex * 3 + 2) % min(memberIDs.count, 9))), reactions: [], isPinned: kind == .announcement && postIndex == 0))
                for commentIndex in 0..<(2 + (clubIndex + postIndex) % 3) {
                    let commenter = memberIDs[(postIndex + commentIndex + 3) % memberIDs.count]
                    let commentID = "comment_\(clubIndex)_\(postIndex)_\(commentIndex)"
                    comments.append(ClubComment(id: commentID, postID: postID, authorID: commenter, parentID: nil, content: "\(commentSeeds[(clubIndex + postIndex + commentIndex) % commentSeeds.count])", createdAt: Calendar.current.date(byAdding: .minute, value: -(commentIndex * 17), to: .now) ?? .now, likedBy: commentIndex == 0 ? [author] : []))
                    if commentIndex == 0 { comments.append(ClubComment(id: "reply_\(clubIndex)_\(postIndex)", postID: postID, authorID: author, parentID: commentID, content: "\(users.first(where: { $0.id == author })?.displayName ?? "Member"): I will share more details in the next update.", createdAt: .now, likedBy: [])) }
                }
            }
        }
        let follows = (0..<80).compactMap { i -> ClubFollow? in let follower = users[i % users.count].id; let followed = users[(i * 7 + 5) % users.count].id; return follower == followed ? nil : ClubFollow(followerID: follower, followedID: followed) }
        let notices = (0..<18).map { index in ClubNotice(id: "notice_\(index + 1)", recipientID: "user_001", actorID: users[(index + 7) % users.count].id, clubID: clubs[index % clubs.count].id, postID: posts[index].id, message: ["commented on a discussion you follow", "shared a new post in your club", "invited you to compare notes", "posted an upcoming community event"][index % 4], createdAt: Calendar.current.date(byAdding: .hour, value: -index * 4, to: .now) ?? .now, isRead: index > 5) }
        let events = clubs.enumerated().flatMap { index, club in
            (0..<2).map { n in
                ClubEvent(id: "event_\(index + 1)_\(n + 1)", clubID: club.id, title: ["Neighborhood walk & coffee", "Monthly deal-room discussion"][n], description: ["Meet local members, compare notes, and share what you are seeing around the neighborhood.", "An open, educational conversation about underwriting assumptions and lessons learned."][n], imageURL: club.coverURL, date: Calendar.current.date(byAdding: .day, value: n == 0 ? (index % 8) + 2 : -((index % 8) + 2), to: .now) ?? .now, location: n == 0 ? "Online community room" : "Community meetup · details in club", hostID: club.creatorID, attendeeIDs: Array(memberships.filter { $0.clubID == club.id }.prefix(3).map(\.userID)), isOnline: n == 0)
            }
        }
        return CommunitySeed(users: users, clubs: clubs, memberships: memberships, posts: posts, comments: comments, follows: follows, notices: notices, events: events)
    }
}
