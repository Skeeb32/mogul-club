import XCTest
@testable import Mogul_Club

final class ClubsStoreTests: XCTestCase {
    @MainActor
    func testSeedContainsConnectedCommunityAndNewMemberPersona() {
        let (store, _) = makeStore()
        XCTAssertGreaterThanOrEqual(store.clubs.count, 20)
        XCTAssertGreaterThanOrEqual(store.users.count, 50)
        XCTAssertGreaterThanOrEqual(store.posts.count, store.clubs.count * 5)
        XCTAssertGreaterThan(store.comments.count, store.posts.count * 2)
        XCTAssertEqual(store.joinedClubs(for: "user_072").count, 0)
        XCTAssertTrue(store.posts.allSatisfy { post in
            store.club(post.clubID) != nil && store.users.contains(where: { $0.id == post.authorID })
        })
        XCTAssertTrue(store.comments.allSatisfy { comment in store.posts.contains(where: { $0.id == comment.postID }) && store.users.contains(where: { $0.id == comment.authorID }) })
    }

    @MainActor
    func testMembershipPostsCommentsPollsFollowsEventsAndPersistence() {
        let (store, defaults) = makeStore()
        let joinTarget = tryUnjoinedClub(store)
        let originalCount = store.memberCount(joinTarget.id)
        store.join(joinTarget.id)
        XCTAssertTrue(store.isMember(joinTarget.id))
        XCTAssertEqual(store.memberCount(joinTarget.id), originalCount + 1)
        XCTAssertTrue(store.makePost(clubID: joinTarget.id, kind: .text, text: "A new thought for this community."))
        let newPost = try! XCTUnwrap(store.posts(in: joinTarget.id).first)
        XCTAssertFalse(store.hasLiked(newPost.id))
        store.toggleLike(newPost.id)
        XCTAssertTrue(store.hasLiked(newPost.id))
        store.toggleLike(newPost.id)
        XCTAssertFalse(store.hasLiked(newPost.id))
        XCTAssertTrue(store.addComment(postID: newPost.id, text: "Thanks for opening this conversation."))
        let comment = try! XCTUnwrap(store.rootComments(for: newPost.id).first)
        XCTAssertTrue(store.addComment(postID: newPost.id, text: "I agree with that point.", parentID: comment.id))
        XCTAssertEqual(store.comments(for: newPost.id).filter { $0.parentID == comment.id }.count, 1)
        store.toggleCommentLike(comment.id)
        XCTAssertTrue(store.comments(for: newPost.id).first(where: { $0.id == comment.id })?.likedBy.contains(store.currentUserID) == true)

        let pollClub = store.clubs[0]
        let poll = try! XCTUnwrap(store.posts(in: pollClub.id).first(where: { $0.kind == .poll }))
        store.vote(postID: poll.id, option: 0)
        store.vote(postID: poll.id, option: 1)
        XCTAssertEqual(store.vote(for: poll.id), 0)
        XCTAssertEqual(store.voteCount(postID: poll.id, option: 0), 1)

        store.toggleFollow("user_002")
        XCTAssertTrue(store.isFollowing("user_002"))
        let event = try! XCTUnwrap(store.events.first(where: { $0.clubID == pollClub.id && $0.date >= .now }))
        store.toggleRSVP(event.id)
        XCTAssertTrue(store.hasRSVP(event.id))
        let createdID = store.createClub(name: "My Demo Circle", description: "A welcoming place for local property conversations.", category: "Market Talk", coverURL: "", avatarURL: "", visibility: .public, rules: ["Be respectful."])
        XCTAssertNotNil(createdID)
        XCTAssertEqual(store.role(in: createdID!), .owner)

        let reopened = ClubsStore(defaults: defaults)
        XCTAssertTrue(reopened.isMember(joinTarget.id))
        XCTAssertTrue(reopened.posts.contains(where: { $0.id == newPost.id }))
        XCTAssertTrue(reopened.isFollowing("user_002"))
        XCTAssertTrue(reopened.hasRSVP(event.id))
        XCTAssertNotNil(reopened.club(createdID!))
    }

    @MainActor
    func testPostingRequiresMembershipAndClubCreationValidatesFields() {
        let (store, _) = makeStore()
        let visitor = "user_072"
        store.switchUser(to: visitor)
        let club = store.clubs[0]
        XCTAssertFalse(store.makePost(clubID: club.id, kind: .text, text: "This should be blocked."))
        XCTAssertNil(store.createClub(name: "No", description: "Too short", category: "Market Talk", coverURL: "", avatarURL: "", visibility: .public, rules: []))
        store.join(club.id)
        XCTAssertFalse(store.makePost(clubID: club.id, kind: .poll, text: "Which topic next?", options: ["One"]))
        XCTAssertTrue(store.joinedClubs().contains(where: { $0.id == club.id }))
    }

    @MainActor
    private func makeStore() -> (ClubsStore, UserDefaults) {
        let name = "mogul-clubs-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return (ClubsStore(defaults: defaults), defaults)
    }

    @MainActor
    private func tryUnjoinedClub(_ store: ClubsStore) -> DemoClub {
        store.clubs.first(where: { !store.isMember($0.id) })!
    }
}
