/*
*Savefile Converter
*By GreenBat
*Version: 
*	1.3 Last updated (29/10/2023)
*	https://github.com/Green-Bat/Savefile-Converter
*/
#Warn
#NoEnv
#NoTrayIcon
#SingleInstance, Ignore
ListLines, Off
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

Gui, Main:New, +HwndmainHwnd, Savefile Converter
Gui, Font, s11
Gui, Main:Add, Radio, xm y20 Checked vSteamToEpic, % "Steam->Epic Games"
Gui, Main:Add, Radio, xp+160 vEpicToSteam, % "Epic Games->Steam"
Gui, Main:Add, Text, xm yp+30 vtext, Drag and drop files or folders or enter their full path :
Gui, Font
Gui, Main:Add, Edit, xm yp+25 wp+20 vPath
Gui, Main:Add, Button, Default xp+127.5 yp+30 wp-255 h30 gConvert, > Convert <
Gui, Main:Add, Progress, w310 h20 xp-127.5 yp-30 vProgressBar
GuiControl, Hide, ProgressBar
Gui, Main:Show, w340 h140
return
;===============================================================================================================================

Convert:
	Gui, Main:Submit, NoHide ; Get the path from the edit box and the current choice of game
	try Check(Path)
	catch e {
		MsgBox, % e.Extra ? 48 : 16, Savefile Converter, % e.Message
		return
	}
	MsgBox, 64, Savefile Converter, Conversion complete.
	GuiControl,, Path ; Empty the edit box
	return
;===============================================================================================================================

MainGuiDropFiles:
	Gui, Main:Submit, NoHide
	filecount := 0
	Loop, Parse, A_GuiEvent, `n
	{
		try Check(A_LoopField)
		catch e {
			MsgBox, % e.Extra ? 48 : 16, Savefile Converter, % e.Message
			continue
		}
		filecount++
	}
	if (filecount > 0)
		MsgBox, 64, Savefile Converter, Conversion complete.
	return
;===============================================================================================================================

Check(ToConvert){
	global EpicToSteam, SteamToEpic, ProgressBar
	
	Gui, Main:+OwnDialogs
	file_count := 0
	, Name := SubStr(ToConvert, InStr(ToConvert, "\",, 0)+1)

	if !(f := FileExist(ToConvert))
		throw Exception("ERROR: Not a valid path!!!",, 0)
	; If a file has "EG_" in its name it most likely means it was already converted
	if (InStr(ToConvert, "EG_", true) && !(InStr(f, "D")) && SteamToEpic)
		throw Exception("File already converted",, 1)
	else if (InStr(ToConvert, "Steam_", true) && !(InStr(f, "D")) && EpicToSteam)
		throw Exception("File already converted",, 1)

	; If it's a single file, run the converter once
	if (InStr(ToConvert, ".sgd", true)){
		try Converter(ToConvert, Name)
		catch c {
			throw c
		}
	}
	else if (InStr(f, "D")) {
		GuiControl, Show, ProgressBar
		; Loop through the folder and convert all the savefiles in it
		Loop, Files, % ToConvert "\*.sgd"
		{
			; If a converted file exsits in the folder, ignore it
			if ((!InStr(A_LoopFileLongPath, "EG_", true) && SteamToEpic) || (!InStr(A_LoopFileLongPath, "Steam_", true) && EpicToSteam)) {
				try Converter(A_LoopFileLongPath, A_LoopFileName)
				catch c {
					MsgBox, % c.Extra ? 48 : 16, Savefile Converter, % c.Message
					continue
				}
				GuiControl,, ProgressBar, % "+" . Mod(file_count, 100)
				file_count++
			}
		}
		GuiControl, Hide, ProgressBar
		if (file_count <= 0)
			throw Exception("All savefiles in """ Name """ are already converted" ,, 1)
	} else if !(SubStr(Name, InStr(Name, ".",, 0)) == ".sgd")
		throw Exception("ERROR: """ Name """ has an incorrect file extension",, 0)
}
;===============================================================================================================================

Converter(ToConvert, Name){
	global EpicToSteam, SteamToEpic
	
	if (EpicToSteam){
		NewFile := SubStr(ToConvert, 1, -StrLen(Name)) . "Steam_" . Name
		, SteamF := FileOpen(NewFile, "w")
		, EGF := FileOpen(ToConvert, "r")
		, l := EGF.Length/1024
		
		if (l == 288 || l == 2372)
			throw Exception("ERRORR: Make sure you have the correct conversion option checked!!")
		
		; Advance file pointer 4 bytes
		EGF.Seek(4)
		; Copy the rest of the Epic file into a new file
		EGF.RawRead(RawData, EGF.Length - 4)
		SteamF.RawWrite(RawData, EGF.Length - 4)
	} else if (SteamToEpic){
		NewFile := SubStr(ToConvert, 1, -StrLen(Name)) . "EG_" . Name
		, EGF := FileOpen(NewFile, "w")
		, SteamF := FileOpen(ToConvert, "r")
		, l := SteamF.Length/1024
		, EGbytes := {"Arkham Knight": "0 10 25 0", "Arkham City": "0 80 4 0", "Arkham Asylum": "0 0 1 0", "Arkham Asylum2": "0 0 2 0"}
		, Game := ""
		
		; Automatically pick the game based on file size
		if (l >= 64 && l <= 84){
			if (l > 64)
				Game := "Arkham Asylum2"
			else
				Game := "Arkham Asylum"
		} else if (l == 288){
			Game := "Arkham City"
		} else if (l == 2372){
			Game := "Arkham Knight"
		} else {
			SteamF.Close()
			EGF.Close()
			FileDelete, % NewFile
			throw Exception("ERROR: Unable to convert """ Name """. Invaild file size. Make sure you have the correct conversion option checked!!",, 0)
		}
		; Insert the required bytes at the beginning of the file, depending on the choice of game
		Loop, Parse, % EGbytes[Game], % " "
			EGF.WriteUChar("0x" A_LoopField)
		; Read the raw binary data from the steam savefile and write it to the converted savefile
		SteamF.RawRead(RawData, SteamF.Length)
		EGF.RawWrite(RawData, SteamF.Length)
	}

	EGF.Close()
	SteamF.Close()
	return
}
;===============================================================================================================================
MainGuiClose:
ExitApp