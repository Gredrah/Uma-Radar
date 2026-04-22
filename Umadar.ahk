#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib/OCR.ahk

CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

; -------------------------------------------------------------------------
; SUCCESS FUNCTION
; -------------------------------------------------------------------------
fileFound(TargetX, TargetY, MatchedName) {
    global sound
    ToolTip ; Clear any existing tooltips
    SoundPlay sound
    TrayTip MatchedName " located!", "Target Found", 1
    
    ; Move mouse to the text and click it
    Click TargetX " " TargetY
    
    MsgBox "Clicked on " MatchedName "!"
    ExitApp()
}

Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetArray := Config.TargetArray 
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept

Loop
{
    ToolTip "Scanning screen for text (en-US)..."
    
    ; 1. Scan the screen and FORCE the English-US OCR engine
    ; This drastically improves accuracy on stylized English fonts.
    try {
        result := OCR.FromDesktop("en-US")
    } catch {
        MsgBox "Error: English OCR language pack is not installed on this Windows system."
        ExitApp()
    }

    ; --- OPTIONAL DEBUGGING ---
    ; Uncomment the line below to see exactly what the OCR engine is reading.
    ; If it misreads "GoldShip" as "GoidShip", just put "GoidShip" in your config.ini!
    ; ToolTip "OCR SEES:`n" result.Text, 10, 10 
    ; --------------------------

    ; 2. Loop through every word in your config.ini array
    FoundMatch := false
    for index, searchWord in TargetArray
    {
        ; We use InStr to check if your word is anywhere in the massive block of OCR text
        if InStr(result.Text, searchWord, false) 
        {
            ; Find the exact X/Y pixel coordinates of that specific word
            targetLocation := result.FindString(searchWord)
            
            if (targetLocation)
            {
                fileFound(targetLocation.x, targetLocation.y, searchWord)
                FoundMatch := true
                break 
            }
        }
    }

    ; 3. POST-SEARCH CLICK, SNAP RETURN, AND WAIT
    ToolTip "Targets not found. Clicking backup coordinates and waiting " sleept "ms..."
    
    MouseGetPos &OrigX, &OrigY  
    Click CoordX " " CoordY     
    
    Sleep 100                   
    MouseMove OrigX, OrigY      
    
    Sleep sleept                
}
return

F9::ExitApp()

; -------------------------------------------------------------------------
; CONFIG LOADER 
; -------------------------------------------------------------------------
LoadConfig()
{
    if !FileExist("config.ini")
    {
        MsgBox "Missing configuration file:`nconfig.ini", "Configuration Error", 16
        return false
    }

    RawTextString := IniRead("config.ini", "Settings", "TargetText", "ERROR")
    if (RawTextString = "ERROR" || RawTextString = "")
    {
        MsgBox "Missing text targets in config.ini.`nPlease add 'TargetText=Word1, Word2' under [Settings].", "Configuration Error", 16
        return false
    }

    TargetArray := StrSplit(RawTextString, ",")
    
    for index, word in TargetArray
    {
        TargetArray[index] := Trim(word)
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
    config.TargetArray := TargetArray
    config.sound := sound
    config.CoordX := CoordX
    config.CoordY := CoordY
    config.sleept := sleept
    return config
}