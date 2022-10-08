//
//  SQLiteSession.swift
//  BibleDatabaseImport
//
//  Created by Austin Savage on 10/8/22.
//

import Foundation


class SQLiteSession {
    let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
    
    enum ReturnType {
        case Text(value: String)
        case Int(value: Int)
    }
    
    private var db: OpaquePointer?
    
    convenience init(_ path: String) {
        self.init(path, flags: SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
    }
    
    init(_ path: String, flags: Int32) {
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            print(message)
            //throw DatabaseError.initializationError(message: message)
            return
        }
    }
    
    func execute(_ sql: String) {
        var statement: OpaquePointer?
        
        sqlite3_prepare(db, sql, Int32(sql.count), &statement, nil)
        
        while true {
            let result = sqlite3_step(statement)
            
            if result == SQLITE_DONE {
                print("Query done!")
                break
            } else if result == SQLITE_ROW {
                print("---row---")
                /* print collector */
                let count = sqlite3_column_count(statement)
                for column in 0..<count {
                    let name = sqlite3_column_name(statement, column)!
                    let value = sqlite3_column_text(statement, column)!
                    print("\(String(cString: name)): \(String(cString: value))")
                }
            } else if result != SQLITE_BUSY {
                print("Query error... \(result)")
                break
            }
        }
        
        guard sqlite3_finalize(statement) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            print(message)
            return
        }
    }
    
    func startTransaction()  {
        execute("BEGIN EXCLUSIVE TRANSACTION")
    }
    
    func endTransaction() {
        execute("COMMIT TRANSACTION")
    }
    
    func insertVerse(_ preparedStatement: OpaquePointer?, _ verse: Verse) {
        sqlite3_bind_int(preparedStatement, 1, verse.bookId)
        sqlite3_bind_int(preparedStatement, 2, verse.chapter)
        sqlite3_bind_int(preparedStatement, 3, verse.verse)
        sqlite3_bind_text(preparedStatement, 4, verse.text, Int32(verse.text.lengthOfBytes(using: .utf8)), SQLITE_TRANSIENT)
        
        while true {
            let result = sqlite3_step(preparedStatement)
            
            if result == SQLITE_DONE {
                break
            } else if result != SQLITE_BUSY {
                let message = String(cString: sqlite3_errmsg(db))
                print(message)
                return
            }
        }
        
        sqlite3_reset(preparedStatement)
    }
    
    func insertBook(_ preparedStatement: OpaquePointer?, _ book: Book) {
        sqlite3_bind_int(preparedStatement, 1, Int32(book.id))
        sqlite3_bind_text(preparedStatement, 2, book.name, Int32(book.name.lengthOfBytes(using: .utf8)), SQLITE_TRANSIENT)
        sqlite3_bind_text(preparedStatement, 3, book.abbreviation, Int32(book.abbreviation.lengthOfBytes(using: .utf8)), SQLITE_TRANSIENT)
        
        while true {
            let result = sqlite3_step(preparedStatement)
            
            if result == SQLITE_DONE {
                break
            } else if result != SQLITE_BUSY {
                let message = String(cString: sqlite3_errmsg(db))
                print(message)
                return
            }
        }
        
        sqlite3_reset(preparedStatement)
    }
    
    func prepare(_ sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare(db, sql, Int32(sql.count), &statement, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            print(message)
            return nil
        }
        
        return statement
    }
}
