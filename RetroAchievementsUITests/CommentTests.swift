//
//  CommentTests.swift
//  RetroAchievementsUITests
//
//  Pure decoding only. The network-backed comment tests live in NetworkTests,
//  which owns the one serialized suite allowed to drive MockURLProtocol —
//  its handler is global state, so a second parallel suite touching it
//  clobbered the first mid-test.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("Comments")
struct CommentTests {

    private func decoded() throws -> CommentsResult {
        try JSONDecoder().decode(CommentsResult.self, from: Fixtures.achievementComments)
    }

    @Test("Decodes the GetComments payload")
    func decodes() throws {
        let result = try decoded()

        #expect(result.count == 4)
        #expect(result.total == 31)
        #expect(result.results.count == 4)
        #expect(result.results[1].user == "junyor789")
        #expect(result.results[1].text == "Took me ages to get this one.")
    }

    @Test("Comment ids are unique even when one user comments twice")
    func idsAreUnique() throws {
        // ULID identifies the author, not the comment — two comments from the
        // same user share it, so it cannot be the row identity.
        let results = try decoded().results
        let ulids = Set(results.compactMap(\.userULID))
        #expect(ulids.count < results.count)
        #expect(Set(results.map(\.id)).count == results.count)
    }

    @Test("Player comments come back newest first, with Server entries dropped")
    func playerCommentsOrdering() throws {
        // The API returns oldest-first: 2019 Server, 2021, 2021, 2022 Server.
        let ordered = try decoded().results.playerComments

        #expect(ordered.count == 2)
        #expect(ordered.allSatisfy { !$0.isAutomated })
        #expect(ordered.first?.text == "Actually the trick is to wait.")   // 2021-07-05
        #expect(ordered.last?.text == "Took me ages to get this one.")     // 2021-07-04

        let dates = ordered.compactMap(\.submittedDate)
        #expect(dates == dates.sorted(by: >))
    }

    @Test("Comments with an unparseable date sort last rather than dropping out")
    func undatedCommentsSortLast() {
        let list = [
            Comment(user: "a", userULID: nil, submitted: "nonsense", text: "undated"),
            Comment(user: "b", userULID: nil,
                    submitted: "2021-07-04T10:11:12.000000Z", text: "dated"),
        ]

        let ordered = list.playerComments
        #expect(ordered.count == 2)
        #expect(ordered.first?.text == "dated")
        #expect(ordered.last?.text == "undated")
    }

    @Test("Automated Server entries are recognised")
    func detectsAutomated() throws {
        let results = try decoded().results

        #expect(results.filter(\.isAutomated).count == 2)
        // What a player actually wrote.
        #expect(results.filter { !$0.isAutomated }.count == 2)
    }

    @Test("Parses the ISO8601-with-fractional-seconds timestamp")
    func parsesTimestamp() throws {
        let comment = try #require(try decoded().results.first)
        let date = try #require(comment.submittedDate)

        let parts = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        #expect(parts.year == 2019)
        #expect(parts.month == 2)
        #expect(parts.day == 15)
        #expect(comment.relativeSubmitted != nil)
    }

    @Test("An unparseable timestamp yields no date rather than a wrong one")
    func rejectsBadTimestamp() {
        let comment = Comment(user: "a", userULID: nil,
                              submitted: "not a date", text: "hi")
        #expect(comment.submittedDate == nil)
        #expect(comment.relativeSubmitted == nil)
    }
}
