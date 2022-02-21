//
//  Color+Extention.swift
//
//  Created by 灰桑 on 7/31/20.
//  Copyright © 2020 灰桑. All rights reserved.
//

import Foundation
import SwiftUI

/// Hex 值
/// eg：Color(hex: "293241")
extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex = String(hex[hex.index(after: hex.startIndex)...])
        }
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
    }
}
