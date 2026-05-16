//
//  Item.swift
//  Greekdrivingtest
//
//  Created by John on 16/5/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
