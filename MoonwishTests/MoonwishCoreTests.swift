import AVFoundation
import SwiftData
import XCTest
@testable import Moonwish

final class MoonwishCoreTests: XCTestCase {
    func testLocalScriptComposerProducesSpeakableScript() {
        let input = WishInput(wish: "I want him to text me back", category: WishDomain.love.rawValue, answers: ["Tonight", "Someone specific"], targetDate: nil)
        let script = LocalScriptComposer.make(input: input)
        XCTAssertGreaterThanOrEqual(script.lines.count, 10)
        XCTAssertFalse(script.opening.isEmpty)
        XCTAssertFalse(script.closing.isEmpty)
        XCTAssertTrue(script.plainText.contains("text me back"))
    }

    func testScriptValidatorParsesWrappedJSON() {
        let raw = """
        Here is your script:
        {"title":"Tonight's Letter","opening":"Breathe in.","lines":["You are calm.","You are safe.","You are open.","You are ready.","You are steady.","You are here."],"closing":"Sleep well.","minutes":8}
        """
        let script = ScriptValidator.parse(raw)
        XCTAssertNotNil(script)
        XCTAssertEqual(script?.lines.count, 6)
    }

    func testScriptValidatorRejectsShortContent() {
        XCTAssertNil(ScriptValidator.parse("not json at all"))
    }

    @MainActor
    func testAudioRendererWritesPlayableFile() async throws {
        let script = ManifestationScript(
            title: "Test",
            opening: "Breathe in slowly.",
            lines: ["You are calm.", "You are safe.", "You are here."],
            closing: "Sleep well.",
            minutes: 8
        )
        let fileName = "unit-test-\(UUID().uuidString).caf"
        let url = try await AudioRenderer.shared.render(script: script, voiceIdentifier: nil, fileName: fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(AudioQuality.isValid(url: url))
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        XCTAssertGreaterThan(duration, 3)
        try? FileManager.default.removeItem(at: url)
    }

    @MainActor
    func testStorePersistsWishAndStreak() throws {
        let schema = Schema([Wish.self, AudioSession.self, DailyRecord.self, JournalEntry.self, BoardItem.self, StreakState.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let wish = Wish(text: "I feel calm", category: .myself, answers: ["Calm"])
        context.insert(wish)
        let session = AudioSession(title: "Calm", scriptJSON: "", fileName: "x.caf", voiceId: "", soundscape: "Theta Waves", duration: 60, engineUsed: "local", qualityPassed: true)
        session.wish = wish
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Wish>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.sessions.count, 1)

        let state = StreakEngine.markListened(in: context, isPlus: false)
        XCTAssertGreaterThanOrEqual(state.currentStreak, 1)
        let records = try context.fetch(FetchDescriptor<DailyRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(records.first?.listened ?? false)
    }

    func testMoonPhaseIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1794000000)
        let phase = MoonPhaseCalculator.phase(for: date)
        XCTAssertGreaterThanOrEqual(phase, 0)
        XCTAssertLessThan(phase, 1)
        XCTAssertFalse(MoonPhaseCalculator.name(for: date).isEmpty)
    }

    func testPresetLibraryHasAtLeastTwentyTracks() {
        XCTAssertGreaterThanOrEqual(PresetCatalog.tracks.count, 20)
        XCTAssertGreaterThanOrEqual(SoundscapeCatalog.all.count, 21)
    }
}
