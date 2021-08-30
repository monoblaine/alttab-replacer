;OPTIMIZATIONS START
#NoTrayIcon
#NoEnv
#KeyHistory 0
ListLines Off
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
;OPTIMIZATIONS END

hModule := DllCall("LoadLibrary", Str, "..\lib\UWPIconExtractor.dll", Ptr)
procHandle := DllCall("GetProcAddress", Ptr, hModule, AStr, "getFileName", Ptr)
defaultImageHandle := LoadPicture(A_WinDir . "\System32\SHELL32.dll", "w32 Icon3", defaultImageHandleType)
ImageHandles := []

OnExit, Exit
return

Exit:
   DllCall("FreeLibrary", Ptr, hModule)
   DllCall("CloseHandle", Ptr, procHandle)
   FreeImageHandle(defaultImageHandle, defaultImageHandleType)
   FreeMenuIconHandles()
   ImageHandles := ""

   ExitApp

FreeImageHandle(byref handle, handleType) {
    if (not handleType) {
        DllCall("DeleteObject", Ptr, handle)
    }
    else if (handleType = 1) {
        DllCall("DestroyIcon", Ptr, handle)
    }
    else if (handleType = 2) {
        DllCall("DestroyCursor", Ptr, handle)
    }
}

FreeMenuIconHandles() {
    for index, obj in ImageHandles {
        FreeImageHandle(obj.handle, obj.handleType)
    }
}

~LAlt & Tab::
Menu, altTabMenu, Add
Menu, altTabMenu, deleteAll

FreeMenuIconHandles()
ImageHandles := []
menuCount := 0

WinGet windowList, List

loop %windowList% {
    winAhkId := windowList%A_Index%

    WinGetTitle winTitle, ahk_id %winAhkId%

    if (winTitle = "") {
        continue
    }

    WinGetClass winClass, ahk_id %winAhkId%
    WinGet, winStyle, Style, ahk_id %winAhkId%

    isUWP := winClass = "ApplicationFrameWindow"

    if (isUWP) {
        WinGetText, winText, ahk_id %winAhkId%

        if (winText = "" && !(winStyle = "0xB4CF0000")) {
            continue
        }
    }

    if !(winStyle & 0xC00000) { ; if the window doesn't have a title bar
        ; If title not contains ...  ; add exceptions
        continue
    }

    menuCount++

    menuHandler := Func("Activate_Window").Bind(winAhkId)

    Menu, altTabMenu, Insert, , %winTitle%, %menuHandler%

    menuItemByPosAccessor := menuCount . "&"

    WinGet, pathToProcess, ProcessPath, ahk_id %winAhkId%

    if (isUWP = 0 && (menuIconHandle := LoadPicture(pathToProcess, "w32 Icon1", imageHandleType))) {
        ImageHandles.Push({ handle: menuIconHandle, handleType: imageHandleType })
        Menu, altTabMenu, Icon, %menuItemByPosAccessor%, hicon:*%menuIconHandle%, , 0
        menuIconHandle := ""
    }
    else if ((hWnd_coreWindow := GetChildWinByClass(winAhkId, "Windows.UI.Core.CoreWindow"))) {
        iconFileName := DllCall(procHandle, Ptr, hWnd_coreWindow, "Cdecl AStr")

        DllCall("CloseHandle", Ptr, hWnd_coreWindow)
        hWnd_coreWindow := ""

        Menu, altTabMenu, Icon, %menuItemByPosAccessor%, %iconFileName%, , 0
    }
    else {
        Menu, altTabMenu, Icon, %menuItemByPosAccessor%, hicon:*%defaultImageHandle%, , 0
    }
}

if (menuCount > 1) {
    Run, Down2Times.exe
}
else if (menuCount = 1) {
    Run, Down1Time.exe
}

Menu, altTabMenu, Show

return

Activate_Window(ahkId) {
    WinActivate, ahk_id %ahkId%
}

GetChildWinByClass(hParent, childClass) {
    hWnd := DllCall("GetWindow", Ptr, hParent, UInt, 5, Ptr) ; GW_CHILD=5

    Loop {
        WinGetClass, winClass, ahk_id %hWnd%

        if (winClass = childClass) {
            return hWnd
        }

        DllCall("CloseHandle", Ptr, hWnd)
        hWnd := DllCall("GetWindow", Ptr, hWnd, UInt, 2, Ptr) ; GW_HWNDNEXT=2
    } Until !hWnd
}
