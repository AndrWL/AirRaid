//
//  Data+Base64URL.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

nonisolated extension Data {

    /// Decodes base64url (RFC 4648 §5) with or without padding; plain base64 is accepted too.
    ///
    /// The backend sends signatures, keys and App Attest fields as unpadded base64url, which `Data(base64Encoded:)`
    /// rejects as is.
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: base64)
    }

    /// Unpadded base64url (RFC 4648 §5), the form the backend expects in JSON bodies.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
