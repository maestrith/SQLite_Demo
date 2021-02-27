Class MySQLite{
	static Init:=0,Keep:=[]
	__New(){
		if(!MySQL.Init){
			SQLFile:=FileExist(FF:=A_ScriptDir "\SQLite3.dll")?FF:A_MyDocuments "\AutoHotkey\Lib\SQLite3.dll",this.Create:=[]
			if(!(DLL:=DllCall("LoadLibrary","Str",SQLFile,"UPtr"))){
				this.m("File: " SQLFile " does not exist. Exiting")
				ExitApp
			}
			this.DLL:=DLL,MySQL.Init:=1,MySQL.Keep[Object(this)]:=this,this.ColTypes:=[],this.ErrorObj:=[]
			this.Bin2String:=DllCall("GetProcAddress",Ptr,DllCall("LoadLibrary","Str","Crypt32.dll","UPtr"),AStr,"CryptBinaryToStringW")
			for a,b in {ColType:"sqlite3_column_type",Step:"sqlite3_step",ColBlob:"sqlite3_column_blob"
					 ,ColBytes:"sqlite3_column_bytes",ColText:"sqlite3_column_text",ColName:"sqlite3_column_name"
					 ,Prepare:"sqlite3_prepare_v2",ColCount:"sqlite3_column_count"
					 ,BindText:"sqlite3_bind_text16"}
				this[a]:=DllCall("GetProcAddress",Ptr,this.DLL,AStr,b)
			
			
			return this
	}}Clean(Text:="",Wrap:="'",Empty:=0){
		static WrapChar:={(Chr(34)):{Wrap:Chr(34),Regex:"(\x22)"},"[":"]","'":{Regex:"(')",Wrap:"'"},"[":{Regex:"(\[|\])",Wrap:"]"}}
		if(Text=""||Text="NULL")
			return (Empty?"''":"NULL")
		Text:=RegExReplace(Text,WrapChar[Wrap].Regex,"$1$1")
		return Wrap Text WrapChar[Wrap].Wrap
	}Close(){
		DllCall("SQlite3.dll\sqlite3_close_v2",PTR,this.Handle)
	}CreatePWFile(File,Password){
		Flag:=6
		RC:=DllCall("SQlite3.dll\sqlite3_open_v2","AStr",":memory:","PtrP",HDB,"Int",Flag,"Ptr",0,"CdeclInt")
		this.Handle:=HDB
		this.Exec(Foo:="ATTACH DATABASE " this.Clean(File) " AS 'Foo' KEY " this.Clean(Password),A_ThisFunc "`n" A_LineNumber)
		this.Exec("DETACH DATABASE Foo",A_LineNumber)
		this.Close()
		this.Open(File)
		this.Exec("PRAGMA KEY=" this.Clean(Password),1)
	}CreateTable(Table,Columns,Unique:="",Conflict:="IGNORE",Temp:=0){
		for a,b in StrSplit(Columns,",")
			RegExMatch(b,"Oi)(\s+\b(INT|INTEGER|NULL|REAL|TEXT|BLOB)\b)",Found),Col.=this.Clean(RegExReplace(b,Found.1)) Found.1 ","
		for a,b in StrSplit(Unique,",")
			UU.=this.Clean(b) ","
		Col.=(Unique?"UNIQUE(" Trim(UU,",") ")":"") (Conflict&&Unique?" ON CONFLICT " Conflict:"")
		this.Exec("CREATE " (Temp?" TEMPORARY ":"") "TABLE IF NOT EXISTS " this.Clean(Table) "(" Trim(Col,",") ")",A_ThisFunc,A_LineNumber)
	}ErrMsg(RC:="",Extra*){
		if(Extra.1="No`n")
			return
		for a,b in Extra
			MsgLine.=b "`n"
		MsgLine.=(RC+0!=""||RC=""?StrGet(DllCall("SQLite3.dll\sqlite3_errstr",Int,(RC?RC:DllCall("SQLite3.dll\sqlite3_extended_errcode",PTR,this.Handle))),"UTF-8"):RC)
		RC:=DllCall("SQLite3.dll\sqlite3_errmsg","Ptr",this.Handle,"CdeclUPtr")
		if(RC)
			MsgLine.=StrGet(RC,"UTF-8")
		this.ErrorObj.Push(MsgLine)
		MsgBox,% MsgLine "`n`n" this.SQL
	}Exec(SQL,Extra*){
		local
		static
		Debug:=""
		for a,b in Extra
			Debug.=b "`n"
		/*
			m("Function: " A_ThisFunc,"Line: " A_LineNumber,"",SQL)
		*/
		this.OO:=[],this.EA:=[],this.ErrorMsg:="",this.ErrorCode:=0,this.SQL:=SQL,this.UTF8(SQL,UTF8)
		if(RC:=DllCall(this.Prepare,"Ptr",this.Handle,"Ptr",&UTF8,"Int",-1,"PtrP",Query,"Ptr",0,"CdeclInt"))
			return this.ErrMsg(RC,Debug)
		Col:=[],Obj:=[],this.OO:=[],this.OO.Col:=[]
		while(StrPtr:=DllCall(this.ColName,"Ptr",Query,"Int",A_Index-1,"CdeclUPtr"))
			Col.Push(CC:=StrGet(StrPtr,"UTF-8")),this.OO.Col.Push(CC)
		this.SQL:=SQL
		/*
			if(SQL~="i)INSERT INTO MyTable"){
				return Query
			}
		*/
		while(DllCall(this.Step,"Ptr",Query,"CdeclInt")=100){
			Obj.Push(OO:=[])
			for a,b in Col{
				ColumnType:=DllCall(this.ColType,"Ptr",Query,"Int",(Column:=a-1),"CdeclInt")
				if(ColumnType=4){
					Ptr:=DllCall(this.ColBlob,"Ptr",Query,"Int",Column,"CdeclUPtr"),Bytes:=DllCall(this.ColBytes,"Ptr",Query,"Int",Column,"CdeclInt")
					if(this.BlobType="Base64"){
						Enc:=0x40000001
						DllCall(this.Bin2String,"Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						VarSetCapacity(Base64,CP*(A_IsUnicode?2:1))
						DllCall(this.Bin2String,"ptr",PTR,"uint",Bytes,"uint",Enc,"str",Base64,"uint*",CP)
						OO[b]:=Base64
					}else if(this.BlobType="ByteArray"){
						Enc:=2
						DllCall(this.Bin2String,"Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						ByteArray:=ComObjArray(0x11,CP)
						PP:=NumGet(ComObjValue(ByteArray)+8+A_PtrSize)
						DllCall(this.Bin2String,"ptr",PTR,"uint",Bytes,"uint",Enc,"Ptr",PP,"uint*",CP)
						OO[b]:=ByteArray
					}else if(this.BlobType="hBitmap"){
						VectorImage:=ComObjCreate("WIA.Vector")
						Enc:=2
						DllCall(this.Bin2String,"Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						ByteArray:=ComObjArray(0x11,CP)
						PP:=NumGet(ComObjValue(ByteArray)+8+A_PtrSize)
						DllCall(this.Bin2String,"ptr",PTR,"uint",Bytes,"uint",Enc,"Ptr",PP,"uint*",CP)
						VectorImage.BinaryData:=ByteArray
						Picture:=VectorImage.Picture
						hBM:=Picture.Handle
						OO[b]:=hBM
					}else{
						Enc:=2
						Count:=0
						OO[b]:=this.BlobType="Text"?"File: " Bytes " Bytes":{PTR:PTR,Size:Bytes}
				}}else if(ColumnType=5)
					OO[b]:=""
				else
					StrPtr:=DllCall(this.ColText,"Ptr",Query,"Int",Column,"CdeclUPtr"),OO[b]:=StrGet(StrPtr,"UTF-8")
			}
		}this.EA:=Obj
		return Obj
	}Exit(){
		Ret:=DllCall("FreeLibrary","UPtr",this.DLL)
		ExitApp
	}GetBlob(SQL,Type:="Base64"){ ;Based HEAVILY on https://www.autohotkey.com/boards/viewtopic.php?f=6&t=1064
		local
		static
		this.UTF8(SQL,UTF8),DllCall("SQlite3.dll\sqlite3_prepare_v2","Ptr",this.Handle,"Ptr",&UTF8,"Int",-1,"PtrP",Query,"Ptr",0,"CdeclInt"),DllCall("SQlite3.dll\sqlite3_column_count","Ptr",Query,"CdeclInt"),Col:=[],Obj:=[]
		while(StrPtr:=DllCall("SQlite3.dll\sqlite3_column_name","Ptr",Query,"Int",A_Index-1,"CdeclUPtr"))
			Col.Push(StrGet(StrPtr,"UTF-8"))
		while(DllCall("SQlite3.dll\sqlite3_step","Ptr",Query,"CdeclInt")=100){
			Obj.Push(OO:=[])
			for a,b in Col{
				ColumnType:=DllCall("SQlite3.dll\sqlite3_column_type","Ptr",Query,"Int",(Column:=a-1),"CdeclInt")
				if(ColumnType=4){
					Ptr:=DllCall("SQlite3.dll\sqlite3_column_blob","Ptr",Query,"Int",Column,"CdeclUPtr")
					Bytes:=DllCall("SQlite3.dll\sqlite3_column_bytes","Ptr",Query,"Int",Column,"CdeclInt")
					if(Type="Base64"){
						Enc:=0x40000001
						DllCall("Crypt32.dll\CryptBinaryToString","Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						VarSetCapacity(Base64,CP*(A_IsUnicode?2:1))
						DllCall("Crypt32.dll\CryptBinaryToString","ptr",PTR,"uint",Bytes,"uint",Enc,"str",Base64,"uint*",CP)
						OO[b]:=Base64
					}else if(Type="ByteArray"){
						Enc:=2
						DllCall("Crypt32.dll\CryptBinaryToString","Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						ByteArray:=ComObjArray(0x11,CP)
						PP:=NumGet(ComObjValue(ByteArray)+8+A_PtrSize)
						DllCall("Crypt32.dll\CryptBinaryToString","ptr",PTR,"uint",Bytes,"uint",Enc,"Ptr",PP,"uint*",CP)
						OO[b]:=ByteArray
					}else if(Type="hBitmap"){
						VectorImage:=ComObjCreate("WIA.Vector")
						Enc:=2
						DllCall("Crypt32.dll\CryptBinaryToString","Ptr",PTR,"uint",Bytes,"uint",Enc,"ptr",0,"uint*",CP)
						ByteArray:=ComObjArray(0x11,CP)
						PP:=NumGet(ComObjValue(ByteArray)+8+A_PtrSize)
						DllCall("Crypt32.dll\CryptBinaryToString","ptr",PTR,"uint",Bytes,"uint",Enc,"Ptr",PP,"uint*",CP)
						VectorImage.BinaryData:=ByteArray
						Picture:=VectorImage.Picture
						hBM:=Picture.Handle
						OO[b]:=hBM
					}else
						OO[b]:={PTR:PTR,Size:Bytes}
				}else if(ColumnType=5)
					OO[b]:=""
				else
					StrPtr:=DllCall("SQlite3.dll\sqlite3_column_text","Ptr",Query,"Int",Column,"CdeclUPtr"),OO[b]:=StrGet(StrPtr,"UTF-8")
			}
		}return Obj
	}GetColumns(Table){
		Columns:=[]
		for a,b in this.Exec("PRAGMA table_info(" this.Clean(Table) ")")
			Columns[b.Name]:=1
		return Columns
	}GetColTypes(Table,AttachedDB:=""){
		Obj:=(CT:=this.ColTypes[Table])?CT:this.ColTypes[Table]:=[]
		for a,b in this.Exec(Foo:="PRAGMA "(AttachedDB?AttachedDB ".":"")"table_info(" this.Clean(Table) ")")
			Obj[b.Name]:=(b.Type?b.Type:"Any")
		return Obj
	}Insert(Table,Obj,Unique:="",NoQuote:="",AttachedDB:=""){
		CurrentColumns:=this.GetColTypes(Table,AttachedDB),Columns:=[],NQ:=[],AddCol:=[]
		if(!Obj.1)
			return
		for a,b in StrSplit(NoQuote,",")
			NQ[b]:=1
		for a,b in Obj{
			for c,d in b{
				Columns[c]:=1,CurrentColumns[c]?"":(AddCol.Push(c),CurrentColumns[c]:=1)
			}
		}
		for a,b in AddCol{
			this.Exec(Foo:="ALTER TABLE "(AttachedDB?AttachedDB ".":"")this.Clean(Table)" ADD COLUMN " this.Clean(b),A_LineNumber,A_LineFile,Foo)
		}
		for a,b in Obj{
			Col:=""
			for c,d in Columns{
				Val.=(NQ[c]?b[c]:this.Clean(b[c],,1)) ",",Col.=this.Clean(c) ","
				if(!Init)
					Row.=this.Clean(c) "=excluded." this.Clean(c) ","
			}Init:=1,TotalValues.="(" Trim(Val,",") "),",Val:=""
		}for a,b in StrSplit(Unique,",")
			UU.=this.Clean(b,Chr(34)) ","
		this.Exec(Foo:="INSERT INTO "(AttachedDB?AttachedDB ".":"")this.Clean(Table) "(" Trim(Col,",") ") VALUES " Trim(TotalValues,",") (Unique?" ON CONFLICT(" Trim(UU,",") ") DO UPDATE SET " Trim(Row,","):""),A_LineNumber "`n" A_ThisFunc)
		/*
			t(Clipboard:=Foo)
		*/
	}m(x*){
		for a,b in x
			Msg.=(IsObject(b)?this.Obj2String(b):b)"`n"
		MsgBox,%Msg%
	}Obj2String(Obj,FullPath:=1,BottomBlank:=0){
		static String,Blank
		if(FullPath=1)
			String:=FullPath:=Blank:=""
		Try{
			if(Obj.XML){
				String.=FullPath Obj.XML "`n",Current:=1
			}
		}
		Try{
			if(Obj.OuterHtml){
				String.=FullPath Obj.OuterHtml "`n",Current:=1
			}
		}if(!Current){
			if(IsObject(Obj)){
				for a,b in Obj{
					if(IsObject(b)&&b.OuterHtml)
						String.=FullPath "." a " = " b.OuterHtml "`n"
					else if(IsObject(b)&&!b.XML)
						Obj2String(b,FullPath "." a,BottomBlank)
					else{
						if(BottomBlank=0)
							String.=FullPath "." a " = " (b.XML?b.XML:b) "`n"
						else if(b!="")
							String.=FullPath "." a " = " (b.XML?b.XML:b) "`n"
						else
							Blank.=FullPath "." a " =`n"
					}
				}
			}
		}	
		return String Blank
	}Open(File,Password:="",Flag:=6,Debug:=1){
		SplitPath,File,,Dir,Ext,NNE
		if(FileExist(FF:=(Dir:=Dir?Dir "\":A_ScriptDir "\") NNE " Password.txt"))
			FileRead,Password,%FF%
		if(Password&&!FileExist(File))
			return this.CreatePWFile(File,Password)
		DllCall("SQlite3.dll\sqlite3_enable_shared_cache",Int,1)
		this.UTF8(Dir NNE "." Ext,UTF8)
		Flag|=0x00020000
		RC:=DllCall("SQlite3.dll\sqlite3_open_v2","Ptr",&UTF8,"PtrP",HDB,"Int",Flag,"Ptr",0,"CdeclInt")
		if(ErrorLevel)
			return False,this._Path:="",this.ErrorMsg:="DLLCall sqlite3_open_v2 failed!",this.ErrorCode:=ErrorLevel,(Debug?this.m("Path: " this._Path,"Error Message: " this.ErrorMsg,"Error Code: " this.ErrorCode):"")
		if(RC)
			return False,this._Path:="",this.ErrorMsg:=this.ErrMsg(),this.ErrorCode:=RC,(Debug?this.m("Path: " this._Path,"Error Message: " this.ErrorMsg,"Error Code: " this.ErrorCode):"")
		this.Handle:=HDB
		this.Exec("PRAGMA busy_timeout=4000")
		if(Password){
			this.Exec("PRAGMA KEY=" this.Clean(Password))
			if(!this.Exec("PRAGMA encoding").1.Encoding)
				return this.m("Database is not secure"),this.Close()
		}return 1
	}ProcessQuery(Columns,ColumnText,ColumnNames){
		static Count:=0
		this:=MySQL.Keep[this],OO:=this.OO
		if(!OO.Columns){
			OO.Col:=[]
			Loop,%Columns%
				Col:=StrGet(NumGet(ColumnNames+((A_Index-1)*A_PtrSize)),"UTF-8"),Col:=Col="OID"?"OID":Col,OO.Columns.="|" Col,OO.Col.Push(Col)
			OO.Columns:=Trim(OO.Columns,"|")
		}if(!IsObject(OO.Values))
			OO.Values:=[],this.EA:=[]
		OO.Values.Push(Obj:=[]),this.EA.Push(EA:=[])
		for a,b in OO.Col
			EA[b]:=StrGet(NumGet(ColumnText+((A_Index-1)*A_PtrSize)),"UTF-8"),Obj.Push(Value:=StrGet(NumGet(ColumnText+((A_Index-1)*A_PtrSize)),"UTF-8")) ;,EA[b]:=Value
	}StoreBlob(SQL,Array){ ;Based HEAVILY on https://www.autohotkey.com/boards/viewtopic.php?f=6&t=1064
		this.SQL:=SQL
		SQLITE_STATIC:=0
		this.UTF8(SQL,UTF8)
		RC:=DllCall(this.Prepare,"Ptr",this.Handle,"Ptr",&UTF8,"Int",-1,"PtrP",Query,"Ptr",0,"CdeclInt")
		if(ErrorLevel||RC)
			return 0,(RC?(this.ErrorMsg:=A_ThisFunc ": " this.ErrMsg(RC,A_ThisFunc)):(this.ErrorMsg:=A_ThisFunc ": DllCall sqlite3_prepare_v2 failed!`nError Code: " ErrorLevel)),this.ErrorCode:=(RC?RC:ErrorLevel),this.m(this.ErrorMsg,(this.ErrorCode+0?"":this.ErrorCode))
		for BlobNum,Blob in Array{
			if(!(Blob.Addr) || !(Blob.Size)){
				this.ErrorMsg := A_ThisFunc ": Invalid parameter BlobArray!"
				this.ErrorCode := ErrorLevel
				Continue
			}
			RC:=DllCall("SQlite3.dll\sqlite3_bind_blob","Ptr",Query,"Int",BlobNum,"Ptr",Blob.Addr,"Int",Blob.Size,"Ptr",SQLITE_STATIC,"CdeclInt")
			if(ErrorLevel){
				this.ErrorMsg := A_ThisFunc ": DllCall sqlite3_bind_blob failed!"
				this.ErrorCode := ErrorLevel
				return 0
			}
			if(RC){
				this.ErrorMsg := A_ThisFunc ": " this.ErrMsg()
				this.ErrorCode := RC
				return 0
			}
		}
		RC:=DllCall("SQlite3.dll\sqlite3_step","Ptr",Query,"CdeclInt")
		if(ErrorLevel){
			this.ErrorMsg := A_ThisFunc ": DllCall sqlite3_step failed!"
			this.ErrorCode := ErrorLevel
			this.m(this,"","Here")
			return 0
		}
		if((RC) && (RC <> 101)){
			this.ErrorMsg := A_ThisFunc ": " this.ErrMsg()
			this.ErrorCode := RC
			return 0
		}
		RC := DllCall("SQlite3.dll\sqlite3_finalize", "Ptr", Query, "Cdecl Int")
	}Table(Table,ColumnsWithUnique:="",Temporary:=0,Extra:=""){
		static Tables,Columns:=[]
		if(!IsObject(Tables)){
			Tables:=[]
			for a,b in this.Exec("SELECT name FROM sqlite_master WHERE type='table'",1)
				Tables[b.Name]:=1
		}if(SQL=0)
			return this.Exec("DROP TABLE " this.Clean(Table))
		else if(!SQL)
			return this.Create[Table]
		if(SQL=1)
			return Columns[Table]
		if(!Columns[Table])
			Columns[Table]:=RegExReplace(RegExReplace(RegExReplace(SQL,",UNIQUE\(.*")," PRIMARY KEY")," INTEGER")
		this.Create[Table]:=SQL
		if(!Tables[Table]){
			this.Exec("CREATE " (Temporary?"TEMPORARY":"") " TABLE IF NOT EXISTS " this.Clean(Table) "(" SQL ")" Extra,1)
			if(!Temporary)
				this.m("Function: " A_ThisFunc,"Label: " A_ThisLabel,"Line: " A_LineNumber,"`n`n",this.SQL)
		}
	}UTF8(String,ByRef UTF8){
		VarSetCapacity(UTF8,StrPut(String,"UTF-8")),StrPut(String,&UTF8,"UTF-8")
		return UTF8
	}Upsert(Table,Columns,SQL){
		for c,d in StrSplit(this.GetUnique(Table),",")
			Excluded.=this.Clean(d)"=excluded."this.Clean(d)","
		for a,b in StrSplit(Columns,",")
			ConflictList.=this.Clean(b,Chr(34))","
		Foo:="INSERT INTO "this.Clean(Table)"("(Columns)") "(SQL)" ON CONFLICT("Trim(ConflictList,",")") DO UPDATE SET "Trim(Excluded,",")
		this.Exec(Foo,A_ThisFunc "`n" A_LineNumber)
	}GetUnique(Table){
		RegExMatch(this.Exec("SELECT * FROM sqlite_master WHERE name="this.Clean(Table)" AND type='table'",A_ThisFunc "`n" A_LineNumber).1.SQL,"OUi)UNIQUE\((.*)\)",Found)
		return Found.1
	}
	Clear(){
		this.PassObj:=[]
	}
	Push(Obj){
		for a,b in Obj{
			if(A_Index=1&&!this.PassObj.1){
				this.ColWidth:=Obj.Count()
				for a,b in Obj
					this.CCC.=a ","
			}if(Obj.Count()!=this.ColWidth){
				this.m("DIFFERENT WIDTHS, Send it!",this.PassObj)
				
				
				this.Exec(Foo:="INSERT INTO " this.Clean(Table) "(" Trim(Col,",") ") VALUES " Trim(TotalValues,",") (Unique?" ON CONFLICT(" Trim(UU,",") ") DO UPDATE SET " Trim(Row,","):""),A_LineNumber "`n" A_ThisFunc)
				
				
			}
			this.PassObj.Push(Obj)
		}
	}
	UTF16(String){
		static UTF8
		VarSetCapacity(UTF8,StrPut(String,"UTF-16")),StrPut(String,&UTF8,"UTF-16")
		return &UTF8
	}	
	
}