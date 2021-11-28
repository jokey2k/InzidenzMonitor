//
//  IncidencesStore.swift
//  InzidenzMonitor
//
//  Created by Markus Ullmann on 29.10.21.
//

import Foundation

struct IncidenceEntry {
    var timestamp: Date
    var incidence: Int
    var hospitalization: Int
    var locality: String
}

enum IncidenceFetchError: Error {
    case unreachable(String)
    case parsingFail(String)
}

final class IncidencesStore {
    var incidences : [IncidenceEntry] = []
    var lastRefreshDate : Date?

    enum Region {
        case Austria
        // case Hamburg
    }

    var usedSource : Region = .Austria

    private init () {
        // Do nothing for now, maybe init later
    }

    static let shared = IncidencesStore()

    func fetchData(handler: @escaping (IncidencesStore?) -> Void) throws {
        if usedSource == .Austria {
            try fetchDataAustria(handler: handler)
        }
    }

    func fetchDataAustria(handler: @escaping (IncidencesStore?) -> Void) throws {
        let url = URL(string:"https://b.staticfiles.at/elm/live/2020-10-covid19/widget.json")!
        let urlSession = URLSession.shared
        debugPrint("Queueing data fetch")
        Task {
            let data : Data
            let response : URLResponse

            // fetch
            do {
                (data, response) = try await urlSession.data(from: url)
            }
            catch {
                throw IncidenceFetchError.unreachable("Error loading \(url): \(String(describing: error))")
            }

            // status check
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw IncidenceFetchError.unreachable("Error loading \(url): Got HTTP \(String(httpResponse.statusCode))")
                }
            }

            // initiate parsing
            let rawDictionary : [String:Any]
            do {
                rawDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            }
            catch {
                throw IncidenceFetchError.parsingFail("Failed reading json from \(url): \(String(describing: error))")
            }
            do {
                try processDataAustria(data: rawDictionary)
            }
            catch {
                throw IncidenceFetchError.parsingFail("Failed parsing numbers from \(url): \(String(describing: error))")
            }

            self.lastRefreshDate = Date()
            handler(self)
            debugPrint("Done with data fetch")
        }
    }

    func processDataAustria(data: [String:Any]) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let incidencedata = data["inzidenz"] as? [String: Any]
        let incidencevalue = incidencedata?["value"] as! Int

        let icudata = data["icu"] as? [String: Any]
        let hospitalizationvalue = icudata?["occupied"] as! Int

        let timestamp = dateFormatter.date(from: incidencedata?["date"] as! String)!

        self.incidences.append(IncidenceEntry(timestamp: timestamp, incidence: incidencevalue, hospitalization: hospitalizationvalue, locality: "Österreich"))
    }
}

