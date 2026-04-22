#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

fileFound(TargetX, TargetY, MatchedName) {
    global sound
    ToolTip ; Clear any existing tooltips
    SoundPlay sound
    TrayTip MatchedName " located!", "Target Found", 1
    MsgBox "Target found at " TargetX ", " TargetY "!"
    ExitApp() ; Ensures the script completely closes upon success
}

#Include lib/FindText.ahk

Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetFolder := Config.TargetFolder
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept

CachedTargets := ""
FindErrText := 0.15
FindErrBg := 0.15

; Build the FindText string
Loop Files TargetFolder "\*.*"
{
    if !(A_LoopFileExt ~= "i)^(png|bmp|jpg|jpeg)$")
        continue 
        
    CachedTargets .= "|<" A_LoopFileName ">##80$" A_LoopFileFullPath
}

Loop
{
    ; -------------------------------------------------------------------------
    ; 1. FINDTEXT SEARCH
    ; -------------------------------------------------------------------------
    ToolTip "Searching via FindText..."
    
    findTextResult := FindText(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, FindErrText, FindErrBg, CachedTargets)
    
    ; ZERO CHECK: Ensure findTextResult is actually an array before parsing
    if (findTextResult && IsObject(findTextResult))
    {
        TargetX := findTextResult[1].x
        TargetY := findTextResult[1].y
        MatchedName := findTextResult[1].id

        fileFound(TargetX, TargetY, MatchedName)
    }
    

    ; -------------------------------------------------------------------------
    ; 2. IMAGESEARCH BACKUP
    ; -------------------------------------------------------------------------
    ToolTip "Searching via ImageSearch Backup..."
    FoundViaBackup := false
    Loop Files TargetFolder "\*.*"
    {
        if !(A_LoopFileExt ~= "i)^(png|bmp|jpg|jpeg)$")
            continue 

        if ImageSearch(&ImgFoundX, &ImgFoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*110 " A_LoopFileFullPath)
        {
            TargetX := ImgFoundX
            TargetY := ImgFoundY
            MatchedName := A_LoopFileName
            FoundViaBackup := true
            break
        }
    }

    if (FoundViaBackup)
    {
        fileFound(TargetX, TargetY, MatchedName)
    }

    ; -------------------------------------------------------------------------
    ; 3. POST-SEARCH CLICK & WAIT
    ; -------------------------------------------------------------------------
    ToolTip "No match found. Clicking and waiting " sleept "ms..."
    
    Click CoordX " " CoordY
    MouseMove 0, 0, 0 ; Move mouse out of the way so it doesn't block the next search
    
    Sleep sleept
}
return

F9::ExitApp()

LoadConfig()
{
    if !FileExist("config.ini")
    {
        MsgBox "Missing configuration file:`nconfig.ini`n`nCreate config.ini with a [FilePaths] section containing target and sound entries.", "Configuration Error", 16
        return false
    }

    TargetFolder := IniRead("config.ini", "FilePaths", "target", "ERROR")
    if (TargetFolder = "ERROR" || TargetFolder = "" || !InStr(FileExist(TargetFolder), "D"))
    {
        MsgBox "Invalid target folder in config.ini.", "Configuration Error", 16
        return false
    }

    sound := IniRead("config.ini", "FilePaths", "sound", "ERROR")
    if (sound = "ERROR" || sound = "" || !FileExist(sound) || InStr(FileExist(sound), "D"))
    {
        MsgBox "Invalid sound file in config.ini.", "Configuration Error", 16
        return false
    }

    CoordX := IniRead("config.ini", "Settings", "CoordX", "ERROR")
    CoordY := IniRead("config.ini", "Settings", "CoordY", "ERROR")
    sleept := IniRead("config.ini", "Settings", "sleept", "ERROR")

    if (!IsNumber(CoordX) || !IsNumber(CoordY) || !IsNumber(sleept))
    {
        MsgBox "Coordinates or sleep time in config.ini are not valid numbers.", "Configuration Error", 16
        return false
    }

    config := {}
    config.TargetFolder := TargetFolder
    config.sound := sound
    config.CoordX := CoordX
    config.CoordY := CoordY
    config.sleept := sleept
    return config
}