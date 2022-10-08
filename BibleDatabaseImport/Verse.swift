//
//  Verse.swift
//  BibleDatabaseImport
//
//  Created by Austin Savage on 10/8/22.
//

import Foundation

struct Verse: Codable {
    var bookId: Int32
    var chapter: Int32
    var verse: Int32
    var text: String
}
