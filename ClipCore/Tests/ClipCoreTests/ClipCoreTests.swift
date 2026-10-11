import XCTest
@testable import ClipCore

private func text(_ s: String, extra: [PasteboardEntry] = []) -> [PasteboardEntry] {
    [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.string, data: Data(s.utf8))] + extra
}

final class FuzzyMatcherTests: XCTestCase {
    func testEmptyQueryMatchesEverything() {
        XCTAssertEqual(FuzzyMatcher.rank(["a", "b"], query: "  ", text: { $0 }), ["a", "b"])
    }

    func testCaseInsensitiveSubstring() {
        XCTAssertNotNil(FuzzyMatcher.score("HELLO", in: "say hello world"))
    }

    func testSubsequenceMatches() {
        XCTAssertNotNil(FuzzyMatcher.score("gtco", in: "git commit"))
        XCTAssertNil(FuzzyMatcher.score("xyz", in: "git commit"))
        XCTAssertNil(FuzzyMatcher.score("tig", in: "git"))
    }

    func testSubstringOutranksScatteredMatch() {
        let ranked = FuzzyMatcher.rank(["c-a-t scattered", "concatenate"], query: "cat", text: { $0 })
        XCTAssertEqual(ranked, ["concatenate", "c-a-t scattered"])
    }

    func testWordStartAndEarlierPositionRankHigher() {
        let ranked = FuzzyMatcher.rank(["xxxxport", "export data", "port 8080"], query: "port", text: { $0 })
        XCTAssertEqual(ranked.first, "port 8080")
    }

    func testTiesKeepInputOrder() {
        let ranked = FuzzyMatcher.rank(["abc 1", "abc 2", "abc 3"], query: "abc", text: { $0 })
        XCTAssertEqual(ranked, ["abc 1", "abc 2", "abc 3"])
    }

    func testOnlySearchesPrefix() {
        let long = String(repeating: "a", count: FuzzyMatcher.searchLimit) + "needle"
        XCTAssertNil(FuzzyMatcher.score("needle", in: long))
    }
}

final class CaptureRulesTests: XCTestCase {
    func testIgnoresConcealedTypes() {
        let rules = CaptureRules()
        XCTAssertFalse(rules.shouldInspect(types: [PasteboardTypes.string, "org.nspasteboard.ConcealedType"], sourceBundleID: nil))
        XCTAssertTrue(rules.shouldInspect(types: [PasteboardTypes.string], sourceBundleID: "com.apple.Safari"))
    }

    func testIgnoresPasswordManagers() {
        XCTAssertFalse(CaptureRules().shouldInspect(types: [PasteboardTypes.string], sourceBundleID: "com.1password.1password"))
    }

    func testIgnoresOwnWrites() {
        let rules = CaptureRules(ownMarkerType: "com.example.mine")
        XCTAssertFalse(rules.shouldInspect(types: [PasteboardTypes.string, "com.example.mine"], sourceBundleID: nil))
        XCTAssertEqual(rules.storableTypes([PasteboardTypes.string, "com.example.mine"]), [PasteboardTypes.string])
    }

    func testEmptyPasteboardIsIgnored() {
        XCTAssertFalse(CaptureRules().shouldInspect(types: [], sourceBundleID: nil))
    }

    func testDropsFilePromises() {
        let types = [PasteboardTypes.fileURL, "com.apple.pasteboard.promised-file-url"]
        XCTAssertEqual(CaptureRules().storableTypes(types), [PasteboardTypes.fileURL])
    }

    func testSizeLimit() {
        let rules = CaptureRules(maxPayloadBytes: 4)
        XCTAssertTrue(rules.shouldStore(text("1234")))
        XCTAssertFalse(rules.shouldStore(text("12345")))
        XCTAssertFalse(rules.shouldStore([]))
    }
}

final class ContentFingerprintTests: XCTestCase {
    func testSameTextFromDifferentAppsMatches() {
        let fromSafari = text("hello", extra: [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.html, data: Data("<b>hello</b>".utf8))])
        let fromNotes = text("hello", extra: [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.rtf, data: Data("{\\rtf1 hello}".utf8))])
        XCTAssertEqual(ContentFingerprint.make(fromSafari), ContentFingerprint.make(fromNotes))
    }

    func testDifferentTextDiffers() {
        XCTAssertNotEqual(ContentFingerprint.make(text("hello")), ContentFingerprint.make(text("hellO")))
    }

    func testOrderIndependent() {
        let a = [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.fileURL, data: Data("file:///a".utf8)),
                 PasteboardEntry(itemIndex: 1, type: PasteboardTypes.fileURL, data: Data("file:///b".utf8))]
        XCTAssertEqual(ContentFingerprint.make(a), ContentFingerprint.make(a.reversed()))
    }

    func testFixedWidthHex() {
        let fp = ContentFingerprint.make(text("x"))
        XCTAssertEqual(fp.count, 16)
        XCTAssertTrue(fp.allSatisfy(\.isHexDigit))
    }
}

final class HistoryRulesTests: XCTestCase {
    func testTrimKeepsNewestUnpinnedAndAllPinned() {
        let now = Date()
        let items = [
            TrimCandidate(id: "old", isPinned: false, lastCopiedAt: now.addingTimeInterval(-300)),
            TrimCandidate(id: "pinnedOld", isPinned: true, lastCopiedAt: now.addingTimeInterval(-900)),
            TrimCandidate(id: "new", isPinned: false, lastCopiedAt: now),
            TrimCandidate(id: "mid", isPinned: false, lastCopiedAt: now.addingTimeInterval(-60)),
        ]
        XCTAssertEqual(HistoryTrimmer.idsToRemove(items, limit: 2), ["old"])
        XCTAssertEqual(Set(HistoryTrimmer.idsToRemove(items, limit: 0)), ["old", "new", "mid"])
        XCTAssertEqual(HistoryTrimmer.idsToRemove(items, limit: 10), [])
    }

    func testTitleCollapsesWhitespace() {
        XCTAssertEqual(ClipTitle.make(from: "  line one\n\n\tline two  "), "line one line two")
        XCTAssertNil(ClipTitle.make(from: " \n "))
    }

    func testTitleTruncates() {
        let title = ClipTitle.make(from: String(repeating: "a", count: 50), maxLength: 10)
        XCTAssertEqual(title, "aaaaaaaaa…")
        XCTAssertEqual(title?.count, 10)
    }

    func testTitleByKind() {
        let files = [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.fileURL, data: Data("file:///Users/me/Report.pdf".utf8)),
                     PasteboardEntry(itemIndex: 1, type: PasteboardTypes.fileURL, data: Data("file:///Users/me/a%20b.png".utf8))]
        XCTAssertEqual(files.kind, .file)
        XCTAssertEqual(ClipTitle.make(for: files), "Report.pdf, a b.png")

        let image = [PasteboardEntry(itemIndex: 0, type: PasteboardTypes.png, data: Data([0x89]))]
        XCTAssertEqual(image.kind, .image)
        XCTAssertEqual(ClipTitle.make(for: image), "Image")

        XCTAssertEqual(ClipTitle.make(for: text("hi\nthere")), "hi there")
    }
}
