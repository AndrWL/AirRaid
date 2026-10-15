//
//  NightReportProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Defines the state of the night report sheet.
protocol NightReportViewModelProtocol: BaseViewModelProtocol {

    /// `nil` until the feed has been read.
    var content: NightReportContent? { get }

    var isSpeaking: Bool { get }

    /// Reads the report aloud, or stops reading it.
    func didTapListen()
}
