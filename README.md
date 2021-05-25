# Convert Quicken Home & Business 2008 or compatible register report to either SQLite3 import file or SQL statements.

* Written for Lua v5.3.6
* This utility is meant to be used with Quicken Home & Business 2008 or compatible (from now on, Q) register report output.

Instructions
============

1. Start your Q program.
2. Select the account register you want to export.
3. Select 'Report' from the top right of the register.
4. Select 'Register Report' from the drop-down menu.
5. Select 'Export Data' from the top left of the pop up window.
6. Select 'Copy report to Clipboard'

At this point the whole register report is in your clipboard.

7. Open any text editor, such as Sublime Text or PNotepad.
8. Paste the clipboard into the editor.
9. Save the file (example: report.txt).

At this point you have a file with the register report.

10. Run the following commands (assuming you're in some c:\temp directory) to create the SQLite3 database table:

```
c:>\temp>lua quicken_register.lua report.txt > import.txt
c:>\temp>sqlite3 quicken.db
sqlite>CREATE TABLE IF NOT EXISTS quicken(
   ...>  dt text not null default(date())
   ...>    check (dt is date(dt,'+0 days')),
   ...>  acct text not null collate nocase,
   ...>  num text collate nocase,
   ...>  payee text not null collate nocase,
   ...>  memo text collate nocase,
   ...>  category text collate nocase,
   ...>  clr text collate nocase,
   ...>  amount float not null
   ...>  );
sqlite>.import quicken import.txt
```

to import to a new SQLite3 database, or

```
c:>\temp>lua quicken_register.lua report.txt -sql | sqlite3 quicken.db
```

to get the produced SQLite3 script fed through the SQLite3 shell to create database and populate the required table.
