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

#Include FindText.ahk

Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetFolder := Config.TargetFolder
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept

CachedTargets := ""

Loop Files, TargetFolder "\*.*"
{
    CachedTargets .= "|<" A_LoopFileName ">" FindText().GetTextFromFiles(A_LoopFileFullPath)
}


    ; Search the full screen using CachedTargets. The two 0.1 values are the
    ; FindText matching thresholds for text/background differences, and the
    ; trailing 1, 1.5, 0.5 values control the search tolerances/scaling used
    ; when matching target patterns so detection remains reliable on screen.
Loop
{
    Click CoordX ", " CoordY
    Sleep sleept

    if (findTextResult := FindText(0, 0, A_ScreenWidth, A_ScreenHeight, 0.1, 0.1, CachedTargets, , , 1, 1.5, 0.5))
    {
        TargetX := findTextResult[1].x
        TargetY := findTextResult[1].y
        MatchedName := findTextResult[1].id

        fileFound(TargetX, TargetY, MatchedName)
        ExitApp()
    }

    FoundViaBackup := false
    Loop Files, TargetFolder "\*.*"
    {
        ; The *w-1 *h-1 options ensure the search area is reduced by 1 pixel in width and height to avoid edge artifacts
        ; The *110 option increases the color variation tolerance to help find matches even if there are minor differences in how the image appears on screen.
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*110 *w-1 *h-1 " A_LoopFileFullPath)
        {
            TargetX := FoundX
            TargetY := FoundY
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