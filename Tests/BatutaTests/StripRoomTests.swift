import Testing
@testable import Batuta

struct StripRoomTests {
    @Test func keepsTheWidestStripSeenOnAScreen() {
        var room = StripRoom()
        #expect(room.width(measured: 165, onScreen: "a", fallback: 260) == 165)
        #expect(room.width(measured: 115, onScreen: "a", fallback: 260) == 165)
        #expect(room.width(measured: 180, onScreen: "a", fallback: 260) == 180)
    }

    @Test func eachScreenRemembersItsOwnStrip() {
        var room = StripRoom()
        _ = room.width(measured: 200, onScreen: "a", fallback: 260)
        #expect(room.width(measured: 120, onScreen: "b", fallback: 260) == 120)
    }

    @Test func usesTheFallbackUntilAStripIsSeen() {
        var room = StripRoom()
        #expect(room.width(measured: nil, onScreen: "a", fallback: 260) == 260)
        _ = room.width(measured: 150, onScreen: "a", fallback: 260)
        #expect(room.width(measured: nil, onScreen: "a", fallback: 260) == 150)
    }
}
