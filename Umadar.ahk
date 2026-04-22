#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

; =========================================================================
; TUNING VARIABLES (Adjust these to optimize performance)
; =========================================================================

; 1. Color Tolerance (0 to 255)
; * 0 requires an exact pixel-perfect match.
; * 50 allows for slight color variations (shadows, hover states, UI transparency).
; * Lowering this speeds up the search, but makes it stricter.
ColorTolerance := 50 

; 2. CPU Throttle (Milliseconds)
; Gives your processor a tiny break between checking each image. 
; Prevents the script from freezing your mouse or lagging the system.
SearchDelay := 10 

; 3. Search Bounding Box (CRITICAL FOR SPEED)
; Right now, it searches the entire screen. If you know the images will only 
; ever appear in a specific area (e.g., the right half of the screen), change 
; these coordinates to create a smaller box. It will search 10x faster!
SearchX1 := 0
SearchY1 := 0
SearchX2 := A_ScreenWidth
SearchY2 := A_ScreenHeight

; =========================================================================

fileFound(TargetX, TargetY, MatchedName) {
    global sound
    ToolTip ; Clear tooltips
    SoundPlay sound
    TrayTip MatchedName " located!", "Target Found", 1
    MsgBox "Target found at " TargetX ", " TargetY "!"
    ExitApp()
}

Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetFolder := Config.TargetFolder
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept

; -------------------------------------------------------------------------
; PRE-LOAD: Scan the folder ONCE at startup and load paths into RAM.
; This prevents the script from constantly reading your hard drive.
; -------------------------------------------------------------------------
ImagePaths := []
Loop Files TargetFolder "\*.*"
{
    if (A_LoopFileExt ~= "i)^(png|bmp|jpg|jpeg)$")
        ImagePaths.Push(A_LoopFileFullPath)
}

if (ImagePaths.Length = 0)
{
    MsgBox "No valid images (png, bmp, jpg) found in:`n" TargetFolder, "Error", 16
    ExitApp()
}

; -------------------------------------------------------------------------
; MAIN AUTOMATION LOOP
; -------------------------------------------------------------------------
Loop
{
    ToolTip "Scanning for " ImagePaths.Length " images..."
    FoundMatch := false
    TargetX := 0
    TargetY := 0
    MatchedName := ""
    
    for index, imgPath in ImagePaths
    {
        ; The Tuned ImageSearch Engine
        if ImageSearch(&ImgFoundX, &ImgFoundY, SearchX1, SearchY1, SearchX2, SearchY2, "*" ColorTolerance " " imgPath)
        {
            TargetX := ImgFoundX
            TargetY := ImgFoundY
            SplitPath imgPath, &MatchedName ; Cleanly strips the folder path to just get the filename
            FoundMatch := true
            break
        }
        Sleep SearchDelay ; Yield CPU
    }

    if (FoundMatch)
    {
        fileFound(TargetX, TargetY, MatchedName)
    }

    ; POST-SEARCH ACTION
    ToolTip "No match found. Clicking and waiting " sleept "ms..."
    
    Click CoordX " " CoordY
    MouseMove 0, 0, 0 ; Move mouse out of the way to prevent hover-state interference
    
    Sleep sleept
}
return

; F9 cleanly kills the script at any time
F9::ExitApp()

LoadConfig()
{
    if !FileExist("config.ini")
    {
        MsgBox "Missing configuration file:`nconfig.ini", "Configuration Error", 16
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