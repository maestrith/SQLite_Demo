MsgBox,% m("Nice","btn:ari")
MsgBox
ExitApp
/*
	Add an Input method{
		make it able to track Checkbox,Radio, and Edit Type Inputs
	}
*/
m(x*){
	static Buttons:={YNC:"Yes,No,Cancel",YN:"Yes,No",OC:"OK,Cancel",ARI:"Abort,Retry,Ignore"}
	m:=New MsgBox(),Default:=1
	for a,b in x{
		Cmd:=StrSplit(b,":")
		if(Cmd.1="Btn")
			Btn:=Buttons[Cmd.2]
		else if(Cmd.1="HTML"){
			HTML:=1
		}else if(Cmd.1="Def"){
			Default:=Cmd.2
		}else{
			Msg.=IsObject(b)?Obj2String(b):b "`r`n"
		}
	}
	m[HTML?"SetHTML":"SetText"](Msg)
	if(Btn)
		m.SetButtons(Btn)
	return m.Show("Win",Default)
}
/*
	Obj2String(Obj,FullPath:=1,BottomBlank:=0){
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
	}
*/
Class MsgBox{
	static Keep:=[]
	_Event(Name,Event){
		local
		static
		Node:=Event.srcElement
		CTRL:=this
		if(Name="MouseDown"){
			Mode:=A_CoordModeMouse,Delay:=A_WinDelay
			SetWinDelay,-1
			CoordMode,Mouse,Screen
			if(Node.ID="Title"){
				MouseGetPos,XX,YY
				WinGetPos,X,Y,,,% this.ID
				OffX:=XX-X,OffY:=YY-Y,LastX:=XX,LastY:=YY
				while(GetKeyState("LButton")){
					MouseGetPos,X,Y
					if(LastX!=X||LastY!=Y)
						WinMove,% this.ID,,% X-OffX,% Y-OffY
					LastX:=X,LastY:=Y
					Sleep,20
				}
			}
			CoordMode,Mouse,%Mode%
			SetWinDelay,%Delay%
		}else if(Name="OnClick"){
			if(Node.ID="Close"){
				this.ResultValue:=Chr(127)
				Gui,% this.Win ":Destroy"
			}else if(Node.ID="Settings"){
				return m("Settings Coming Soon")
				TT:=this
				SetTimer,ShowSettingsWindow,-1
				return
				ShowSettingsWindow:
				Gui,MsgBoxSettings:Destroy
				Gui,MsgBoxSettings:Default
				Gui,Color,0,0
				Gui,Font,c0xAAAAAA
				Gui,Add,Text,,% "Settings For: " TT.ParentTitle
				Gui,Show
				return
			}else if(Node.ID="Testing"){
				this.ResultValue:=Node.Value
			}if(Node.NodeName="Button"){
				this.ResultValue:=Node.Value
			}
		}
	}__New(Options:=""){
		local
		global MsgBox
		static wb
		Default:=A_DefaultGui
		Win:="MyMsgBox" A_TickCount
		WinGetActiveTitle,Title
		Gui,%Win%:Destroy
		Gui,%Win%:Default
		Gui,-Caption +HWNDMain +LabelMsgBox. ;+Resize
		Gui,Margin,0,0
		WinGet,HWND,ID,A
		Ver:=this.FixIE(11)
		MsgBox.Keep[Main]:=this
		Gui,Add,ActiveX,vwb HWNDIE,mshtml
		this.FixIE(Ver),this.Owner:=HWND,this.HWND:=IE,this.Win:=Win,this.ParentTitle:=Title,this.ID:="ahk_id" Main+0,this.KeyResult:=[],this.BoundResult:=this.Result.Bind(this),this.CSS:=[]
		RegRead,CheckReg,HKCU\SOFTWARE\Microsoft\Windows\DWM,ColorizationColor
		Color:=(CC:=SubStr(Format("{:x}",CheckReg+0),-5))?CC:"AAAAAA",this.ThemeColor:="#" Color,wb.Navigate("About:Blank")
		for a,b in {Border:DllCall("GetSystemMetrics",Int,33,Int)-1}
			this[a]:=b
		Gui,Color,% "0x" Color,% "0x" Color
		for a,b in {Color:"Grey",Background:"#000000"}
			this[a]:=b
		for a,b in Options
			this[a]:=b
		IconCode:=(II:=Icons[this.Icon]).Code
		while(wb.ReadyState!=4)
			Sleep,10
		this.Doc:=wb.Document,Master:=this.CreateElement("Div",,"-MS-User-Select:None;Margin:0px;Width:100%","Master"),Root:=this.CreateElement("Div",Master,"","Root"),this.Doc.Body.SetAttribute("Style","Background-Color:" this.Background ";Margin:0px;Display:Flex"),this.NormalCSS:=[],this.ButtonCSS:=[],Style:=this.Doc.Body.Style
		for a,b in {ScrollBarBaseColor:this.Background,ScrollBarFaceColor:this.ThemeColor,ScrollBarArrowColor:this.ThemeColor,ScrollBarTrackColor:this.Background}
			Style[a]:=b
		Outer:=this.CreateElement("Div",Root,,"Outer"),this.Outer:=Outer,Header:=this.CreateElement("Div",Outer,"Cursor:Move;Width:100%","Header")
		for a,b in [["Title","Div",Header,"Float:Left;Align-Items:Center;-MS-User-Select:None;text-overflow:ellipsis;overflow:hidden;white-space:nowrap;","Window Title"]
				 ,["Settings","Div",Header,"Position:Absolute;Float:Left;Cursor:Hand;Background-Color:Pink;Display:Flex;Justify-Content:Center;Align-Items:Center;Color:Black;-MS-User-Select:None","S"]
				 ,["Close","Div",Header,"Position:Absolute;Float:Left;Cursor:Hand;Background-Color:Red;Display:Flex;Justify-Content:Center;Align-Items:Center;Color:Black;-MS-User-Select:None","X"]]
			New:=this.CreateElement(b.2,b.3,b.4),New.ID:=b.1,New.InnerText:=b.5,New.SetAttribute("Class","Header")
		Icon:=this.CreateElement("Div",Master,"Display:Inline-Block;Padding-Left:4px;Padding-Right:4px;User-Select:Text;Float:Left;Justify-Content:Center;Align-Items:Center","Icon"),Icon.SetAttribute("Class","Icon"),this.Text:=this.CreateElement("Div",Master,"Display:Block;OverFlow:Auto;-MS-User-Select:Text;White-Space:NoWrap","Text")
		if(II.Color!="")
			Icon.Style.Color:=II.Color
		this.Text.SetAttribute("Class","Text")
		Hotkey,IfWinActive,% this.ID
		for a,b in {Esc:this.Escape.Bind(this),Space:(Enter:=this.Enter.Bind(this)),Enter:Enter
				 ,Left:(Arrows:=this.Arrows.Bind(this)),Right:Arrows,Up:Arrows,Down:Arrows}
			Hotkey,%a%,%b%,On
		this.ButtonDiv:=this.CreateElement("Div",Master,,"Buttons"),this.SetButtons(),this.CreateElement("Div",Master,"Visibility:Hidden;Position:Absolute;Width:Auto;Height:Auto","GetSize"),Script:=this.CreateElement("Script",Root),Script.InnerText:="onclick=function(event){ahk_event('OnClick',event);" "};ondblclick=function(event){ahk_event('OnDoubleClick',event);" "};onmousedown=function(event){ahk_event('MouseDown',event);" "};",Settings.ID:="Settings",Close.ID:="Close",Button.ID:="Testing",this.Doc.ParentWindow.ahk_event:=this._Event.Bind(this)
		if(this.Gradient)
			this.SetBackground({0:this.ThemeColor,100:"#000"}),this.SetBackground({0:this.ThemeColor,100:"#000"},"Icon")
		this.CSS.Button:=this.CreateElement("Style",Root),this.CSS.Header:=this.CreateElement("Style",Root),this.CSS.GetSize:=this.CreateElement("Style",Root),this.CSS.Text:=this.CreateElement("Style",Root),this.CSS.Icon:=this.CreateElement("Style",Root),this.SetCSS({"Header":{Size:20,Background:this.ThemeColor},"Button":{Size:20},"Icon":{Size:120}}),this.SetIcon(this.Icon),this.SetCSS({Text:{Color:this.Color},Header:{Color:this.Color},Button:{Color:this.Color,Background:(this.Gradient?"-ms-linear-gradient(Top," this.ThemeColor " 0%,#383838 70%,#000000 100%)":this.ThemeColor),Border:"1px Solid " this.Background}})
		Gui,%Default%:Default
		return this
	}Arrows(){
		local
		Button:=this.GetActive().Value,ID:=this.OrderTab[Button],ID:=ID+(A_ThisHotkey~="i)\b(Up|Left)\b"?-1:1),ID:=ID>this.TabOrder.MaxIndex()?1:ID<=0?this.TabOrder.MaxIndex():ID,this.TabOrder[ID].Obj.Focus()
	}BuildCSS(Obj){
		local
		for a,b in {Size:"Font-Size"}
			if(Value:=Obj[a])
				Obj[b]:=Value "px",Obj.Delete(a)
		Total:="{"
		for a,b in Obj
			Total.=a ":" b ";"
		return Total "}"
	}BuildGradient(Color){
		local
		Start:="Top"
		for a,b in Color{
			if(a="Start")
				Start:=b
			else
				Gradient.=b " " a "%,"
		}return Color:=Gradient?"-ms-linear-gradient(" Start "," Trim(Gradient,",") ")":Color
	}ClearHotkeys(){
		Hotkey,IfWinActive,% this.ID
		for a,b in this.KeyResult
			Hotkey,%a%,Off
		this.KeyResult:=[]
	}CreateElement(Type,Parent:="",Style:="",ID1:=""){
		local
		New:=this.Doc.CreateElement(Type),(Parent?Parent.AppendChild(New):this.Doc.Body.AppendChild(New))
		if(Style)
			New.SetAttribute("Style",Style)
		if(ID1)
			New.ID:=ID1
		return New
	}Enter(){
		this.GetActive().Click()
	}Escape(){
		Gui,% this.Win ":Destroy"
	}FixIE(Version=0){ ;Thanks GeekDude
		local
		static Versions:={7:7000,8:8888,9:9999,10:10001,11:11001}
		Key:="Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION",Version:=Versions[Version]?Versions[Version]:Version
		if(A_IsCompiled)
			ExeName:=A_ScriptName
		else
			SplitPath,A_AhkPath,ExeName
		RegRead,PreviousValue,HKCU,%Key%,%ExeName%
		if(!Version)
			RegDelete,HKCU,%Key%,%ExeName%
		else
			RegWrite,REG_DWORD,HKCU,%Key%,%ExeName%,%Version%
		return PreviousValue
	}GetActive(){
		return this.Doc.ActiveElement
	}GetID(ID){
		return this.Doc.GetElementById(ID)
	}Monitor(Monitor:=""){
		local
		SysGet,Count,MonitorCount
		SysGet,Primary,MonitorPrimary
		Obj:=[]
		while(A_Index<=Count){
			SysGet,Mon,MonitorWorkArea,%A_Index%
			Obj[A_Index]:={Left:MonLeft,Top:MonTop,Right:MonRight,Bottom:MonBottom,W:MonRight-MonLeft,H:MonBottom-MonTop}
		}return Obj.Count()=1?Obj.1:Obj[Monitor]?Obj[Monitor]:Obj[Primary]
	}Result(){
		local
		this.ResultValue:=this.KeyResult[A_ThisHotkey]
	}SetBackground(Color,ID1:="Text"){
		local
		this.SetCSS({(ID1):{Background:this.BuildGradient(Color)}})
	}SetButtons(ButtonsCSV:="OK",Default:="Clipboard,ClipExit,E&xitApp,FileDump"){
		local
		this.ClearHotkeys()
		for a,b in this.ButtonsCSS
			b.ParentNode.RemoveChild(b)
		Buttons:=StrSplit(ButtonsCSV,","),this.OrderTab:=[],this.TabOrder:=[],ID:=1,this.ButtonsCSS:=[]
		while(aa:=this.Doc.GetElementsByTagName("Button").Item[0])
			aa.ParentNode.RemoveChild(aa)
		for a,b in StrSplit(Default,",")
			Buttons.Push(b)
		if(FileExist(A_MyDocuments "\AutoHotkey\Lib\Studio.ahk"))
			Buttons.Push("Studio")
		this.Hotkeys:=[]
		for a,Text in Buttons{
			Button:=this.CreateElement("Button",this.ButtonDiv)
			Button.Value:=RegExReplace(Text,"&")
			Button.ID:="Button" ++ID
			if(RegExMatch(Text,"O)&(.)",Found)){
				if(this.Hotkeys[Found.1])
					Letter:=this.GetHotkey(Text)
				else
					Letter:=Found.1
			}else
				Letter:=this.GetHotkey(Text)
			if(Letter)
				this.SetHotkey(Letter,Button.Value)
			Button.InnerHTML:=RegExReplace(Button.Value,Letter,"<u>" Letter "</u>")
			this.OrderTab[Button.Value]:=this.TabOrder.Push({ID:Button.Value,Obj:Button,ButtonID:ID}),Style:=Button.Style,Style.Cursor:="Hand",Button.SetAttribute("Class","Button"),this.Buttons[Button.Value]:=Button,Button.SetAttribute("ButtonID",ID)
		}
	}GetHotkey(Text){
		for a,Letter in StrSplit(RegExReplace(Text,"(\W|\s)")){
			if(!this.Hotkeys[Letter])
				return Letter,this.Hotkeys[Letter]:=1
		}
	}SetButtonCSS(Object){
		local
		for Name,Obj in Object{
			if(!Button:=this.ButtonCSS[Name])
				Button:=this.ButtonCSS[Name]:=[]
			for a,b in Obj
				Button[a]:=(a="Background"?this.BuildGradient(b):b)
			if(!OO:=this.ButtonsCSS[Name])
				OO:=this.ButtonsCSS[Name]:=this.CreateElement("Style")
			OO.InnerText:="#Button" this.Buttons[Name].GetAttribute("ButtonID") this.BuildCSS(Button)
	}}SetCSS(Object){
		local
		for Type,Obj in Object{
			if(!Normal:=this.NormalCSS[Type])
				Normal:=this.NormalCSS[Type]:=[]
			for a,b in Obj
				Normal[a]:=b
			this.CSS[Type].InnerText:="." Type this.BuildCSS(Normal)
			if(Type="Header"&&(VV:=OO["Font-Size"]))
				if(RegExMatch(VV,"O)(\d+)",Found))
					this.GetID("Close").Style.Width:=Round(Found.1*1.5) "px",Found:=""
	}}SetHotkey(Key,Value){
		local
		Result:=this.BoundResult
		Hotkey,%Key%,%Result%,On
		this.KeyResult[Key]:=Value
	}SetHTML(Text*){
		local
		for a,b in Text
			(a=HTML&&b=1?(HTML:=1):(Msg.=(IsObject(b)?this.Obj2String(b):b)))
		this.Text.InnerHTML:=RegExReplace(Msg,"\R","<br>")
	}SetIcon(Icon){
		local
		static Icons:={"!":{Code:"&#x26A0;",Color:"Yellow"},X:{Code:"&#x2297;",Color:"Red"},"?":{Code:"&#x2753;",Color:"Blue"},I:{Code:"&#x24D8;",Color:"Blue"}},Img
		IconObj:=this.GetID("Icon")
		if(!Icon)
			IconObj.Style.Display:="None"
		else
			IconObj.Style.Display:="Flex"
		if(InStr(Icon,"http")&&!Image)
			(Img:=this.CreateElement("Img",this.GetID("Icon"))),Img.SRC:=this.Icon,Img.Style.MaxWidth:=200,Img.Style.MaxHeight:=200,IconObj.Style.Display:="Flex"
		else
			IconObj.InnerHTML:=(II:=Icons[Icon])?II.Code:Icon
		if(II.Color)
			this.SetCSS({"Icon":{Color:II.Color}})
	}SetText(Text*){
		local
		for a,b in Text
			Msg.=(IsObject(b)?this.Obj2String(b):b)
		this.GetID("Text").InnerText:=Msg
	}Show(Name:="",Default:=1,Ico:=""){
		local
		this.ResultValue:="",this.Doc.GetElementsByTagName("Button").Item[Default-1].Focus(),Text:=this.GetID("Text"),Mon:=this.Monitor(),this.Name:=Name?Name:this.Name,(TT:=this.Doc.GetElementById("Title")).InnerText:=this.Name
		Gui,% this.Win ":Show",w0 h0 Hide
		Ico:=this.Doc.GetElementById("Icon"),IcoWidth:=Ico.ScrollWidth,IcoHeight:=Ico.ScrollHeight,this.Doc.GetElementById("Header").Style.Height:=TT.ScrollHeight,ButtonWidth:=0,Height:=[],Sub:=0
		for a,b in [Close:=this.GetID("Close"),Settings:=this.GetID("Settings")]
			Obj:=this.Doc.GetElementById(b),Sub+=Obj.ClientWidth
		Title:=this.GetID("Title"),this.SetCSS({"Header":{Height:Title.ScrollHeight}})
		for a,b in this.TabOrder
			Rect:=b.Obj.GetBoundingClientRect(),ButtonWidth+=Ceil(Rect.Right-Rect.Left),Height[Ceil(Rect.Height)]:=1
		if(ButtonWidth>Mon.W)
			return this.SetCSS({"Button":{Size:20}}),this.Show(Name)
		MaxW:=W:=A_ScreenWidth-100,MaxH:=H:=A_ScreenHeight-100,HH:=Height.MaxIndex(),AddW:=Text.OffSetWidth-Text.ClientWidth,AddH:=Text.OffSetHeight-Text.ClientHeight
		if((NH:=Text.ScrollHeight+Title.ScrollHeight+HH+AddH)<Mon.H)
			H:=NH,AddW:=0
		if((NH:=IcoHeight+Title.ScrollHeight+HH+AddH)>H)
			H:=NH
		if((NW:=Text.ScrollWidth+IcoWidth+AddW)<Mon.W)
			W:=NW
		if(W<ButtonWidth)
			W:=ButtonWidth
		Width:=Floor(Close.ScrollWidth/2),Close.Style.PaddingLeft:=Width,Close.Style.PaddingRight:=Width
		if(W<Settings.ScrollWidth+Close.ScrollWidth)
			return this.SetCSS({"Header":{Size:30,Height:""}}),this.Show(Name)
		Gui,% this.Win ":Show",xCenter yCenter w%W% h%H%
		ButtonWidth:=0
		for a,b in this.TabOrder
			Rect:=b.Obj.GetBoundingClientRect(),ButtonWidth+=Ceil(Rect.Right-Rect.Left),Height[Ceil(Rect.Height)]:=1
		if(ButtonWidth>Mon.W)
			return this.SetCSS({"Button":{Size:20}}),this.Show(Name)
		if(W<ButtonWidth)
			Gui,% this.Win ":Show",xCenter yCenter w%ButtonWidth% h%H%
		Gui,% this.Win ":+Owner" this.Owner " +MinSize" ButtonWidth "x" TT.ScrollHeight+Height.MaxIndex()+10
		while(!this.ResultValue)
			Sleep,400
		if(this.ResultValue="ClipExit"){
			Clipboard:=Trim(RegExReplace(this.Doc.GetElementById("Text").InnerText,"\<\/?br\>","`r`n"),"`r`n")
			ExitApp
		}
		if(this.ResultValue="FileDump"){
			x:=ComObjActive("{DBD5A90A-A85C-11E4-B0C7-43449580656B}")
			Text:=Trim(RegExReplace(this.Doc.GetElementById("Text").InnerText,"\<\/?br\>","`r`n"),"`r`n")
			x.TempFile(Text)
			ExitApp
		}
		this.ResultValue:=this.ResultValue=Chr(127)?"":this.ResultValue
		if(this.ResultValue="Clipboard"){
			Clipboard:=Trim(RegExReplace(this.Doc.GetElementById("Text").InnerText,"\<\/?br\>","`r`n"),"`r`n")
			Gui,% this.Win ":Destroy"
			return "Clipboard"
		}else if(this.ResultValue="ExitApp")
			ExitApp
		else if(this.ResultValue="Studio"){
			if(x:=ComObjActive("{DBD5A90A-A85C-11E4-B0C7-43449580656B}"))
				x.DebugWindow(Trim(RegExReplace(this.Doc.GetElementById("Text").InnerText,"\<\/?br\>","`r`n"),"`r`n"))
			ExitApp
		}Gui,% this.Win ":Hide"
		return this.ResultValue
	}Size(a:="",W:="",H:=""){
		local Settings,Close,Height,Title
		static Pos:=[]
		this:=IsObject(this)?this:MsgBox.Keep[this]
		WinGet,Style,Style,% this.ID
		if(!W||!H)
			W:=Pos.W,H:=Pos.H
		Pos:={W:W,H:H},Close:=this.GetID("Close"),Settings:=this.GetID("Settings"),Border:=Style&0x40000!=0?this.Border:0
		ControlMove,,%Border%,%Border%,%W%,%H%,% "ahk_id" this.HWND
		Close.Style.Right:="0"
		Settings.Style.Right:=Close.ClientWidth
		Pos1:=Close.GetBoundingClientRect()
		this.Doc.GetElementById("Title").Style.Width:=W-(Close.ScrollWidth+Settings.ScrollWidth)
		Height:=this.Doc.GetElementsByTagName("Button").Item[0].OffSetHeight
		Title:=this.GetID("Title").ScrollHeight
		this.Doc.GetElementById("Icon").Style.Height:=H-Height-Title
		this.Doc.GetElementById("Text").Style.Height:=H-Height-Title
	}
}