; https://stackoverflow.com/questions/43298908/how-to-add-administrator-privileges-to-autohotkey-script
;@Ahk2Exe-UpdateManifest 1
#SingleInstance Force
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
  try
  {
    if A_IsCompiled
      Run '*RunAs "' A_ScriptFullPath '" /restart'
    else
      Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
  }
  ExitApp
}

;Set Coord method
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

;Prevent overflow trigger
SetKeyDelay 500
;Prevent script hold user action
SendMode "Event"
SetTitleMatchMode "RegEx"
;設定圖標
I_Icon := "wotb.ico"
If FileExist(I_Icon)
    TraySetIcon(I_Icon)

/*
    ==========================================================
    Global Var
    ==========================================================
*/
Global white_color := "0xFFFFFF"
Global black_color := "0x000000"
;In Garage screen
Global Booster_btn_detail := {X:830, Y:100, Color:"0x3D990F"}
Global Battle_btn_detail := {X:970, Y:125, Color:"0xF6A815"}
Global Store_logo_detail := {X:1870, Y:30, Color:white_color}
Global Selected_tank_color1 := "0xFDA924"
Global Selected_tank_color2 := "0xFF9C00"

;Filter List
Global List_Pin_detail := {X:1095, Y:890, Color:white_color}
Global Double_booster_detail := {X:837, Y:887, Color:"0x991A0F"}

;In Battle
Global GTeam_Score_detail := {X:910, Y:0 , Color:black_color}
Global RTeam_Score_detail := {X:1010, Y:0 , Color:black_color}
Global Battle_Timer_detail := {X1:925, Y1:2, X2:994, Y2:29, Color:"0x505C66"}
Global Battle_Hp_detail := {X:855, Y:1055, Color:"0x3D990F"}

WinTitle := "ahk_exe wotblitz"

;Switch Status
Global ScenarioList := {InBattle:false, FilterOn:false, InGarage:false, BattleChat:false}

/*
    ==========================================================
    New Object
    ==========================================================
*/
Check_obj := Check()
garage_obj := Garage()
filter_obj := Garage.Filter()
battle_obj := Battle()
ScenarioMethod := ObjBindMethod(Check(), "Scenario")
/*
    ==========================================================
    Detection Timer
    ==========================================================
*/
;First Checking
Check_obj.GameActive
;Check is game active every 5 sec
SetTimer ObjBindMethod(Check(), "GameActive"), 5000
/*
    ==========================================================
    Functions
    ==========================================================
*/
IsColor(obj){
    return PixelGetColor(obj.X,obj.Y) == obj.Color ? true : false
}

AutoMoveClick(x, y, IsClick:=true, mode:="event"){
    MouseGetPos &CurrX, &CurrY
    if mode == "input"
        SendMode "Input"
    Click x, y, IsClick
    if IsClick > 0
        MouseMove CurrX, CurrY
    SendMode "Event"
}

class Check{
    IsInGarage(){
        if((IsColor(Booster_btn_detail) && IsColor(Store_logo_detail)) || (IsColor(Store_logo_detail) && IsColor(Battle_btn_detail))){
            ScenarioList.InGarage := true
        }else{
            ScenarioList.InGarage := false
        }
    }

    ;Filter In Garage 
    IsFilterOn(){
        if (IsColor(List_Pin_detail) && IsColor(Double_booster_detail)){
            ScenarioList.FilterOn := true
        }else{
            ScenarioList.FilterOn := false
        }
    }
    
    IsInBattle(){
        obj := Battle_Timer_detail
        Have_Timer := PixelSearch(&PosX1, &PosY1, obj.X1, obj.Y1, obj.X2, obj.Y2, obj.Color)
        if (IsColor(GTeam_Score_detail) && IsColor(RTeam_Score_detail) && Have_Timer){
            ScenarioList.InBattle := true
            ;this.IsBattleChatOn
        }else{
            ScenarioList.InBattle := false
        }
    }

    IsBattleChatOn(){
        if(!IsColor(Battle_Hp_detail)){
            ScenarioList.BattleChat := true
        }else
            ScenarioList.BattleChat := false
    }

    Scenario(){
        this.IsFilterOn(), this.IsInGarage(), this.IsInBattle()
    }

    ;Check is game window active
    GameActive(){
        if WinWaitActive(WinTitle,,5){
            this.Scenario
            ;Check In Game Screen every 500ms
            SetTimer ScenarioMethod, 500
            Suspend false
        }else{
            Suspend true
            SetTimer ScenarioMethod, 0
        }
    }
}

class Garage{
    MenuSelect(type){
        xpos := 55
        ypos := 175
        BlockInput true
        MouseGetPos &CurrX, &CurrY
        ;Switch to click
        switch type {
            case "profile":
                ypos += -110
            case "mail":
                ypos += 90 * 0
            case "tree":
                ypos += 90 * 1
            case "mission":
                ypos += 90 * 2
            case "storage":
                ypos += 90 * 3
            case "chat":
                ypos += 90 * 4
            case "clan":
                ypos += 90 * 5
            case "plat":
                ypos += 90 * 6
            case "tour":
                ypos += 90 * 7
            case "rooms":
                ypos += 90 * 8
            case "communities":
                ypos += 90 * 9
            case "setting":
                ypos := 1035
            default:
                
        }
        ;Scroll Up/down
        if ! (type ~= "setting")
            Click xpos, ypos, "WU", 2
        else
            Click xpos, ypos, "WD", 2
        sleep 50
        AutoMoveClick(xpos, ypos)
        MouseMove CurrX, CurrY
        BlockInput false
    }

    SelectGameMode(){
        AutoMoveClick(1130,120)
    }

    OpenStore(){
        AutoMoveClick(1865, 35)
    }

    BottomMenuSelect(choice){
        switch choice {
            case 1:      ;Shift + 1
                AutoMoveClick(540,890)
            case 2:      ;Shift + 2
                AutoMoveClick(670,890)
            case 3:      ;Shift + 3
                AutoMoveClick(810,890)
            case 4:      ;Shift + 4
                AutoMoveClick(970,890)
            case 5:      ;Shift + 5
                AutoMoveClick(1140,890)
            case 6:      ;Shift + 6
                AutoMoveClick(1300,890)
            case 7:      ;Shift + 7
                AutoMoveClick(1470,890)
            default:
                return
        }
    }

    GetTankPos(adjusted := false){
        SendMode "Input"
        Re_search:
        PixelSearch(&PosX1, &PosY1, 110, 1075, 1830, 1079, Selected_tank_color1)
        PixelSearch(&PosX2, &PosY2, 110, 1075, 1830, 1079, Selected_tank_color2)
        ;Set value to 9999 if not found
        XYarr := [PosX1, PosX2, PosY1, PosY2]
        for index, val in XYarr{
            if(val = ""){
                XYarr[index] := 9999
            }
        }
        Tank := {PosX : Min(XYarr[1], XYarr[2]), PosY : Min(XYarr[3], XYarr[4])}
        ;Reset Tank Position
        if(Tank.PosX ~= 9999 || Tank.PosY ~= 9999){
            this.SelectGameMode()
            Send "{Esc}"
            Sleep 70
            adjusted := true
            goto Re_search
        }
        ;Check if need to adjust
        WinGetClientPos(&_,&_,&Clientwidth,&_, "ahk_exe wotblitz")
        if(Tank.PosX - 115 > 0 && Tank.PosX + 210 < Clientwidth)
            adjusted := true
        ;Each tank icon width 210px, middle pt is +105, next tank is +315
        ;Each tank icon height 134px, middle pt is +67
        ;adjust tank position
        Tank.PosY -= 67
        if(!adjusted){
            AutoMoveClick(Tank.PosX+1, Tank.PosY, false)
            Click
            Sleep 700
            adjusted := true
            goto Re_search
        }else{
            ;Center the cursor on tank icon
            Tank.PosX += 105
            AutoMoveClick(Tank.PosX, Tank.PosY, false)
        }
        SendMode "Event"
        return Tank
    }

    class Filter{
        SelectTier(tier){
            xpos := 655
            ypos := 775
            if tier != 0{
                xpos += 80 * tier - 80
            }else
                xpos += 80 * 10 - 80

            /*Select Nations (When Capslock On) */
            if GetKeyState("CapsLock", "T"){
                this.SelectNations(tier-1)
                return
            }
            AutoMoveClick(xpos, ypos,,"input")
        }

        SelectType(type){
            xpos := 495 + 80 * type
            ypos := 895
            AutoMoveClick(xpos, ypos,,"input")
        }

        SelectPinned(){
            AutoMoveClick(1095, 895,,"input")
        }

        SelectNations(type){
            xpos := 615 + 100 * type
            ypos := 1015
            AutoMoveClick(xpos, ypos,,"input")
        }
    }
}

class Battle{
    PressSector(zone){
        xpos := 50
        ypos := 825
        row := (Mod(zone, 3) != 0) ? zone // 3 : zone // 3 - 1
        col := (Mod(zone, 3) != 0) ? Mod(zone, 3) - 1 : 3 - 1
        xpos += 100 * col
        ypos += 100 * row
        SendInput "{LControl Down}"
        AutoMoveClick(xpos, ypos,,"input")
        Send "{LControl Up}"
    }
}
/*
    ==========================================================
    Hotkey (Main Part)
    ==========================================================
*/
;Hotkey when in garage
#HotIf ScenarioList.InGarage && WinActive(WinTitle)
   /*Bottom menu part*/
    ;Crew
    +1::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(1)
    }

    ;Rank
    +2::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(2)
    }

    ;CAMO
    +3::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(3)
    }

    ;Consumables
    +4::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(4)
    }

    ;Provisions
    +5::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(5)
    }

    ;Ammo
    +6::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(6)
    }

    ;Equipent
    +7::
    {
        KeyWait "LShift"
        garage_obj.BottomMenuSelect(7)
    }
    
    ;Select game mode
    Space::
    {
        garage_obj.SelectGameMode()
        return
    }

    /*Left::
    {   
        KeyWait "Left"
        TankIcon := garage_obj.GetTankPos()
    }*/

    /*Side menu part*/
    `::{
        KeyWait "``"
        garage_obj.MenuSelect("profile")
    }

    ~::{
        KeyWait "Shift"
        garage_obj.OpenStore()
    }

    ;Open mail (Shift+m)
    +m::{
        KeyWait "Shift"
        garage_obj.MenuSelect("mail")
    }

    ;Open Tech tree
    t::{
        KeyWait "t"
        garage_obj.MenuSelect("tree")
    }

    ;Open mission
    m::{
        KeyWait "m"
        garage_obj.MenuSelect("mission")
    }

    ;Open storage (Shift + S)
    +s::{
        KeyWait "Shift"
        garage_obj.MenuSelect("storage")
    }

    ;Open Chat
    c::{
        KeyWait "c"
        garage_obj.MenuSelect("chat")
    }

    ;Open Clan (Alt + C)
    !c::{
        KeyWait "Alt"
        garage_obj.MenuSelect("clan")
    }

    ;Open Platoon 
    p::{
        KeyWait "p"
        garage_obj.MenuSelect("plat")
    }

    ;Open Tour (Shift + T)
    +t::{
        KeyWait "Shift"
        garage_obj.MenuSelect("tour")
    }

    ;Open tranning room
    r::{
        KeyWait "r"
        garage_obj.MenuSelect("rooms")
    }

    ;Open Communities (Shift + C)
    +c::{
        KeyWait "Shift"
        garage_obj.MenuSelect("communities")
    }

    ;Open setting
    s::{
        KeyWait "s"
        garage_obj.MenuSelect("setting")
    }
#HotIf 

;Hotkey only work when filter is on
#HotIf ScenarioList.FilterOn && WinActive(WinTitle)
/*The Tier selection part*/
/*Select Nations (When Capslock On) */
1::{
    filter_obj.SelectTier(A_ThisHotkey)
}
2::{
    filter_obj.SelectTier(A_ThisHotkey)
}
3::{
    filter_obj.SelectTier(A_ThisHotkey)
}
4::{
    filter_obj.SelectTier(A_ThisHotkey)
}
5::{
    filter_obj.SelectTier(A_ThisHotkey)
}
6::{
    filter_obj.SelectTier(A_ThisHotkey)
}
7::{
    filter_obj.SelectTier(A_ThisHotkey)
}
8::{
    filter_obj.SelectTier(A_ThisHotkey)
}
9::{
    filter_obj.SelectTier(A_ThisHotkey)
}
0::{
    filter_obj.SelectTier(A_ThisHotkey)
}

/*Select Tank Type */
h::{
    filter_obj.SelectType(0)
}
j::{
    filter_obj.SelectType(1)
}
k::{
    filter_obj.SelectType(2)
}
l::{
    filter_obj.SelectType(3)
}

;Pinned tank
p::{
    if GetKeyState("CapsLock", "T"){
        filter_obj.SelectPinned
    }else{
        garage_obj.MenuSelect("plat")
    }
}

~CapsLock::{
    if GetKeyState("CapsLock", "T")
        ToolTip "Capslock is on"
    else
        ToolTip "Capslock is off"
    sleep 1500
    ToolTip
}
#HotIf

;Hotkey only work when in battle
#HotIf ScenarioList.InBattle && !ScenarioList.BattleChat && WinActive(WinTitle)
~`::{
    if !KeyWait("``", "T0.3"){
        ToolTip "forward On"
        if GetKeyState("w", "P"){
            KeyWait("w")
        }
        Send "{w down}"
        sleep 500
        ToolTip
    }
}

~s::
{
    If ! GetKeyState("w", "P")
    {
        Send "{w up}"
    }
}

/*Select sector (Only work with the BIG/Mid Size map)*/
Numpad1::{
    battle_obj.PressSector(1)
}
Numpad2::{
    battle_obj.PressSector(2)
}
Numpad3::{
    battle_obj.PressSector(3)
}
Numpad4::{
    battle_obj.PressSector(4)
}
Numpad5::{
    battle_obj.PressSector(5)
}
Numpad6::{
    battle_obj.PressSector(6)
}
Numpad7::{
    battle_obj.PressSector(7)
}
Numpad8::{
    battle_obj.PressSector(8)
}
Numpad9::{
    battle_obj.PressSector(9)
}

;Auto shoot when hold MButton
*MButton::{
    Loop{
        Send "{Click}"
    }Until KeyWait("MButton", "T0.1")
}

;Toggle script on/off
; Press Alt+N to toggle on/off
#SuspendExempt 
~!n::
{
    Suspend
    ToolTip a_isSuspended ? "script now stopped":"script now running"
    SetTimer ObjBindMethod(Check(), "GameActive"), (A_IsSuspended) == 1 ? 0 : 5000
    Sleep 3000
    ToolTip
}
#SuspendExempt false
#HotIf