//
//  SupportTests.swift
//  RetroAchievementsUITests
//
//  Image URL construction and console grouping — both places where the app
//  previously had inconsistencies or a force-unwrap.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("RAImageURL")
struct RAImageURLTests {

    @Test("Builds the same URL whether or not the path has a leading slash")
    func leadingSlashAgnostic() {
        // The API is inconsistent: award icons arrive as "/Images/x.png" while
        // some other fields arrive without the slash.
        let withSlash = RAImageURL.gameIcon("/Images/047942.png")
        let withoutSlash = RAImageURL.gameIcon("Images/047942.png")

        #expect(withSlash?.absoluteString == "https://retroachievements.org/Images/047942.png")
        #expect(withSlash == withoutSlash)
    }

    @Test("Never produces a double slash after the host")
    func noDoubleSlash() {
        let url = try! #require(RAImageURL.gameIcon("/Images/047942.png"))
        #expect(url.absoluteString.contains("org//") == false)
    }

    @Test("Nil and empty paths yield no URL")
    func nilAndEmpty() {
        #expect(RAImageURL.gameIcon(nil) == nil)
        #expect(RAImageURL.gameIcon("") == nil)
        #expect(RAImageURL.titleScreen("") == nil)
    }

    @Test("Avatar falls back to the default user picture")
    func avatarFallback() {
        let fallback = RAImageURL.avatar(nil)
        #expect(fallback?.absoluteString.contains("UserPic") == true)

        let real = RAImageURL.avatar("/UserPic/mrosen97.png")
        #expect(real?.absoluteString == "https://retroachievements.org/UserPic/mrosen97.png")
    }

    @Test("Badge URLs use the _lock variant only when locked")
    func badgeLocking() {
        #expect(RAImageURL.badge("54321", locked: false)?.absoluteString
                == "https://retroachievements.org/Badge/54321.png")
        #expect(RAImageURL.badge("54321", locked: true)?.absoluteString
                == "https://retroachievements.org/Badge/54321_lock.png")
    }
}

@Suite("Consoles")
struct ConsolesTests {

    private func consoles() -> Consoles {
        let list = try! JSONDecoder().decode([Console].self, from: Fixtures.consoleIDs)
        return Consoles(consoles: list)
    }

    @Test("Looks up a console by ID")
    func lookup() {
        #expect(consoles().getConsoleDataByID(consoleID: 2)?.name == "Nintendo 64")
    }

    @Test("An unknown console ID returns nil instead of crashing")
    func unknownIDIsNil() {
        // This used to force-unwrap `.first!`, so any hardcoded manufacturer ID
        // the API stopped returning took the app down at launch.
        #expect(consoles().getConsoleDataByID(consoleID: 99_999) == nil)
    }

    @Test("Manufacturer groups drop IDs the API did not return")
    func groupsOnlyContainKnownConsoles() {
        let grouped = consoles().consolesSortedByKind
        let known = Set([2, 1, 14])

        for group in grouped {
            #expect(group.consoleIDList.allSatisfy(known.contains))
        }
    }

    @Test("Empty manufacturer groups are omitted")
    func noEmptyGroups() {
        #expect(consoles().consolesSortedByKind.allSatisfy { !$0.consoleIDList.isEmpty })
    }

    @Test("SNK consoles are present in the grouped list")
    func snkIsIncluded() {
        // snConsoles was missing from consolesSortedByKind, so Neo Geo systems
        // never appeared in the Consoles tab.
        let ids = consoles().consolesSortedByKind.flatMap(\.consoleIDList)
        #expect(ids.contains(14))
    }

    @Test("Consoles within a group are sorted by name")
    func sortedByName() {
        let list = try! JSONDecoder().decode([Console].self, from: Fixtures.consoleIDs)
        let subject = Consoles(consoles: list)

        for group in subject.consolesSortedByKind {
            let names = group.consoleIDList.compactMap {
                subject.getConsoleDataByID(consoleID: $0)?.name.lowercased()
            }
            #expect(names == names.sorted())
        }
    }
}
