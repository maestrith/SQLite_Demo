#SingleInstance,Force
DB:=New MySQLite()
DB.Open("My DB.db","Testing Password")
DB.Exec("CREATE TABLE IF NOT EXISTS Testing(ID INTEGER,Name,UNIQUE(ID) ON CONFLICT IGNORE)",A_ThisFunc,A_LineNumber)
DB.Exec("INSERT INTO Testing VALUES(1,'Things')",A_ThisFunc "`n" A_LineNumber)
DB.m(DB.Exec("SELECT OID AS OID,* FROM Testing",A_ThisFunc "`n" A_LineNumber))
DB.Insert("Testing",[{ID:1,Name:"New Things 2"}],"ID")
DB.m(DB.Exec("SELECT OID AS OID,* FROM Testing",A_ThisFunc "`n" A_LineNumber))
ExitApp
#Include Lib\Class MySQLite.ahk