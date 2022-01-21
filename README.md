# Convert Quicken Home & Business 2008 (or compatible) register report to either SQLite3 import file or SQL statements.

* Written for [Lua](https://www.lua.org) v5.3.6
* Lua binaries with built-in SQLite3 for [Windows](http://www.aspisys.com/lua.exe) and [Linux i386](http://www.aspisys.com/lua)
* This utility is meant to be used with Quicken Home & Business 2008 or compatible (from now on, Q) register report output.

WARNING: Due to a bug fix, this version uses a slightly different table schema.
         If you have already created the table from the previous version(s),
         first drop the old table with `drop table quicken`.

Instructions
============

1. Start your Q program.
2. Select any account register or just the one you want to export.
3. Select 'Report' from the top right of the register.
4. Select 'Register Report' from the drop-down menu.
5. Select 'Customize' and choose all accounts, categories, payees, tags, ... you're interested in.
   (For a full report, select all in all tabs.)
6. Select the date period you want to export, and press `OK`.
7. Select 'Export Data' from the top left of the pop up window.
8. Select 'Report to Excel compatible format' which will generate a tab-delimited
   text CSV file, and choose an appropriate name for the file,
   such as `c:\temp\report.txt`.
   (Depending on size it could take several minutes.  Your PC may look like it froze.)

Due to an apparent bug in Q, step [8] may produce incorrect output for very large contents.
To overcome this, repeat the above process for smaller non-overlapping [6] periods,
e.g. each year separately, named appropriately (e.g. `2020.txt`), and then combine the
various files using `COPY` like so:

~~~
c:>\temp\>copy 2020.txt+2021.txt+2022.txt report.txt
~~~

At this point you should have a file (report.txt) with the full register report for the
selected period.

9. Run the following command to create the [SQLite3](https://sqlite.org) database table:

```
c:>\temp>lua quicken_register.lua report.txt -sql | sqlite3 quicken.db
```

to get the produced SQLite3 script fed through the SQLite3 shell to
create and populate the required database table.

Special note
============

Unfortunately, the Q exported data does not contain any method of marking a row as unique.
If, for example, you have made two identical transactions on the exact same date, there
is no way to tell which is which.

The implication of that is only important when updating your SQLite3 quicken table with
new data (i.e., an incremental update).  You need to be careful to not cause date range
overlaps because the database will end up with duplicate rows that you won't be able to
know if they are intended duplicates (repeats of the exact same transaction) or an
overlapping import mistake.

You can remedy this by selecting the date range carefully, and possibly deleting rows
from SQLite3 quicken table based on the `dt` field.  Example to delete anything beginning
from 2022 so it can be re-imported without ending up with overlaps:

```
c:>\temp>sqlite3 quicken.db "delete from quicken where dt > '2022'"
```
Then import the new register report that must be date-ranged to start on 2022-01-01.
