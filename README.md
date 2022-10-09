# Bible Database Import

The bible database importer will take tab separated tables and import them into an SQLite database file. Bible verses are inserted into a virtual full text search table which tokenizes the verses into a B-Tree within a single transaction. Because all the verses are inserted in the same transaction, the B-Tree is automatically balanced.

## Input File Formats

**books.tsv**

- book number
- book name
- abbreviation of the book name

```text
1	Genesis	Gen
```

**verses.tsv**

The format for `verses.tsv` matches the source data used in bontibon's KJV project ([bontibon/kjv](https://github.com/bontibon/kjv)).

- book name
- abbreviation of the book name
- book number
- chapter number
- verse number

```text
Genesis	Gen	1	1	1	In the beginning God created heaven, and earth.
```

# License
This script is in the public domain.
