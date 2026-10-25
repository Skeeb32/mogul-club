import SwiftUI

enum ClubBrowseSort: String, CaseIterable, Identifiable {
    case trending = "Trending", popular = "Most Popular", newest = "Newest", active = "Most Active"
    var id: String { rawValue }
}

struct ClubsView: View {
    @ObservedObject var store: ClubsStore
    let onAccount: () -> Void
    @State private var query = ""
    @State private var category = "All"
    @State private var sort: ClubBrowseSort = .trending
    @State private var visibility = "Any visibility"
    @State private var joinedOnly = false
    @State private var showCreate = false
    @State private var showNotifications = false
    @State private var showDemoUsers = false
    @State private var selectedClubID: String?

    private var categories: [String] { ["All"] + Array(Set(store.clubs.map(\.category))).sorted() }
    private var filteredClubs: [DemoClub] {
        var result = store.clubs.filter { club in
            let matchesCategory = category == "All" || club.category == category
            let matchesJoined = !joinedOnly || store.isMember(club.id)
            let matchesVisibility = visibility == "Any visibility" || club.visibility.rawValue.localizedCaseInsensitiveCompare(visibility) == .orderedSame
            let terms = (club.name + " " + club.description + " " + club.category + " " + club.interestTags.joined(separator: " ")).localizedLowercase
            return matchesCategory && matchesJoined && matchesVisibility && (query.isEmpty || terms.localizedStandardContains(query.localizedLowercase))
        }
        switch sort {
        case .trending: result.sort { store.postCount($0.id) + store.memberCount($0.id) / 4 > store.postCount($1.id) + store.memberCount($1.id) / 4 }
        case .popular: result.sort { store.memberCount($0.id) > store.memberCount($1.id) }
        case .newest: result.sort { $0.createdAt > $1.createdAt }
        case .active: result.sort { store.activityDate($0.id) > store.activityDate($1.id) }
        }
        return result
    }
    private var recommended: [DemoClub] {
        store.clubs.filter { club in
            !store.isMember(club.id) && !club.interestTags.filter { store.currentUser.interests.contains($0) }.isEmpty
        }.prefix(6).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DemoNotice()
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Clubs").font(.largeTitle.weight(.bold))
                            Text("Find your people. Share what you’re learning.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Button { showCreate = true } label: { Label("Create", systemImage: "plus").font(.subheadline.weight(.semibold)).padding(.horizontal, 13).padding(.vertical, 10).background(ClubStyle.emerald, in: Capsule()).foregroundStyle(.white) }
                            .accessibilityIdentifier("create-club")
                    }
                    demoAccountPicker
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search clubs, topics, interests", text: $query).accessibilityIdentifier("club-search")
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.accessibilityLabel("Clear search") }
                    }
                    .padding(13).background(.background, in: RoundedRectangle(cornerRadius: 14))
                    categoryPicker
                    if !store.joinedClubs().isEmpty {
                        sectionHeading("Your clubs", subtitle: "Your communities and conversations")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(store.joinedClubs()) { club in
                                    Button { selectedClubID = club.id } label: { JoinedClubTile(club: club, count: store.memberCount(club.id)) }.buttonStyle(.plain)
                                }
                            }.padding(.horizontal, 1)
                        }
                    }
                    if !query.isEmpty || joinedOnly || category != "All" {
                        HStack { sectionHeading(joinedOnly ? "Joined clubs" : "Club results", subtitle: "\(filteredClubs.count) communities"); Spacer(); visibilityMenu; sortMenu }
                        resultGrid
                    } else {
                        if !recommended.isEmpty {
                            sectionHeading("Picked for you", subtitle: "Based on your interests")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 14) {
                                    ForEach(recommended) { club in Button { selectedClubID = club.id } label: { FeaturedClubCard(club: club, store: store) }.buttonStyle(.plain) }
                                }.padding(.horizontal, 1)
                            }
                        }
                        HStack { sectionHeading("Featured clubs", subtitle: "Communities making moves"); Spacer(); sortMenu }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 14) {
                                ForEach(store.clubs.filter(\.isFeatured)) { club in Button { selectedClubID = club.id } label: { FeaturedClubCard(club: club, store: store) }.buttonStyle(.plain) }
                            }.padding(.horizontal, 1)
                        }
                        HStack { sectionHeading("Explore all clubs", subtitle: "\(filteredClubs.count) fictional communities"); Spacer(); visibilityMenu; sortMenu; Button(joinedOnly ? "Show all" : "Joined") { joinedOnly.toggle() }.font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald) }
                        resultGrid
                    }
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 30)
                .frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { MogulLogo(width: 124) }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        Image(systemName: store.currentNotices().contains(where: { !$0.isRead }) ? "bell.badge" : "bell")
                    }.accessibilityLabel("Notifications")
                    Button(action: onAccount) { Image(systemName: "person.crop.circle").font(.title3) }.accessibilityLabel("Account")
                }
            }
            .navigationDestination(item: $selectedClubID) { id in
                if let club = store.club(id) { ClubDetailView(club: club, store: store) }
            }
            .sheet(isPresented: $showCreate) {
                CreateClubSheet(store: store) { id in showCreate = false; selectedClubID = id }
            }
            .sheet(isPresented: $showNotifications) { NotificationsSheet(store: store) }
            .sheet(isPresented: $showDemoUsers) { DemoUserPickerSheet(store: store) }
            .onReceive(NotificationCenter.default.publisher(for: .openDemoClub)) { note in
                if let clubID = note.object as? String, store.club(clubID) != nil { selectedClubID = clubID }
            }
        }
    }

    private var demoAccountPicker: some View {
        HStack(spacing: 10) {
            CommunityAvatar(user: store.currentUser, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("Browsing as \(store.currentUser.displayName)").font(.subheadline.weight(.semibold))
                Text("Fictional demo profile · switch account").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Switch") { showDemoUsers = true }.font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald).accessibilityIdentifier("switch-demo-user")
        }.padding(11).background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { item in
                    Button { category = item } label: {
                        Text(item).font(.caption.weight(.semibold)).padding(.horizontal, 13).padding(.vertical, 9)
                            .background(category == item ? ClubStyle.emerald : Color(.secondarySystemBackground), in: Capsule())
                            .foregroundStyle(category == item ? .white : .primary)
                    }.buttonStyle(.plain)
                }
            }
        }.accessibilityIdentifier("club-categories")
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ClubBrowseSort.allCases) { option in Button(option.rawValue) { sort = option } }
        } label: { Label(sort.rawValue, systemImage: "arrow.up.arrow.down").font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald) }
            .accessibilityLabel("Sort clubs")
    }

    private var visibilityMenu: some View {
        Menu {
            ForEach(["Any visibility", "Public", "Private"], id: \.self) { value in Button(value) { visibility = value } }
        } label: { Image(systemName: "line.3.horizontal.decrease.circle").font(.headline).foregroundStyle(ClubStyle.emerald) }
            .accessibilityLabel("Filter visibility")
    }

    private var resultGrid: some View {
        Group {
            if filteredClubs.isEmpty {
                ContentUnavailableView("No clubs found", systemImage: "person.3", description: Text("Try another search or choose a different category."))
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 285), spacing: 14)], alignment: .leading, spacing: 14) {
                    ForEach(filteredClubs) { club in ClubDiscoveryCard(club: club, store: store) { selectedClubID = club.id } }
                }
            }
        }
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.weight(.bold))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct ClubDiscoveryCard: View {
    let club: DemoClub
    @ObservedObject var store: ClubsStore
    let open: () -> Void
    var body: some View {
        let isOwner = store.role(in: club.id) == .owner
        VStack(alignment: .leading, spacing: 0) {
            ClubCover(url: club.coverURL, height: 150)
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 5) {
                        if club.isFeatured { Label("FEATURED", systemImage: "sparkle").font(.system(size: 9, weight: .bold)).padding(7).background(.ultraThinMaterial, in: Capsule()) }
                        if club.visibility == .private { Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold)).padding(7).background(.ultraThinMaterial, in: Circle()) }
                    }.padding(10)
                }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    ClubIdentityAvatar(url: club.avatarURL, initials: club.name.initials, size: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(club.name).font(.headline.weight(.bold)).lineLimit(1).foregroundStyle(.primary)
                        Text(club.category).font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                    }
                    Spacer(minLength: 0)
                }
                Text(club.description).font(.caption).foregroundStyle(.secondary).lineLimit(2).frame(minHeight: 34, alignment: .topLeading)
                HStack(spacing: 12) {
                    Label("\(store.memberCount(club.id))", systemImage: "person.2")
                    Label("\(store.postCount(club.id)) posts", systemImage: "text.bubble")
                    Spacer(minLength: 0)
                    MemberAvatarStack(members: members, size: 24)
                }.font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 9) {
                    Button { store.isMember(club.id) ? store.leave(club.id) : store.join(club.id) } label: {
                        Text(isOwner ? "Owner" : (store.isMember(club.id) ? "Joined" : "Join club")).font(.caption.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(store.isMember(club.id) ? Color(.secondarySystemBackground) : ClubStyle.emerald, in: Capsule())
                            .foregroundStyle(store.isMember(club.id) ? Color.primary : Color.white)
                    }.buttonStyle(.plain).disabled(isOwner).accessibilityIdentifier("join-\(club.id)")
                    Button(action: open) { Text("View club").font(.caption.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 10).overlay(Capsule().stroke(ClubStyle.emerald.opacity(0.45))) }
                        .buttonStyle(.plain).foregroundStyle(ClubStyle.emerald).accessibilityIdentifier("view-\(club.id)")
                }
            }.padding(13)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.black.opacity(0.05)))
    }
    private var members: [ClubDemoUser] { store.memberships.filter { $0.clubID == club.id }.prefix(4).map { store.user($0.userID) } }
}

struct FeaturedClubCard: View {
    let club: DemoClub
    @ObservedObject var store: ClubsStore
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ClubCover(url: club.coverURL, height: 124).overlay(alignment: .bottomLeading) {
                ClubIdentityAvatar(url: club.avatarURL, initials: club.name.initials, size: 40).padding(10)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(club.name).font(.subheadline.weight(.bold)).lineLimit(1)
                Text("\(store.memberCount(club.id)) members · \(club.category)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }.padding(.horizontal, 10).padding(.bottom, 10)
        }.frame(width: 236).background(.background, in: RoundedRectangle(cornerRadius: 15)).clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct JoinedClubTile: View {
    let club: DemoClub
    let count: Int
    var body: some View {
        HStack(spacing: 9) {
            ClubIdentityAvatar(url: club.avatarURL, initials: club.name.initials, size: 38)
            VStack(alignment: .leading, spacing: 3) { Text(club.name).font(.caption.weight(.bold)).lineLimit(1); Text("\(count) members").font(.caption2).foregroundStyle(.secondary) }
        }.padding(10).frame(width: 190, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 13))
    }
}

struct ClubCover: View {
    let url: String
    var height: CGFloat = 170
    var body: some View {
        AsyncImage(url: URL(string: url), transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .empty, .failure: ZStack { LinearGradient(colors: [ClubStyle.emerald.opacity(0.45), Color(red: 0.84, green: 0.80, blue: 0.68)], startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: "building.2.crop.circle.fill").font(.system(size: 42)).foregroundStyle(.white.opacity(0.8)) }
            @unknown default: Color.gray.opacity(0.2)
            }
        }.frame(maxWidth: .infinity).frame(height: height).clipped()
            .accessibilityLabel("Club cover image")
    }
}

struct ClubIdentityAvatar: View {
    let url: String
    let initials: String
    var size: CGFloat = 42
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if case .success(let image) = phase { image.resizable().scaledToFill() }
            else { Text(initials).font(.system(size: size * 0.32, weight: .bold)).foregroundStyle(ClubStyle.emerald).frame(width: size, height: size).background(ClubStyle.emerald.opacity(0.12)) }
        }.frame(width: size, height: size).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
    }
}

struct CommunityAvatar: View {
    let user: ClubDemoUser
    var size: CGFloat = 38
    var body: some View { ClubIdentityAvatar(url: user.avatarURL, initials: user.displayName.initials, size: size).accessibilityLabel(user.displayName) }
}

struct MemberAvatarStack: View {
    let members: [ClubDemoUser]
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: -8) { ForEach(members) { CommunityAvatar(user: $0, size: size) } }
    }
}
