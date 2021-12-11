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
6. Select 'Copy report to Clipboard' (depending on size it could take several seconds).

At this point the whole register report is in your clipboard.

7. Open any text editor, such as Sublime Text or PNotepad.
   Make sure tabs (used to separate columns) are NOT converted to spaces by your editor options.
8. Paste the clipboard into the editor.
9. Save the file (example: report.txt).

Alternatively, and to avoid possible tab conversion issues,
at the `c:\temp>` (example directory) command line prompt,
you could replace [7]-[9] above with the following steps:

7. Type `copy con > report.txt`
8. `Mouse right-click` to paste your clipboard content.
9. Press `[CTRL-Z]` followed by `[ENTER]` to end the file.

(This method should preserve tabs and not change them to spaces.)

At this point you have a file (report.txt) with the register report.

10. Run the following command to create the SQLite3 database table:

```
c:>\temp>lua quicken_register.lua report.txt -sql | sqlite3 quicken.db
```

to get the produced SQLite3 script fed through the SQLite3 shell to
create and populate the required database table.

You can repeat the above process for each Q account you want to transfer
to SQLite3.  All accounts will end up in the same table but can be distinguished
by the `acct` field.
