;@Ahk2Exe-SetName         AutoRunner
;@Ahk2Exe-SetVersion      0.9.6
;@Ahk2Exe-SetDescription  AutoRuns script located in \autoruns of specified directories
;@Ahk2Exe-SetCopyright    Copyright (c) 2020 Pandu POLUAN <pepoluan@gmail.com>
;@Ahk2Exe-SetCompanyName  pepoluan
;@Ahk2Exe-SetOrigFilename AutoRunner.ahk
;@Ahk2Exe-SetMainIcon     AutoRunner.ico
;@Ahk2Exe-ExeName         AutoRunner.exe

; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#NoEnv
#Warn
#SingleInstance, force

; ==== Notes =====
; * All braces indented using "Whitesmiths" style. Because it looks like Python ;-)
; * All function & class declarations are at the END of this file

AutorunsDrives := A_Args
; Uncomment next line for debugging
; AutorunsDrives := [ "S:", "T:" ]
AutorunsDir := "\autoruns"

; Both of these in SECONDS
WaitDelay := 0.2
LaunchDelay := 5.0

If (AutorunsDrives.Length() < 1)
    {
    MsgBox, 16, AutoRunner, % "ERROR: Please specify drives to autorun!"
    ExitApp, 1
    }

guiX := A_ScreenWidth // 6
guiY := A_ScreenHeight // 5

Gui, New
Gui, -Resize -MinimizeBox -MaximizeBox
Gui, Add, GroupBox, w300 h25
Gui, Add, Progress, xp+5 yp+10 wp-10 hp-15 vSpin, 0
Gui, Add, Edit, xp-5 y+15 r6 wp+10 +ReadOnly vActiv
Gui, Add, StatusBar, ,

Gui, Show, x%guiX% y%guiY%

; Catch event of user closing GUI box by clicking the "X"
GuiClose(GuiHwnd)
    {
    ExitApp
    }

sb_elapsed := new StatusBarTimeElapsed()
spinner := new SpinnerObj("Spin", sb_elapsed)
activities := new ActivityList("Activ", sb_elapsed)


Sort, AutorunsDrives
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


activities.Update("Retrieving autorun links...")
lnkFiles := []
For index, drv in AutorunsDrives
    {
    arpath := drv . AutorunsDir
    If (!FileExist(arpath))
        {
        activities.Update("`n" . arpath . " does not exist, skipping")
        Continue
        }
    Loop, Files, % arpath . "\*.lnk"
        {
        lnkFiles.Push(A_LoopFileLongPath)
        sb_elapsed.Update()
        }
    }
activities.Update("`nFound " . lnkFiles.Length() . " link files")


If (lnkFiles.Length() == 0)
    {
    activities.Update("`nNo link files to execute.`nExiting in 5 seconds...")
    sb_elapsed.SleepSec(5)
    Gui, Destroy
    ExitApp
    }


Sort, lnkFiles
For index, fpath in lnkFiles
    {
    activities.Update("`nExecuting " . fpath)
    Run, %fpath%
    sb_elapsed.SleepSec(LaunchDelay)
    }


activities.Update("`nAll autoruns launched.`nExiting in 5 seconds...")
sb_elapsed.SleepSec(5)
Gui, Destroy
ExitApp


; ========== FUNCTIONS & CLASSES ==========


FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
    {
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

    __New()
        {
        this.started := A_Now
        }
    
    Update()
        {
        t := A_Now
        t -= this.started, seconds
        SB_SetText("  " . FormatSeconds(t))
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
