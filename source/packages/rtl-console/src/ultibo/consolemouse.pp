{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    Mouse unit for Ultibo

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit ConsoleMouse;

interface

{$i mouseh.inc}

implementation

uses
 GlobalConst,GlobalConfig,GlobalTypes,Platform,Mouse,Framebuffer,Console,Types,Classes,SysUtils;
 
{$i mouse.inc}

var
 MouseX:LongInt;
 MouseY:LongInt;
 MouseLast:TMouseEvent;
 
 ConsoleDevice:PConsoleDevice = nil;
 ConsoleProperties:TConsoleProperties;
 
 WindowRect:TRect;
 WindowProperties:TWindowProperties;

 FramebufferDevice:PFramebufferDevice = nil;
 
procedure TranslateMouse(const Data:TMouseData;var MouseEvent:TMouseEvent;Poll:Boolean);
var
 X:LongInt;
 Y:LongInt;
 Buttons:LongWord;
 MousePoint:TPoint;
begin
 {Get X and Y}
 X:=MouseX;
 Y:=MouseY;
 
 {Update X}
 if (Data.Buttons and MOUSE_ABSOLUTE_X) <> 0 then
  begin
   {Absolute}
   X:=Data.OffsetX;
  end
 else
  begin
   {Relative}
   X:=X + Data.OffsetX;
  end;  
 if X < 0 then X:=0;
 if X > (ConsoleProperties.Width - 1) then X:=ConsoleProperties.Width - 1;
 
 {Update Y}
 if (Data.Buttons and MOUSE_ABSOLUTE_Y) <> 0 then
  begin
   {Absolute}
   Y:=Data.OffsetY;
  end
 else
  begin
   {Relative}
   Y:=Y + Data.OffsetY;
  end;  
 if Y < 0 then Y:=0;
 if Y > (ConsoleProperties.Height - 1) then Y:=ConsoleProperties.Height - 1;
 
 {Update Buttons}
 Buttons:=0;
 if (Data.Buttons and (MOUSE_LEFT_BUTTON or MOUSE_TOUCH_BUTTON)) <> 0 then
  begin
   Buttons:=Buttons or MouseLeftButton;
  end;
 if (Data.Buttons and MOUSE_MIDDLE_BUTTON) <> 0 then
  begin
   Buttons:=Buttons or MouseMiddleButton;
  end;
 if (Data.Buttons and MOUSE_RIGHT_BUTTON) <> 0 then
  begin
   Buttons:=Buttons or MouseRightButton;
  end;
 
 {Get Mouse Point}
 MousePoint:=Point(X,Y);
 
 {Check Mouse Point}
 if PtInRect(WindowRect,MousePoint) then
  begin
   {Get X and Y}
   MouseEvent.x:=(X - WindowRect.Left) div WindowProperties.FontWidth;
   MouseEvent.y:=(Y - WindowRect.Top) div WindowProperties.FontHeight;
   
   {Get Buttons} 
   MouseEvent.Buttons:=Buttons;
   
   {Check Move}
   if (MouseLast.x <> MouseEvent.x) or (MouseLast.y <> MouseEvent.y) then
    begin
     MouseEvent.Action:=MouseActionMove;
    end;
   
   {Check Buttons} 
   if MouseLast.Buttons <> MouseEvent.Buttons then
    begin
     if (MouseLast.Buttons and MouseEvent.Buttons) <> MouseLast.Buttons then
      begin
       MouseEvent.Action:=MouseActionUp;
      end 
     else
      begin
       MouseEvent.Action:=MouseActionDown;
      end; 
    end;
   
   {Check Action}
   if not(Poll) and (MouseEvent.Action <> 0) then
    begin
     MouseLast:=MouseEvent;
    end;
  end;  
  
 {Check Poll}
 if not(Poll) then
  begin
   MouseX:=X;
   MouseY:=Y;
   
   {Update Mouse}
   if ConsoleDevice <> nil then
    begin
     if FramebufferDevice <> nil then
      begin
       {Framebuffer Cursor}
       FramebufferDeviceUpdateCursor(FramebufferDevice,True,MouseX,MouseY,False);
      end
     else
      begin
       {Console Cursor}
       ConsoleDeviceUpdateCursor(ConsoleDevice,True,MouseX,MouseY,False);
      end;      
    end;  
  end;
end;


procedure SysInitMouse;
var
 X1:LongWord;
 Y1:LongWord;
 X2:LongWord;
 Y2:LongWord;
 WorkBuffer:String;
begin
 {Check Environment Variables}
 {CONSOLE_VIDEO_DEVICE}
 WorkBuffer:=SysUtils.GetEnvironmentVariable('CONSOLE_VIDEO_DEVICE');
 if Length(WorkBuffer) <> 0 then CONSOLE_VIDEO_DEVICE:=WorkBuffer;
 
 {Check Device}
 ConsoleDevice:=nil;
 FramebufferDevice:=nil;
 if Length(CONSOLE_VIDEO_DEVICE) <> 0 then
  begin
   {Get By Name}
   ConsoleDevice:=ConsoleDeviceFindByName(CONSOLE_VIDEO_DEVICE);
   if ConsoleDevice = nil then
    begin
     {Get By Description}
     ConsoleDevice:=ConsoleDeviceFindByDescription(CONSOLE_VIDEO_DEVICE);
    end;
  end
 else
  begin
   {Get Default Device}
   ConsoleDevice:=ConsoleDeviceGetDefault;
  end;    
 
 {Check Console Device}
 if ConsoleDevice <> nil then
  begin
   {Check Type}
   if ConsoleDevice^.Device.DeviceType = CONSOLE_TYPE_FRAMEBUFFER then
    begin
     {Check Framebuffer}
     if FramebufferDeviceCheck(PFramebufferConsole(ConsoleDevice)^.Framebuffer) <> nil then
      begin
       {Get Framebuffer}
       FramebufferDevice:=PFramebufferConsole(ConsoleDevice)^.Framebuffer;
      end;
    end;
    
   {Get Properties}
   if ConsoleDeviceGetProperties(ConsoleDevice,@ConsoleProperties) = ERROR_SUCCESS then
    begin
     {Check Console Window}
     if CONSOLE_VIDEO_WINDOW <> INVALID_HANDLE_VALUE then
      begin
       {Get Properties}
       if ConsoleWindowGetProperties(CONSOLE_VIDEO_WINDOW,@WindowProperties) = ERROR_SUCCESS then
        begin
         {Setup Mouse}
         FillChar(LastMouseEvent,SizeOf(TMouseEvent),0);
         LastMouseEvent.x:=0;
         LastMouseEvent.y:=0;
         LastMouseEvent.Buttons:=0;
         
         MouseX:=0;
         MouseY:=0;
         FillChar(MouseLast,SizeOf(TMouseEvent),0);
         
         {Get Window Rect}
         X1:=WindowProperties.X1 + WindowProperties.Borderwidth + WindowProperties.OffsetX;
         Y1:=WindowProperties.Y1 + WindowProperties.Borderwidth + WindowProperties.OffsetY;
         X2:=X1 + (WindowProperties.Width * WindowProperties.FontWidth);
         Y2:=Y1 + (WindowProperties.Height * WindowProperties.FontHeight);
         WindowRect:=Rect(X1,Y1,X2,Y2);

         {Enable Cursor}
         if FramebufferDevice <> nil then
          begin
           {Framebuffer Cursor}
           FramebufferDeviceSetCursor(FramebufferDevice,0,0,0,0,nil,0);
           
           FramebufferDeviceUpdateCursor(FramebufferDevice,True,MouseX,MouseY,False);
          end
         else
          begin
           {Console Cursor}
           ConsoleDeviceSetCursor(ConsoleDevice,0,0,nil);
           
           ConsoleDeviceUpdateCursor(ConsoleDevice,True,MouseX,MouseY,False);
          end;
         
         {Show Mouse}
         ShowMouse;
        end;
      end;
    end; 
  end;
end;


procedure SysDoneMouse;
begin
 {Hide Mouse}
 HideMouse;
 
 {Disable Cursor}
 if ConsoleDevice <> nil then
  begin
   if FramebufferDevice <> nil then
    begin
     {Framebuffer Cursor}
     FramebufferDeviceUpdateCursor(FramebufferDevice,False,MouseX,MouseY,False);
    end
   else
    begin
     {Console Cursor}
     ConsoleDeviceUpdateCursor(ConsoleDevice,False,MouseX,MouseY,False);
    end;    
  end;
end;


function SysDetectMouse:byte;
begin
 SysDetectMouse:=2;
end;


function SysGetMouseX:word;
begin
 SysGetMouseX:=LastMouseEvent.x;
end;


function SysGetMouseY:word;
begin
 SysGetMouseY:=LastMouseEvent.y;
end;


function SysGetMouseButtons:word;
begin
 SysGetMouseButtons:=LastMouseEvent.Buttons;
end;


procedure SysGetMouseEvent(var MouseEvent: TMouseEvent);
var
 Count:LongWord;
 Data:TMouseData;
begin
 FillChar(MouseEvent,SizeOf(TMouseEvent),0);
 
 {Read Next Mouse Data}
 if MouseRead(@Data,SizeOf(TMouseData),Count) = ERROR_SUCCESS then
  begin
   {Translate Mouse}
   TranslateMouse(Data,MouseEvent,False);
   
   {Update Last}
   LastMouseEvent:=MouseEvent;
  end;
end;


function SysPollMouseEvent(var MouseEvent: TMouseEvent):boolean;
var
 Count:LongWord;
 Data:TMouseData;
begin
 FillChar(MouseEvent,SizeOf(TMouseEvent),0);
 
 {Peek Next Mouse Data}
 if MouseReadEx(@Data,SizeOf(TMouseData),MOUSE_FLAG_NON_BLOCK or MOUSE_FLAG_PEEK_BUFFER,Count) = ERROR_SUCCESS then
  begin
   {Translate Mouse}
   TranslateMouse(Data,MouseEvent,True);
   
   SysPollMouseEvent:=True;
  end
 else
  begin 
   SysPollMouseEvent:=False;
  end;
end;


procedure SysPutMouseEvent(const MouseEvent: TMouseEvent);
begin
 {Nothing}
end;


const
 SysMouseDriver : TMouseDriver = (
  UseDefaultQueue : False;
  InitDriver      : @SysInitMouse;
  DoneDriver      : @SysDoneMouse;
  DetectMouse     : @SysDetectMouse;
  ShowMouse       : nil;
  HideMouse       : nil;
  GetMouseX       : @SysGetMouseX;
  GetMouseY       : @SysGetMouseY;
  GetMouseButtons : @SysGetMouseButtons;
  SetMouseXY      : nil;
  GetMouseEvent   : @SysGetMouseEvent;
  PollMouseEvent  : @SysPollMouseEvent;
  PutMouseEvent   : @SysPutMouseEvent;
 );

begin
 SetMouseDriver(SysMouseDriver);
end.
