import SwiftUI

enum ClubPageTab: String, CaseIterable, Identifiable {
    case feed = "Feed", members = "Members", about = "About", events = "Events", media = "Media"
    var id: String { rawValue }
}

struct ClubDetailView: View {
    let club: DemoClub
    @ObservedObject var store: ClubsStore
    @State private var tab: ClubPageTab = .feed
    @State private var showComposer = false
    @State private var showMedia: ClubPost?
    @State private var toast: String?

    private var clubPosts: [ClubPost] { store.posts(in: club.id) }
    private var memberRows: [ClubMembership] { store.memberships.filter { $0.clubID == club.id }.sorted { roleOrder($0.role) < roleOrder($1.role) } }
    private var upcomingEvents: [ClubEvent] { store.events.filter { $0.clubID == club.id && $0.date >= .now }.sorted { $0.date < $1.date } }
    private var mediaPosts: [ClubPost] { clubPosts.filter { $0.imageURL != nil } }
    private var locked: Bool { club.visibility == .private && !store.isMember(club.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                DemoNotice().padding(.horizontal, 17).padding(.top, 8)
                heroSection
                actionSection
                metadataSection
                pageTabPicker.padding(.horizontal, 17)
                if locked {
                    ContentUnavailableView("Private community", systemImage: "lock.fill", description: Text("Join this club to see its member-only conversations, people, and events."))
                        .padding(.top, 16)
                } else {
                    tabContent.padding(.horizontal, 17)
                }
            }.padding(.bottom, 30).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { MogulLogo(width: 112) } }
        .sheet(isPresented: $showComposer) { CreatePostSheet(club: club, store: store) }
        .sheet(item: $showMedia) { post in MediaViewerSheet(post: post, store: store) }
        .alert("Club update", isPresented: Binding(get: { toast != nil }, set: { if !$0 { toast = nil } })) { Button("OK") { toast = nil } } message: { Text(toast ?? "") }
    }

    private var heroSection: some View {
        ClubCover(url: club.coverURL, height: 218)
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 12) {
                    ClubIdentityAvatar(url: club.avatarURL, initials: club.name.initials, size: 64)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(club.name).font(.title3.weight(.bold)).foregroundStyle(.white)
                        Text("\(store.memberCount(club.id)) members · \(store.postCount(club.id)) posts")
                            .font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .top, endPoint: .bottom))
            }
    }

    private var actionSection: some View {
        let owner = store.role(in: club.id) == .owner
        let joined = store.isMember(club.id)
        return HStack(spacing: 9) {
            Button { joined ? store.leave(club.id) : store.join(club.id) } label: {
                Label(owner ? "Owner" : (joined ? "Joined" : (club.visibility == .private ? "Join private club" : "Join club")),
                      systemImage: owner ? "crown.fill" : (joined ? "checkmark" : "plus"))
                    .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(joined ? Color(.secondarySystemBackground) : ClubStyle.emerald, in: Capsule())
                    .foregroundStyle(joined ? Color.primary : Color.white)
            }
            .buttonStyle(.plain).disabled(owner).accessibilityIdentifier("detail-join-\(club.id)")
            ShareLink(item: URL(string: "https://mogul.club/clubs/\(club.slug)")!) {
                Image(systemName: "square.and.arrow.up").font(.headline).frame(width: 44, height: 44).background(.background, in: Circle())
            }.accessibilityLabel("Share club")
            Menu {
                Button("All activity", systemImage: "bell.badge") { toast = "You’ll see all club activity in this demo." }
                Button("Highlights", systemImage: "bell") { toast = "Highlights preference saved for this session." }
                Button("Mute notifications", systemImage: "bell.slash") { toast = "Club notifications muted for this session." }
            } label: {
                Image(systemName: "bell.badge").font(.headline).frame(width: 44, height: 44).background(.background, in: Circle())
            }.accessibilityLabel("Notification preferences")
        }.padding(.horizontal, 17)
    }

    private var metadataSection: some View {
        HStack(spacing: 8) {
            Text(club.category).font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                .padding(.horizontal, 10).padding(.vertical, 6).background(ClubStyle.emerald.opacity(0.1), in: Capsule())
            if club.visibility == .private { Label("Private", systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary) }
            MemberAvatarStack(members: memberRows.prefix(5).map { store.user($0.userID) }, size: 26)
            Spacer()
            Text("by \(store.user(club.creatorID).displayName)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }.padding(.horizontal, 17)
    }

    private var pageTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ClubPageTab.allCases) { item in
                    Button { withAnimation(.easeInOut(duration: 0.15)) { tab = item } } label: {
                        Text(item.rawValue).font(.subheadline.weight(tab == item ? .bold : .medium)).padding(.horizontal, 14).padding(.vertical, 9)
                            .foregroundStyle(tab == item ? .white : .secondary).background(tab == item ? ClubStyle.emerald : Color(.secondarySystemBackground), in: Capsule())
                    }.buttonStyle(.plain).accessibilityIdentifier("club-tab-\(item.id.lowercased())")
                }
            }
        }
    }

    @ViewBuilder private var tabContent: some View {
        switch tab {
        case .feed: feedContent
        case .members: membersContent
        case .about: aboutContent
        case .events: eventsContent
        case .media: mediaContent
        }
    }

    private var feedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.isMember(club.id) {
                Button { showComposer = true } label: {
                    HStack(spacing: 10) { CommunityAvatar(user: store.currentUser, size: 40); Text("Share something with the club…").font(.subheadline).foregroundStyle(.secondary); Spacer(); Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(ClubStyle.emerald) }
                        .padding(13).background(.background, in: RoundedRectangle(cornerRadius: 15))
                }.buttonStyle(.plain).accessibilityIdentifier("create-post")
            } else {
                Text("Join this club to post, react, and join the conversation.").font(.caption).foregroundStyle(.secondary).padding(14).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 14))
            }
            ForEach(clubPosts) { post in CommunityPostCard(post: post, store: store) }
        }
    }

    private var membersContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(memberRows.count) members").font(.headline)
            ForEach(memberRows) { membership in
                let member = store.user(membership.userID)
                HStack(spacing: 11) {
                    NavigationLink { UserProfileView(user: member, store: store) } label: {
                        HStack(spacing: 10) { CommunityAvatar(user: member, size: 42); VStack(alignment: .leading, spacing: 2) { Text(member.displayName).font(.subheadline.weight(.semibold)); Text("@\(member.username)").font(.caption).foregroundStyle(.secondary) } }
                    }.buttonStyle(.plain)
                    Spacer()
                    Text(membership.role.rawValue.capitalized).font(.caption.weight(.medium)).foregroundStyle(membership.role == .owner ? ClubStyle.emerald : .secondary)
                    if store.canModerate(club.id), membership.userID != store.currentUserID, membership.role != .owner {
                        Menu { Button("Remove from club", systemImage: "person.crop.circle.badge.minus", role: .destructive) { store.removeMember(membership.userID, from: club.id) } } label: { Image(systemName: "ellipsis").padding(8) }
                    }
                }.padding(10).background(.background, in: RoundedRectangle(cornerRadius: 13))
            }
        }
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 8) { Text("About this club").font(.headline); Text(club.description).font(.subheadline).foregroundStyle(.secondary); Label("\(club.visibility.rawValue.capitalized) club · \(club.category)", systemImage: club.visibility == .private ? "lock" : "globe.americas").font(.caption).foregroundStyle(ClubStyle.emerald) }
                .padding(15).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 9) { Text("Club leaders").font(.headline); memberRoleRow(userID: club.creatorID, role: "Owner"); ForEach(club.moderatorIDs, id: \.self) { memberRoleRow(userID: $0, role: "Moderator") } }
                .padding(15).background(.background, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 9) { Text("Community guidelines").font(.headline); ForEach(Array(club.rules.enumerated()), id: \.offset) { index, rule in Label(rule, systemImage: "\(index + 1).circle").font(.subheadline).foregroundStyle(.secondary) } }
                .padding(15).background(.background, in: RoundedRectangle(cornerRadius: 15))
            Text("Created \(club.createdAt.formatted(date: .abbreviated, time: .omitted)) · fictional demonstration community").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var eventsContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Club events").font(.headline)
            if upcomingEvents.isEmpty { ContentUnavailableView("No upcoming events", systemImage: "calendar", description: Text("Check back for the next community meetup.")) }
            ForEach(upcomingEvents) { event in ClubEventCard(event: event, store: store) }
            let past = store.events.filter { $0.clubID == club.id && $0.date < .now }
            if !past.isEmpty {
                Text("Past events").font(.headline).padding(.top, 6)
                ForEach(past) { event in ClubEventCard(event: event, store: store, isPast: true) }
            }
        }
    }

    private var mediaContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Shared photos").font(.headline)
            if mediaPosts.isEmpty { ContentUnavailableView("No shared media yet", systemImage: "photo.on.rectangle.angled", description: Text("Photos shared in club posts will appear here.")) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(mediaPosts) { post in
                    Button { showMedia = post } label: {
                        ClubCover(url: post.imageURL ?? club.coverURL, height: 150).overlay(alignment: .bottomLeading) {
                            Text(store.user(post.authorID).displayName).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(1).padding(9).frame(maxWidth: .infinity, alignment: .leading).background(.black.opacity(0.45))
                        }
                    }.buttonStyle(.plain).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func memberRoleRow(userID: String, role: String) -> some View {
        let person = store.user(userID)
        return NavigationLink { UserProfileView(user: person, store: store) } label: {
            HStack(spacing: 9) { CommunityAvatar(user: person, size: 34); Text(person.displayName).font(.subheadline); Spacer(); Text(role).font(.caption).foregroundStyle(.secondary); Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary) }
        }.buttonStyle(.plain)
    }
    private func roleOrder(_ role: ClubRole) -> Int { switch role { case .owner: 0; case .moderator: 1; case .member: 2 } }
}
