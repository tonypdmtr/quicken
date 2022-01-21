--==============================================================================
-- Convert Quicken Home & Business 2008 register report export via clipboard
-- to some text file into SQLite3 .import ready file for quicken table
-- Written by Tony G. Papadimitriou <tonyp@acm.org> on 2021-05-25
-- Placed in the Public Domain
-- History --
-- 2021-05-25 Original
-- 2022-01-20 BugFix: SQL version did not include memo field
--            BugFix: SQL version did not use CREATE_SQL constant
--            Split pattern (PAT) into multiple lines for readability
--            Made tab pattern a separate constant (TAB) for easier editing, if needed
--            Attempted UNIQUE constraint but left as comment as exported file is not necessarily unique
--==============================================================================

CREATE_SQL = [[
CREATE TABLE IF NOT EXISTS quicken(
  dt text not null default(date())                --date of event
    check (dt is date(dt,'+0 days')),
  acct text not null collate nocase,              --account to use
  num text collate nocase,                        --transaction number
  payee text not null collate nocase,             --payee
  memo text null collate nocase,                  --memo
  tag text null collate nocase,                   --tag
  category text null collate nocase,              --category
  clr text null collate nocase,                   --cleared payment flag
  amount float not null                           --signed amount
  --, unique (dt,acct,payee,memo,tag,category,amount)
  );
]]

TAB = '[\t|]'
PAT = '^'..TAB..
      '(%d+/%d+/%d+)'..TAB..        --dt
      '(.-)'..TAB..                 --accnt
      '(.-)'..TAB..                 --num
      '(.-)'..TAB..                 --payee
      '(.-)'..TAB..                 --memo
      '(.-)'..TAB..                 --category
      '(.-)'..TAB..                 --tag
      '(.-)'..TAB..                 --clr
      '(%-?%d-%,?%d+%.%d%d)%s*$'    --amount
EOL = '~~~LF~~~'
DELIMITER = '|'

filename = arg[1]

as_sql = arg[2] ~= nil and arg[2]:upper() == '-SQL'
if not as_sql and arg[2] ~= nil then
  print(f'ERROR: Unexpected argument "{arg[2]}"')
  return
end

--------------------------------------------------------------------------------

local
function is_num(s)
  return s:match '^%-?%d-%,?%d+%.%d%d$' ~= nil
end

--------------------------------------------------------------------------------

local
function n(s)
  if s == nil or s == '' then return 'NULL' end
  if is_num(s) then return s end
  return "'" .. s:gsub("'","''") .. "'"
end

--------------------------------------------------------------------------------

local
function pl()
  if ans == nil or ans.dt == nil then return end
  if as_sql then
    ans.dt = n(ans.dt)
    ans.acct = n(ans.acct)
    ans.num = n(ans.num)
    ans.payee = n(ans.payee)
    ans.memo = n(ans.memo)
    ans.category = n(ans.category)
    ans.tag = n(ans.tag)
    ans.clr = n(ans.clr)
    ans.amount = n(ans.amount)
    print(f'INSERT INTO quicken VALUES({ans.dt},{ans.acct},{ans.num},{ans.payee},{ans.memo},{ans.category},{ans.tag},{ans.clr},{ans.amount});')
  else
    print(ans.dt .. DELIMITER ..
          ans.acct .. DELIMITER ..
          ans.num .. DELIMITER ..
          ans.payee .. DELIMITER ..
          ans.memo .. DELIMITER ..
          ans.category .. DELIMITER ..
          ans.tag .. DELIMITER ..
          ans.clr .. DELIMITER ..
          ans.amount)
  end
  ans = {}
end

--------------------------------------------------------------------------------

function do_work()
  local count = 0
  for line in io.lines(filename) do
    local dt,acct,num,payee,memo,category,tag,clr,amount = line:match(PAT)
    if (dt == 'dt' or dt == 'Date') and
       (acct == 'acct' or acct == 'Account') and
       (num == 'num' or num == 'Num') and
       (payee == 'payee' or payee == 'Description') and
       (memo == 'memo' or memo == 'Memo') and
       (category == 'category' or category == 'Category') and
       (tag == 'tag' or tag == 'Tag') and
       (clr == 'clr' or clr == 'Clr') and
       (amount == 'amount' or amount == 'Amount') then
      print(f'dt{DELIMITER}acct{DELIMITER}num{DELIMITER}payee{DELIMITER}memo{DELIMITER}category{DELIMITER}tag{DELIMITER}clr{DELIMITER}amount')
      goto CONTINUE
    end
    if amount == nil then goto CONTINUE end
    amount = amount:gsub(',','')        --remove possible thousands commas
    if dt ~= nil then
      if dt == '' then
        --print(line)
        if ans == nil then return end
        if payee ~= '' then ans.payee = ans.payee .. EOL .. payee end
        if memo ~= '' then ans.memo = ans.memo .. EOL .. memo end
        if category ~= '' then ans.category = ans.category .. EOL .. category end
        if amount ~= '' then ans.amount = ans.amount + amount end
      else
        pl()
        dt = { dt:match '(%d+)/(%d+)/(%d+)' }
        if dt[1] == nil then goto CONTINUE end
        dt = f'{dt[3]}-{dt[2]::%02i}-{dt[1]::%02i}'
        ans = {}
        ans.dt = dt
        ans.acct = acct
        ans.num = num
        ans.payee = payee
        ans.memo = memo
        ans.category = category
        ans.tag = tag
        ans.clr = clr
        ans.amount = amount
      end
    end
  ::CONTINUE::
  end
end

--==============================================================================

if filename == nil then print([[
Usage: quicken_register.lua filename [-SQL]
       Convert Quicken Home & Business 2008
       register report exported via clipboard
       to some text file into SQLite3 .import
       ready file for quicken table with schema:
-----------------------------------------------------------------
DROP TABLE IF EXISTS quicken;
]] .. CREATE_SQL .. [[
-----------------------------------------------------------------
       If present, the -SQL flag will cause output as SQLite3
       compatible INSERT statements wrapped in a single transaction.
]])

  return
end

--------------------------------------------------------------------------------
if as_sql then print(CREATE_SQL .. 'BEGIN;') end
do_work()
pl()
if as_sql then print('END;') end
--==============================================================================
