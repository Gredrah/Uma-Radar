#SingleInstance Force
SetBatchLines, -1
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

#Include FindText.ahk

IniRead, TargetFolder, config.ini, FilePaths, target
IniRead, sound, config.ini, FilePaths, sound

CachedTargets := ""

Loop, Files, %TargetFolder%\*.*
{
    CachedTargets .= "|<" . A_LoopFileName . ">" . FindText().GetTextFromFiles(A_LoopFileFullPath)
}

F8::
Loop
{
    Click, 795, 898
    Sleep, 4100

    if (findTextResult := FindText(0, 0, A_ScreenWidth, A_ScreenHeight, 0.1, 0.1, CachedTargets, , , 1, 1.5, 0.5))
    {
        TargetX := findTextResult[1].x
        TargetY := findTextResult[1].y
        MatchedName := findTextResult[1].id

        SoundPlay, %sound%
        TrayTip, Target Found, %MatchedName% located!, 10, 1
        MsgBox, %MatchedName% found at %TargetX%, %TargetY%!
        ExitApp
    }

    FoundViaBackup := false
    Loop, Files, %TargetFolder%\*.*
    {
        ImageSearch, FoundX, FoundY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *110 *w-1 *h-1 %A_LoopFileFullPath%
        if (ErrorLevel = 0)
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
        SoundPlay, %sound%
        MsgBox, %MatchedName% found via Backup ImageSearch at %TargetX%, %TargetY%!
        ExitApp
    }

    MouseGetPos, MouseX, MouseY
    ToolTip, No match found, % MouseX + 20, % MouseY + 20
    Sleep, 1000
    ToolTip
    
    Sleep, 500
}
return

F9::ExitApp