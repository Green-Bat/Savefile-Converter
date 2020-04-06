﻿#Warn
#NoEnv
#NoTrayIcon
#SingleInstance, Ignore
ListLines, Off
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

bytes := {"Arkham Knight": "00 10 25 00", "Arkham City": "00 80 04 00", "Arkham Asylum": ["00 00 01 00", "00 00 02 00"]}

Gui, Main:New, +HwndmainHwnd, Savefile Converter
Gui, Font, s11
Gui, Main:Add, Text, xm y45 vtext, Drag and drop files or folders or enter their full path :
Gui, Font
Gui, Main:Add, DDL, xp+220 yp-30 w100 vGame, Arkham Asylum||Arkham City|Arkham Knight
Gui, Main:Add, Edit, xm yp+55 wp+220 vPath
Gui, Main:Add, Button, Default xp+127.5 yp+30 wp-255 h30 gConvert, > Convert <
Gui, Main:Show, w340 h135
return
;===============================================================================================================================

Convert:
	GuiControlGet, ToConvert,, Path ; Get the path from the edit box
	GuiControlGet, ChosenGame,, Game ; Get the current choice of game
	try Check(ToConvert, ChosenGame)
	catch e {
		MsgBox, % e.Extra ? 48 : 16, Savefile Converter, % e.Message
		return
	}
	MsgBox, 0, Savefile Converter, Conversion complete.
	GuiControl,, Path ; Empty the edit box
	return
;===============================================================================================================================

MainGuiDropFiles:
	GuiControlGet, ChosenGame,, Game
	filecount := 0
	Loop, Parse, A_GuiEvent, `n
	{
		try Check(A_LoopField, ChosenGame)
		catch e {
			MsgBox, % e.Extra ? 48 : 16, Savefile Converter, % e.Message
			continue
		}
		filecount++
	}
	if (filecount > 0)
		MsgBox, 0, Savefile Converter, Conversion complete.
	return
;===============================================================================================================================

Check(ToConvert, ChosenGame){
	Gui, Main:+OwnDialogs
	file_count := 0
	, Name := SubStr(ToConvert, InStr(ToConvert, "\",, 0)+1)
	if !(f := FileExist(ToConvert))
		throw Exception("ERROR: Not a valid path!!!",, 0)
	; If a file has "EG_" in its name it most likely means it was already converted
	if (InStr(ToConvert, "EG_", true) && !(InStr(f, "D")))
		throw Exception("File Already Converted",, 1)

	; If it's a single file, run the converter once
	if (InStr(ToConvert, ".sgd", true))
		Converter(ToConvert, Name, ChosenGame)
	else if (InStr(f, "D")) {
		; Loop through the folder and convert all the savefiles in it
		Loop, Files, % ToConvert "\*.sgd"
		{
			if !(InStr(A_LoopFileLongPath, "EG_", true)) { ; If a converted file exsits in the folder, ignore it
				Converter(A_LoopFileLongPath, A_LoopFileName, ChosenGame)
				file_count++
			}
		}
		if (file_count <= 0)
			throw Exception("No unconverted savefiles were found",, 1)
	} else if !(SubStr(Name, InStr(Name, ".",, 0)) == ".sgd")
		throw Exception("ERROR: """ Name """ has an incorrect file extension",, 0)
}
;===============================================================================================================================

Converter(ToConvert, Name, Game){
	local SteamData:=""
	, NewFile := SubStr(ToConvert, 1, -StrLen(Name)) . "EG_" . Name

	EGF := FileOpen(NewFile, "w")
	SteamF := FileOpen(ToConvert, "r")
	; Insert the required bytes at the beginning of the file, depending on the choice of game
	; if the file size is greater than 65kb insert the second set of bytes for Arkham Asylum
	Loop, Parse, % (((SteamF.Length/1024) > 65) && (Game == "Arkham Asylum")) ? bytes[Game][2] : (Game == "Arkham Asylum") ? bytes[Game][1] : bytes[Game], % " "
		EGF.WriteUChar("0x" A_LoopField)
	; Read the raw binary data from the steam savefile and write it to the converted savefile
	SteamF.RawRead(RawData, SteamF.Length)
	EGF.RawWrite(RawData, SteamF.Length)

	EGF.Close()
	SteamF.Close()
	return
}
;===============================================================================================================================
MainGuiClose:
ExitApp