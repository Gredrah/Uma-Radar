#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

; -------------------------------------------------------------------------
; SETTINGS
; -------------------------------------------------------------------------
DEBUG := false          ; set true to see OCR output
OCR_DELAY := 300        ; delay between OCR scans (ms)

; REGION TO SCAN (IMPORTANT: adjust this!)
; X, Y, Width, Height
SCAN_X := 0
SCAN_Y := 0
SCAN_W := A_ScreenWidth
SCAN_H := A_ScreenHeight

; -------------------------------------------------------------------------
; LOAD LIBRARIES
; -------------------------------------------------------------------------
#Include lib\ImagePut.ahk
#Include lib\RapidOcr.ahk

ToolTip "Warming up OCR engine..."
try {
    global ocrEngine := RapidOcr({ modelpath: "lib\models" })
} catch {
    MsgBox "Failed to load RapidOcr.`nCheck models + DLLs.", "Error", 16
    ExitApp()
}
ToolTip

; -------------------------------------------------------------------------
; LOAD CONFIG
; -------------------------------------------------------------------------
Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetArray := Config.TargetArray
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept

; normalize targets once
for i, v in TargetArray
    TargetArray[i] := StrLower(Trim(v))

; -------------------------------------------------------------------------
; SUCCESS FUNCTION
; -------------------------------------------------------------------------
fileFound(TargetX, TargetY, MatchedName) {
    global sound

    ToolTip
    SoundPlay sound
    TrayTip MatchedName " located!", "Target Found", 1

    Click TargetX " " TargetY
    MsgBox "Clicked on [" MatchedName "]!"
    ExitApp()
}

; -------------------------------------------------------------------------
; MAIN LOOP
; -------------------------------------------------------------------------
Loop
{
    ToolTip "Scanning..."

    ; --- Capture only region ---
    buf := ImagePutBuffer(0)

    ; --- Build bitmap structure ---
    st_BF := Buffer(40, 0)
    NumPut("ptr", buf.ptr
        , "uint", buf.stride
        , "uint", buf.width
        , "uint", buf.height
        , "uint", 4
        , "uint", 0
        , "uint", 0
        , st_BF)

    ; --- OCR ---
    ocrResult := ocrEngine.ocr_from_bitmapdata(st_BF, 0, true)

    FoundMatch := false

    if IsObject(ocrResult)
    {
        for _, block in ocrResult
        {
            if !IsObject(block)
                continue

            if !block.HasProp("text")
                continue

            rawText := block.text
            cleanText := StrLower(Trim(rawText))

            if DEBUG
            {
                ToolTip cleanText
                Sleep 200
            }

            for _, searchWord in TargetArray
            {
                if InStr(cleanText, searchWord)
                {
                    if !block.HasProp("boxPoint")
                        continue

                    ; adjust coordinates back to screen space
                    sumX := 0, sumY := 0

                    for _, p in block.boxPoint {
                        sumX += p.x
                        sumY += p.y
                    }

                    TargetX := sumX // block.boxPoint.Length + SCAN_X
                    TargetY := sumY // block.boxPoint.Length + SCAN_Y

                    fileFound(TargetX, TargetY, searchWord)
                    FoundMatch := true
                    break 2
                }
            }
        }
    }

    ; ---------------------------------------------------------------------
    ; OPTIONAL FALLBACK CLICK (disabled by default)
    ; ---------------------------------------------------------------------
    if !FoundMatch
    {
        ToolTip "Not found. Waiting..."

        MouseGetPos &OrigX, &OrigY
        Click CoordX " " CoordY
        Sleep 100
        MouseMove OrigX, OrigY
    }

    Sleep OCR_DELAY
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
        MsgBox "Missing config.ini", "Error", 16
        return false
    }

    RawText := IniRead("config.ini", "Settings", "TargetText", "")
    if (RawText = "")
    {
        MsgBox "Missing TargetText in config.ini", "Error", 16
        return false
    }

    TargetArray := StrSplit(RawText, ",")
    for i, v in TargetArray
        TargetArray[i] := Trim(v)

    sound := IniRead("config.ini", "FilePaths", "sound", "")
    if (sound = "" || !FileExist(sound))
    {
        MsgBox "Invalid sound file.", "Error", 16
        return false
    }

    CoordX := IniRead("config.ini", "Settings", "CoordX", "")
    CoordY := IniRead("config.ini", "Settings", "CoordY", "")
    sleept := IniRead("config.ini", "Settings", "sleept", "")

    if (!IsNumber(CoordX) || !IsNumber(CoordY) || !IsNumber(sleept))
    {
        MsgBox "Invalid numeric values in config.ini", "Error", 16
        return false
    }

    return {
        TargetArray: TargetArray,
        sound: sound,
        CoordX: CoordX,
        CoordY: CoordY,
        sleept: sleept
    }
}