//
//  ComplicationController.swift
//  InzidenzMonitor WatchKit Extension
//
//  Created by Markus Ullmann on 29.10.21.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {

    var timelineEntries : [IncidenceEntry] = []

    var timelineStartDate : Date?
    var timelineEndDate : Date?

    var lastSyncDate : Date?

    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "InzidenzMonitor", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Sync data from watchos App to show in complication
    func updateCovidData() {
        if IncidencesStore.shared.lastRefreshDate == nil {
            return
        }
        if IncidencesStore.shared.lastRefreshDate == lastSyncDate {
            return
        }

        self.timelineEntries.removeAll()
        self.timelineStartDate = getStartOfDay(for: IncidencesStore.shared.lastRefreshDate!)
        self.timelineEndDate = self.timelineStartDate!.addingTimeInterval(60*60*24)
        self.timelineEntries = IncidencesStore.shared.incidences

        self.lastSyncDate = IncidencesStore.shared.lastRefreshDate
    }

    func getStartOfDay(for date: Date = Date()) -> Date {
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.local
        let dateAtMidnight = calendar.startOfDay(for: date)
        return dateAtMidnight
    }

    // MARK: - Timeline Configuration
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        debugPrint("getTimelineEndDate called")
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        debugPrint("getCurrentTimelineEntry called")
        self.updateCovidData()
        if self.timelineEntries.count == 0 {
            let tmpl = getTemplate(for: complication, using: nil)
            handler(CLKComplicationTimelineEntry(date: Date(timeIntervalSince1970: 1), complicationTemplate: tmpl))
            return
        }
        let entry = self.timelineEntries[0]
        let tmpl = getTemplate(for: complication, using: entry)
        handler(CLKComplicationTimelineEntry(date: entry.timestamp, complicationTemplate: tmpl))
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        debugPrint("getTimelineEntries called")
        // Call the handler with the timeline entries after the given date
        self.updateCovidData()
        if self.timelineEntries.count == 0 {
            let tmpl = getTemplate(for: complication, using: nil)
            handler([CLKComplicationTimelineEntry(date: Date(timeIntervalSince1970: 1), complicationTemplate: tmpl)])
            return
        }
        var entries : [CLKComplicationTimelineEntry] = []
        for entry in timelineEntries {
            let tmpl = getTemplate(for: complication, using: entry)
            entries.append(CLKComplicationTimelineEntry(date: entry.timestamp, complicationTemplate: tmpl))
        }

        handler(entries)
    }

    // MARK: - Templates
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(getTemplate(for: complication, using: nil))
    }

    func getTemplate(for complication: CLKComplication, using entry: IncidenceEntry? = nil) -> CLKComplicationTemplate {
        var header : CLKSimpleTextProvider
        var body1 : CLKSimpleTextProvider
        var body2 : CLKSimpleTextProvider
        var body_comb : CLKSimpleTextProvider

        if let entry = entry {
            let formatted_timestamp = self.dateFormatter.string(from: entry.timestamp)
            header = CLKSimpleTextProvider(text: "\(entry.locality) \(formatted_timestamp)")
            body1 = CLKSimpleTextProvider(text: "Inzidenz: \(entry.incidence)")
            body2 = CLKSimpleTextProvider(text: "Hospital: \(entry.hospitalization)")
            body_comb = CLKSimpleTextProvider(text: "\(entry.incidence) / \(entry.hospitalization)")
        } else {
            header = CLKSimpleTextProvider(text: "Land (DD.MM.)")
            body1 = CLKSimpleTextProvider(text: "Inzidenz: XXX")
            body2 = CLKSimpleTextProvider(text: "Hospital: XXX")
            body_comb = CLKSimpleTextProvider(text: "XXX / XXX")
        }
        switch(complication.family) {
        case .modularSmall:
            let tmpl = CLKComplicationTemplateModularSmallSimpleText(textProvider: body_comb)
            return tmpl
        case .modularLarge:
            let tmpl = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider:header, body1TextProvider: body1, body2TextProvider: body2)
            return tmpl
        case .graphicRectangular:
            let tmpl = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: header, body1TextProvider: body1, body2TextProvider: body2)
            return tmpl
        default:
            let tmpl = CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: header, body1TextProvider: body1, body2TextProvider: body2)
            return tmpl
        }
    }

    let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        // d.locale = Locale(identifier: "en_US_POSIX")
        d.dateFormat = "(dd.MM.)"
        // Force something CET'ish to not fail when overseas as the data is CET-sourced
        d.timeZone = TimeZone(identifier: "Europe/Berlin")!

        return d
    }()
}
