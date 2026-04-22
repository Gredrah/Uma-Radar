#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

fileFound(TargetX, TargetY, MatchedName) {
    global sound
    SoundPlay sound
    TrayTip MatchedName " located!", "Target Found", 1
    MsgBox "Target found at " TargetX ", " TargetY "!"
    ExitApp()
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

Loop Files TargetFolder "\*.*"
{
    ; FIX 1: Use FindText's native file path syntax. 
    ; "##50$" tells FindText to load a file with a color tolerance of 50. 
    ; You can lower this to 10 for stricter matching, or raise it for looser matching.
    CachedTargets .= "|<" A_LoopFileName ">##50$" A_LoopFileFullPath
}

Loop
{
    Click CoordX " " CoordY
    Sleep sleept

    ; FIX 2: Added &FoundX and &FoundY to the beginning to handle the ByRef coordinate outputs.
    if (findTextResult := FindText(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0.1, 0.1, CachedTargets, , , 1, 1.5, 0.5))
    {
        TargetX := findTextResult[1].x
        TargetY := findTextResult[1].y
        MatchedName := findTextResult[1].id

        fileFound(TargetX, TargetY, MatchedName)
        ExitApp()
    }

    FoundViaBackup := false
    Loop Files TargetFolder "\*.*"
    {
        ; The *w-1 *h-1 options ensure the search area is reduced by 1 pixel in width and height to avoid edge artifacts
        ; The *110 option increases the color variation tolerance.
        if ImageSearch(&ImgFoundX, &ImgFoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*110 *w-1 *h-1 " A_LoopFileFullPath)
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
        ExitApp()
    }

    MouseGetPos &MouseX, &MouseY
    ToolTip "No match found", MouseX + 20, MouseY + 20
    Sleep 1000
    ToolTip()
    
    Sleep 500
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
    if (TargetFolder = "ERROR")
    {
        MsgBox "Missing configuration value:`n[FilePaths] target`n`nPlease add the target entry to config.ini.", "Configuration Error", 16
        return false
    }

    if (TargetFolder = "" || !InStr(FileExist(TargetFolder), "D"))
    {
        MsgBox "Invalid target folder:`n" TargetFolder "`n`nPlease set [FilePaths] target to an existing directory.", "Configuration Error", 16
        return false
    }

    sound := IniRead("config.ini", "FilePaths", "sound", "ERROR")
    if (sound = "ERROR")
    {
        MsgBox "Missing configuration value:`n[FilePaths] sound`n`nPlease add the sound entry to config.ini.", "Configuration Error", 16
        return false
    }

    if (sound = "" || !FileExist(sound) || InStr(FileExist(sound), "D"))
    {
        MsgBox "Invalid sound file:`n" sound "`n`nPlease set [FilePaths] sound to an existing sound file.", "Configuration Error", 16
        return false
    }

    CoordX := IniRead("config.ini", "Settings", "CoordX", "ERROR")
    if (CoordX = "ERROR" || !IsNumber(CoordX))
    {
        MsgBox "Invalid coordinate value:`n[Settings] CoordX`n`nPlease set [Settings] CoordX to a valid number.", "Configuration Error", 16
        return false
    }

    CoordY := IniRead("config.ini", "Settings", "CoordY", "ERROR")
    if (CoordY = "ERROR" || !IsNumber(CoordY))
    {
        MsgBox "Invalid coordinate value:`n[Settings] CoordY`n`nPlease set [Settings] CoordY to a valid number.", "Configuration Error", 16
        return false
    }

    sleept := IniRead("config.ini", "Settings", "sleept", "ERROR")
    if (sleept = "ERROR" || !IsNumber(sleept))
    {
        MsgBox "Invalid sleep time value:`n[Settings] sleept`n`nPlease set [Settings] sleept to a valid number.", "Configuration Error", 16
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