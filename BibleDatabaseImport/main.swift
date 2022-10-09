//
//  main.swift
//  BibleDatabaseImport
//
//  Created by Austin Savage on 10/8/22.
//

import Foundation

var db: SQLiteSession

db = try SQLiteSession("/Users/savage/Documents/BibleDatabaseImport/dra.db")

db.execute("""

    CREATE TABLE books (
        id INT,
        name TEXT,
        abbreviation TEXT
    );

""")

db.startTransaction()

let insertBooks = "INSERT INTO books (id, name, abbreviation) VALUES (?,?,?);"

let preparedInsertBooks = db.prepare(insertBooks)

let booksUrl = URL(fileURLWithPath: "/Users/savage/Documents/BibleDatabaseImport/dra/books.tsv")
let books =  try String(contentsOf: booksUrl)
    .replacingOccurrences(of: "\r\n", with: "\n")
    .split(separator: "\n")

for book in books {
    if book.isEmpty {
        continue
    }
    let parts = book.split(separator: "\t")
    let row = Book(id: Int32(parts[0])!, name: String(parts[1]), abbreviation: String(parts[2]))
    db.insertBook(preparedInsertBooks, row)
}

sqlite3_finalize(preparedInsertBooks)
db.endTransaction()
    
db.execute("""

    CREATE VIRTUAL TABLE verses USING fts5(
        book,
        chapter,
        verse,
        text,
        tokenize = 'porter unicode61 remove_diacritics 2'
    );

""")

db.startTransaction()

let sql = """
    INSERT INTO verses (book, chapter, verse, text) values(?,?,?,?);
"""

let preparedStatement = db.prepare(sql)

let versesUrl = URL(fileURLWithPath: "/Users/savage/Documents/BibleDatabaseImport/dra/verses.tsv")
let verses =  try String(contentsOf: versesUrl)
    .replacingOccurrences(of: "\r\n", with: "\n")
    .split(separator: "\n")

print("Inserting verses...")

for verse in verses {
    if verse.isEmpty {
        continue
    }
    let parts = verse.split(separator: "\t")
    let row = Verse(bookId: Int32(parts[2])!, chapter: Int32(parts[3])!, verse: Int32(parts[4])!, text: String(parts[5]))
    db.insertVerse(preparedStatement, row)
}

sqlite3_finalize(preparedStatement)
db.endTransaction()


while true {
    print("Enter an bible query:")
    let query = readLine()

    if query?.lowercased() == "stop" {
        print("stopping...")
        break
    }

    db.execute("""
        SELECT
            books.name,
            books.abbreviation,
            verses.chapter,
            verses.verse,
            verses.text
        FROM verses
        JOIN books ON books.id = verses.book
        WHERE
            text MATCH "\(query!)"
        LIMIT 3;
    """)
}
