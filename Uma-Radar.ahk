#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

; -------------------------------------------------------------------------
; SETTINGS
; -------------------------------------------------------------------------
SetWorkingDir A_ScriptDir

DEBUG := false  ; Set to true to enable OCR result pagination for debugging

; REGION TO SCAN (Adjust for performance, if you know where the target text appears on screen)
; X, Y, Width, Height
SCAN_X := 0
SCAN_Y := 0
SCAN_W := A_ScreenWidth
SCAN_H := A_ScreenHeight

; -------------------------------------------------------------------------
; LOAD LIBRARIES
; -------------------------------------------------------------------------
DllCall("SetDefaultDllDirectories", "uint", 0x00001000 | 0x00000800)
DllCall("AddDllDirectory", "ptr", StrPtr(A_ScriptDir "\lib"))

#Include lib\ImagePut.ahk
#Include lib\RapidOcr.ahk

ToolTip "Warming up OCR engine..."
try {
    baseDir := A_ScriptFullPath ? RegExReplace(A_ScriptFullPath, "\\[^\\]+$") : A_ScriptDir
    modelPath := baseDir "\lib\models"
    global ocrEngine := RapidOcr({ modelpath: modelPath })
} catch {
    MsgBox "Failed to load RapidOcr.`nCheck models + DLLs.", "Error", 16
    ExitApp()
}
ToolTip

; -------------------------------------------------------------------------
; LOAD CONFIG
; -------------------------------------------------------------------------
configPath := A_ScriptDir "\config.ini"

Config := LoadConfig()
if !IsObject(Config)
    ExitApp()

TargetArray := Config.TargetArray
sound := Config.sound
CoordX := Config.CoordX
CoordY := Config.CoordY
sleept := Config.sleept
jumpBack := Config.jumpBack

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

    MouseMove TargetX, TargetY
    MsgBox "Clicked on [" MatchedName "]!"
    ExitApp()
}

; -------------------------------------------------------------------------
; getRefreshCoordinates get the position of the refresh button by ratio of pixels in the game window, in case of different screen resolutions
getRefreshCoordinates() {
    ; .415104166..., .83148148... are the ratios of the refresh button's position relative to the screen height in 1080p, 1440p, and 2160p respectively
    UmamusumeRefreshRatios := [0.415104166, 0.83148148]
    X:=0, Y:=0, W:=0, H:=0
    WinGetPos(&X, &Y, &W, &H, "Umamusume")
    
    if (W = 0 || H = 0)
    {
        MsgBox "Failed to get game window position. Make sure Umamusume.exe is running.", "Error", 16
        ExitApp()
    }

    RefreshX := X + W * UmamusumeRefreshRatios[1]
    RefreshY := Y + H * UmamusumeRefreshRatios[2]

    return {X: RefreshX, Y: RefreshY}
}

; -------------------------------------------------------------------------
; CLICK REFRESH (for when target not found)
clickOnFail(CoordX, CoordY) {
    f := 0
    if (!CoordX || !CoordY) 
    {
        CoordX := (pt := getRefreshCoordinates()).X, CoordY := pt.Y
        f := 1
    }

    MouseMove CoordX, CoordY
    Click
    return f
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

    ; DEBUG: Paginate OCR results if there are many blocks (optional)
    if (DEBUG)
    {
        page := 1
        pageSize := 10

        total := ocrResult.Length
        maxPage := Ceil(total / pageSize)

        while true
        {
            start := (page - 1) * pageSize + 1
            end := Min(page * pageSize, total)

            debugText := "OCR Page " page "/" maxPage "`n`n"

            if (end >= start)
            {
                Loop (end - start + 1)
                {
                    i := start + A_Index - 1
                    block := ocrResult[i]
                    if IsObject(block) && block.HasProp("text")
                        debugText .= i ": " block.text "`n"
                }
            }

            choice := MsgBox(debugText "`n`nNext page?", "OCR Debug", "YesNo")

            if (choice = "No")
                break

            page++
            if (page > maxPage)
                break
        } 
    }
    ; --- END DEBUG ---

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

    if !FoundMatch
    {
        ToolTip "Not found. Waiting..."

        MouseGetPos &OrigX, &OrigY
        clickOnFail(CoordX, CoordY)
        if jumpBack
        {
            Sleep 100
            MouseMove OrigX, OrigY
        }
    }

    Sleep sleept
}
return

F9::ExitApp()

; -------------------------------------------------------------------------
; CONFIG LOADER
; -------------------------------------------------------------------------
LoadConfig()
{
    global configPath

    if !FileExist(configPath)
    {
        default :=
        (
        "[FilePaths]`n"
        "sound=dat\goldshi-radar.wav`n"

        "`n[Settings]`n"
        "TargetText=Special Week, Silence Suzuka, Tokai Teio`n"
        "sleept=4100`n"
        "jumpBack=0`n"
        "CoordX=0`n"
        "CoordY=0`n"
        )

        FileAppend default, configPath
        MsgBox "Created default config.ini at:`n" configPath "`nPlease edit targets and run the script again.", "Config Created", 64
        return false
    }

    RawText := IniRead(configPath, "Settings", "TargetText", "")
    if (RawText = "")
    {
        MsgBox "Missing TargetText in config.ini", "Error", 16
        return false
    }

    TargetArray := StrSplit(RawText, ",")
    for i, v in TargetArray
        TargetArray[i] := Trim(v)

    sound := IniRead(configPath, "FilePaths", "sound", "")
    if (sound = "" || !FileExist(sound))
    {
        MsgBox "Invalid sound file.", "Error", 16
        return false
    }

    CoordX := (pt := getRefreshCoordinates()).X, CoordY := pt.Y
    sleept := IniRead(configPath, "Settings", "sleept", "")
    jumpBack := IniRead(configPath, "Settings", "jumpBack", "0")

    if (!IsNumber(CoordX) || !IsNumber(CoordY) || !IsNumber(sleept) || !IsNumber(jumpBack))
    {
        MsgBox "Invalid numeric values in config.ini", "Error", 16
        return false
    }

    return {
        TargetArray: TargetArray,
        sound: sound,
        CoordX: CoordX,
        CoordY: CoordY,
        sleept: sleept,
        jumpBack: jumpBack
    }
}