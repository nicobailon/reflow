import SwiftUI
import ReflowCore

@MainActor
final class StatisticsManager: ObservableObject {
    @AppStorage("allTimeLinesJoined") private var storedAllTimeLinesJoined: Int = 0
    @AppStorage("allTimePastes") private var storedAllTimePastes: Int = 0
    
    @Published private(set) var sessionLinesJoined: Int = 0
    @Published private(set) var sessionPastes: Int = 0
    
    var allTimeLinesJoined: Int { storedAllTimeLinesJoined }
    var allTimePastes: Int { storedAllTimePastes }
    
    var statistics: ReflowStatistics {
        ReflowStatistics(
            sessionLinesJoined: sessionLinesJoined,
            sessionPastes: sessionPastes,
            allTimeLinesJoined: storedAllTimeLinesJoined,
            allTimePastes: storedAllTimePastes
        )
    }
    
    func recordPaste(linesJoined: Int) {
        sessionLinesJoined += linesJoined
        sessionPastes += 1
        storedAllTimeLinesJoined += linesJoined
        storedAllTimePastes += 1
    }
    
    func resetSession() {
        sessionLinesJoined = 0
        sessionPastes = 0
    }
    
    func resetAllTime() {
        storedAllTimeLinesJoined = 0
        storedAllTimePastes = 0
        resetSession()
    }
}
