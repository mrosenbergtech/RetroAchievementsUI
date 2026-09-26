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

    // MARK: - Links
    //
    // The shapes below are taken from real API_GetComments responses: players
    // paste bare URLs, usually a YouTube guide, sometimes with `?si=…&t=…`
    // still attached. The API does not HTML-escape them, so what arrives is
    // exactly what has to be detected.

    // Fully qualified: Swift Testing exports its own `Comment` type, so the
    // bare name is ambiguous in a return position here.
    private func comment(_ text: String) -> RetroAchievementsUI.Comment {
        RetroAchievementsUI.Comment(user: "a", userULID: nil,
                                    submitted: "2021-07-04T10:11:12.000000Z",
                                    text: text)
    }

    @Test("A bare YouTube URL becomes a link")
    func detectsBareURL() {
        let found = comment("https://youtu.be/3ncB3AFeG3c").links
        #expect(found.map(\.absoluteString) == ["https://youtu.be/3ncB3AFeG3c"])
    }

    @Test("Query parameters survive detection")
    func keepsQueryParameters() {
        // A timestamped guide link is worthless without its `t` parameter.
        let raw = "https://youtu.be/wV-A-P2JP94?si=2AFnqgGMZJQfmd1h&t=155"
        #expect(comment(raw).links.map(\.absoluteString) == [raw])
    }

    @Test("A URL in the middle of a sentence is linked without its surroundings")
    func detectsURLInProse() {
        let found = comment("This might be the easiest achievement in this set. "
                            + "https://www.youtube.com/watch?v=MLcwJH8WcZA").links
        #expect(found.map(\.absoluteString)
                == ["https://www.youtube.com/watch?v=MLcwJH8WcZA"])
    }

    @Test("Trailing punctuation stays out of the URL")
    func excludesTrailingPunctuation() {
        // "see https://youtu.be/abc." must not link to ".../abc." — that 404s.
        let found = comment("see https://youtu.be/abc.").links
        #expect(found.map(\.absoluteString) == ["https://youtu.be/abc"])
    }

    @Test("A scheme-less www link is resolved to an openable URL")
    func detectsSchemelessLink() {
        // The detector supplies http:// for a scheme-less host. Left as it
        // comes: the alternative is guessing https for the author, which
        // breaks the http-only fan sites this hobby is full of, and both
        // Safari and any site worth visiting redirect anyway.
        let found = comment("guide at www.youtube.com/watch?v=abc").links.first
        #expect(found?.scheme == "http")
        #expect(found?.host == "www.youtube.com")
        #expect(found?.absoluteString == "http://www.youtube.com/watch?v=abc")
    }

    @Test("Several links in one comment are kept in the order written")
    func detectsMultipleLinks() {
        let found = comment("part one https://youtu.be/one then https://youtu.be/two").links
        #expect(found.map(\.absoluteString)
                == ["https://youtu.be/one", "https://youtu.be/two"])
    }

    @Test("A comment with no URL yields no links")
    func detectsNoLinks() {
        #expect(comment("Took me ages to get this one.").links.isEmpty)
        #expect(comment("").links.isEmpty)
    }

    @Test("Marked-up text reads the same as the original")
    func linkedTextPreservesCharacters() {
        // The row shows linkedText instead of text, so any character the
        // markup dropped or reordered would be a visible corruption.
        for raw in ["Took me ages to get this one.",
                    "https://youtu.be/3ncB3AFeG3c",
                    "see https://youtu.be/abc. then www.example.com/x done",
                    "unicode é 🎮 https://youtu.be/one tail",
                    ""] {
            let marked = comment(raw).linkedText
            #expect(String(marked.characters) == raw)
        }
    }

    @Test("Only the URL run carries the link attribute")
    func linkedTextMarksOnlyTheURL() {
        let marked = comment("watch https://youtu.be/one first").linkedText

        let linked = marked.runs.filter { $0.link != nil }
        #expect(linked.count == 1)
        #expect(linked.first.map { String(marked[$0.range].characters) } == "https://youtu.be/one")
        #expect(linked.first?.link?.absoluteString == "https://youtu.be/one")

        let plain = marked.runs.filter { $0.link == nil }
            .map { String(marked[$0.range].characters) }
            .joined()
        #expect(plain == "watch  first")
    }
}
