;@Ahk2Exe-SetName         AutoRunner
;@Ahk2Exe-SetVersion      0.10.0
;@Ahk2Exe-SetDescription  AutoRuns script located in \autoruns of specified directories
;@Ahk2Exe-SetCopyright    Copyright (c) 2020 Pandu POLUAN <pepoluan@gmail.com>
;@Ahk2Exe-SetCompanyName  pepoluan
;@Ahk2Exe-SetOrigFilename AutoRunner.ahk
;@Ahk2Exe-SetMainIcon     AutoRunner.ico
;@Ahk2Exe-ExeName         AutoRunner.exe

; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; Icons made by [Icongeek26](https://www.flaticon.com/authors/icongeek26)
; from [www.flaticon.com](https://www.flaticon.com/)
; used under the "Flaticon License"

#NoEnv
#Warn
#SingleInstance, force

; ==== Notes =====
; * All braces indented using "Whitesmiths" style. Because it looks like Python ;-)
; * All function & class declarations are at the END of this file


; ========== TEST HARNESS ==========


TEST_MODE := False
if (TEST_MODE)
    {
    ; Comment/uncomment as needed
    ; A_Args.Push("--exts")
    ; A_Args.Push("lnk,exe,txt")
    ; A_Args.Push("S:")
    ; A_Args.Push("D:")
    ; A_Args.Push("UIU:")
    ; A_Args.Push("T:")
    }


; ========== PARAMETERS SETUP ==========


AutorunsDrives := []
AutorunsExts := []
AutorunsDir := "\autoruns"
UnknownParams := []
skip_next := False
For n, param in A_Args
    {
    If (skip_next)
        {
        skip_next := False
        }
    Else If (param == "--exts")
        {
        AutorunsExts := StrSplit(A_Args[n+1], ",")
        skip_next := True
        }
    Else If (param == "--dir")
        {
        AutorunsDir := A_Args[n+1]
        skip_next := True
        }
    Else If (RegExMatch(param, "^[a-zA-Z]:"))
        {
        AutorunsDrives.Push(param)
        }
    Else
        UnknownParams.Push(param)
    }

If (UnknownParams.Length() > 0)
    {
    MsgBox, 16, AutoRunner, % "ERROR: Unrecognized parameters:`n`n" . Join(" ", UnknownParams)
    ExitApp, 1
    }

If (AutorunsDrives.Length() < 1)
    {
    MsgBox, 16, AutoRunner, % "ERROR: Please specify drives to autorun!"
    ExitApp, 1
    }

If (AutorunsExts.Length() < 1)
    {
    AutorunsExts.Push("lnk")
    }

; Both of these in SECONDS
WaitDelay := 0.2
LaunchDelay := 5.0


; ========== GUI SETUP ==========


guiX := A_ScreenWidth // 6
guiY := A_ScreenHeight // 5

Gui, New
Gui, -Resize -MinimizeBox -MaximizeBox
Gui, Add, GroupBox, w300 h25
Gui, Add, Progress, xp+5 yp+10 wp-10 hp-15 vSpin, 0
Gui, Add, Edit, xp-5 y+15 r9 wp+10 +ReadOnly vActiv
Gui, Add, StatusBar, vStatBar,

Gui, Show, x%guiX% y%guiY%

; Catch event of user closing GUI box by clicking the "X"
GuiClose(GuiHwnd)
    {
    ExitApp
    }

sb_elapsed := new StatusBarTimeElapsed("StatBar")
spinner := new SpinnerObj("Spin", sb_elapsed)
activities := new ActivityList("Activ", sb_elapsed)


; ========== LOGIC PROPER ==========


activities.Update("Invoked with parameters:")
activities.Update("`nDrives: " . Join(" ", AutorunsDrives))
activities.Update("`nDirectory: " . AutorunsDir)
activities.Update("`nExts: " . Join(" ", AutorunsExts))
activities.Update("`n-----`n")


For index, drv in AutorunsDrives
    {
    activities.Update("Waiting for drive " . drv . "...")
    While !FileExist(drv . "\")
        {
        Sleep % WaitDelay * 1000
        spinner.Spin()
        }
    activities.Update(" done.`n")
    }
spinner.Finish()


activities.Update("Retrieving autorun targets...")
all_to_start := []
For index, drv in AutorunsDrives
    {
    arpath := drv . AutorunsDir
    If (!FileExist(arpath))
        {
        activities.Update("`n" . arpath . " does not exist, skipping")
        Continue
        }
    drv_to_start := []
    For _, ext in AutorunsExts
        {
        Loop, Files, % arpath . "\*." . ext
            {
            drv_to_start.Push(A_LoopFileLongPath)
            sb_elapsed.Update()
            }
        }
    ; Sort per-drive autorun targets...
    Sort, drv_to_start
    ; ... but maintain the drive order as specified in params
    all_to_start.Push(drv_to_start*)
    }    
activities.Update("`nFound " . all_to_start.Length() . " autorun targets")


If (all_to_start.Length() == 0)
    {
    activities.Update("`nNo autorun targets to launch.")
    }
Else
    {
    For _, fpath in all_to_start
        {
        activities.Update("`nExecuting " . fpath)
        If (!TEST_MODE)
            {
            Run, %fpath%
            }
        sb_elapsed.SleepSec(LaunchDelay)
        }
    activities.Update("`nAll autorun targets launched.")
    }

activities.Update("`nExiting in 5 seconds...")
sb_elapsed.SleepSec(5)
Gui, Destroy
ExitApp


; ========== FUNCTIONS & CLASSES ==========


; Ref: https://www.autohotkey.com/boards/viewtopic.php?p=122129#p122129
Join(sep, params)
    {
    local
    out := ""
    For _, elem in params
        out .= sep . elem
    Return SubStr(out, 1 + StrLen(sep))
    }

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
    {
    local
    NumberOfSeconds := Floor(NumberOfSeconds)
    time := 19990101  ; *Midnight* of an arbitrary date.
    time += NumberOfSeconds, seconds
    FormatTime, mmss, %time%, mm:ss
    return NumberOfSeconds//3600 ":" mmss
    /*
    ; Unlike the method used above, this would not support more than 24 hours worth of seconds:
    FormatTime, hmmss, %time%, h:mm:ss
    return hmmss
    */
    }


class SpinnerObj
    {
    Increment := 5

    __New(ProgressLabel, SBElapsedObject)
        {
        this.sb := SBElapsedObject
        this.pg := ProgressLabel
        this.val := 0
        }

    Spin()
        {
        this.val += this.Increment
        If (this.val > 100)
            {
            this.val -= 100
            }
        GuiControl, , % this.pg, % this.val
        this.sb.Update()
        }
    
    Finish()
        {
        this.val := 100 - this.Increment
        this.Spin()
        }
    }


class StatusBarTimeElapsed
    {
    SleepUpdateMsec := 200

    __New(StatusBarLabel)
        {
        this.sb := StatusBarLabel
        this.started := A_Now
        }
    
    Update()
        {
        t := A_Now
        t -= this.started, seconds
        newtext := "  " . FormatSeconds(t)
        GuiControlGet, oldtext, , % this.sb,
        If (newtext != oldtext)
            {
            SB_SetText(newtext)
            }
        }

    SleepSec(seconds)
        {
        Loop, % Floor(seconds * (1000 / this.SleepUpdateMsec))
            {
            Sleep, % this.SleepUpdateMsec
            this.Update()
            }
        }
    }


class ActivityList
    {
    __New(EditBoxLabel, SBElapsedObject)
        {
        this.sb := SBElapsedObject
        this.ebox := EditBoxLabel
        this.text := ""
        }

    Update(addText)
        {
        this.text .= addText
        GuiControl, , % this.ebox, % this.text
        ControlFocus, % this.ebox
        Send, ^{End}
        this.sb.Update()
        }
    }
