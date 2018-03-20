{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    Video unit for Ultibo

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit ConsoleVideo;

interface

{$i videoh.inc}

implementation

uses
 GlobalConst,GlobalConfig,GlobalTypes,Console,Font,Default8x16,SysUtils;

{$i video.inc}

var
 WindowCreate:Boolean;
 WindowHandle:TWindowHandle = INVALID_HANDLE_VALUE;
 ConsoleDevice:PConsoleDevice = nil;
 ConsoleBuffer:array of TConsoleChar;
 
var {Source: http://www.shikadi.net/moddingwiki/EGA_Palette}
 ConsoleColors:array[0..15] of LongWord = (
  {Foreground and background colors}
  $FF000000,       {Black}
  $FF0000AA,       {Blue}
  $FF00AA00,       {Green}
  $FF00AAAA,       {Cyan}
  $FFAA0000,       {Red}
  $FFAA00AA,       {Magenta}
  $FFAA5500,       {Brown}
  $FFAAAAAA,       {LightGray}
  {Foreground colors}
  $FF555555,       {DarkGray}
  $FF5555FF,       {LightBlue}
  $FF55FF55,       {LightGreen}
  $FF55FFFF,       {LightCyan}
  $FFFF5555,       {LightRed}
  $FFFF55FF,       {LightMagenta}
  $FFFFFF55,       {Yellow}
  $FFFFFFFF        {White}
 );
 
procedure SysInitVideo;
var
 WorkInt:LongWord;
 WorkBuffer:String;
begin
 {Setup Error Code}
 ErrorCode:=errVioInit;
 
 {Check Environment Variables}
 {CONSOLE_VIDEO_POSITION}
 WorkInt:=StrToIntDef(SysUtils.GetEnvironmentVariable('CONSOLE_VIDEO_POSITION'),0);
 if WorkInt > 0 then CONSOLE_VIDEO_POSITION:=WorkInt;
 
 {CONSOLE_VIDEO_DEVICE}
 WorkBuffer:=SysUtils.GetEnvironmentVariable('CONSOLE_VIDEO_DEVICE');
 if Length(WorkBuffer) <> 0 then CONSOLE_VIDEO_DEVICE:=WorkBuffer;

 {CONSOLE_VIDEO_FONT}
 WorkBuffer:=SysUtils.GetEnvironmentVariable('CONSOLE_VIDEO_FONT');
 if Length(WorkBuffer) <> 0 then CONSOLE_VIDEO_FONT:=WorkBuffer;
 
 {Check Device}
 ConsoleDevice:=nil;
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
   {Check Window}
   if CONSOLE_VIDEO_WINDOW <> INVALID_HANDLE_VALUE then
    begin
     {Get Window Handle}
     WindowHandle:=CONSOLE_VIDEO_WINDOW;
    end
   else
    begin
     {Get Default Window}
     WindowHandle:=ConsoleWindowGetDefault(ConsoleDevice);
     if WindowHandle = INVALID_HANDLE_VALUE then
      begin
       {Check Single Window}
       if ConsoleDeviceCheckFlag(ConsoleDevice,CONSOLE_FLAG_SINGLE_WINDOW) then
        begin
         CONSOLE_VIDEO_POSITION:=CONSOLE_POSITION_FULLSCREEN;
        end;
        
       {Check Fullscreen} 
       if (CONSOLE_VIDEO_POSITION = CONSOLE_POSITION_FULLSCREEN) and not(ConsoleDeviceCheckFlag(ConsoleDevice,CONSOLE_FLAG_FULLSCREEN)) then
        begin
         CONSOLE_VIDEO_POSITION:=CONSOLE_POSITION_FULL;
        end;
       
       {Create Console Window}
       WindowHandle:=ConsoleWindowCreate(ConsoleDevice,CONSOLE_VIDEO_POSITION,True);
       if WindowHandle <> INVALID_HANDLE_VALUE then WindowCreate:=True;
      end;
    end;  
   
   {Check Window Handle}
   if WindowHandle <> INVALID_HANDLE_VALUE then
    begin
     CONSOLE_VIDEO_WINDOW:=WindowHandle;
     
     {Check Font}
     if (Length(CONSOLE_VIDEO_FONT) <> 0) and (FontFindByName(CONSOLE_VIDEO_FONT) <> INVALID_HANDLE_VALUE) then
      begin
       {Set Font}
       ConsoleWindowSetFont(WindowHandle,FontFindByName(CONSOLE_VIDEO_FONT));
      end
     else
      begin     
       {Set Font}
       ConsoleWindowSetFont(WindowHandle,FontFindByName('Default8x16'));
      end; 
     
     {Reset Viewport}
     ConsoleWindowResetViewport(WindowHandle);
     
     {Get Parameters}
     ScreenColor:=ConsoleDeviceCheckFlag(ConsoleDevice,CONSOLE_FLAG_COLOR);
     ScreenWidth:=ConsoleWindowGetWidth(WindowHandle);
     ScreenHeight:=ConsoleWindowGetHeight(WindowHandle);
     
     {TDrawBuffer only has FVMaxWidth elements larger values lead to crashes}
     if ScreenWidth > FVMaxWidth then ScreenWidth:=FVMaxWidth;
     
     {Get Parameters}
     CursorX:=ConsoleWindowGetX(WindowHandle);
     CursorY:=ConsoleWindowGetY(WindowHandle);
     CursorLines:=0;
     
     {Set Cursor}
     ConsoleWindowCursorOff(WindowHandle); 
     ConsoleWindowCursorBar(WindowHandle);
     ConsoleWindowCursorBlink(WindowHandle,True);
     
     {Create Buffer}
     SetLength(ConsoleBuffer,ScreenWidth * ScreenHeight);
     
     ErrorCode:=vioOK;
    end; 
  end;
end;


procedure SysDoneVideo;
begin
 {Release Buffer}
 SetLength(ConsoleBuffer,0);
 
 {Check Create}
 if WindowCreate then
  begin
   {Destroy Console Window}
   ConsoleWindowDestroy(WindowHandle);
  end;
  
 {Reset Parameters} 
 WindowCreate:=False;
 WindowHandle:=INVALID_HANDLE_VALUE;
 ConsoleDevice:=nil;
 
 CONSOLE_VIDEO_WINDOW:=INVALID_HANDLE_VALUE;
end;


procedure SysUpdateScreen(Force: Boolean);
type 
 WordRec = record
  One, Two: Byte;
 end;

var
 Count:Integer;
 Update:Boolean;

 Skip:LongWord;
 Width:LongWord;
 Height:LongWord;
 
 Dest:TConsolePoint;
 Source:TConsolePoint;
 
 BufCounter:LongInt;
 LineCounter:LongInt;
 ColCounter:LongInt;
 
 X1,Y1,X2,Y2:LongInt;
 
 Buffer:PCardinal;
 OldBuffer:PCardinal;
 EndBuffer:PCardinal;
begin
 {Check Force}
 if Force then
  begin
   Update:=True
  end 
 else
  begin
   {Check Changes}
   Update:=False;

   {Divide Bytes by 4 (SizeOf(Cardinal)}
   Count:=VideoBufSize shr 2;
   
   {Get Start and End}
   Buffer:=PCardinal(VideoBuf);
   OldBuffer:=PCardinal(OldVideoBuf);
   EndBuffer:=@PCardinal(VideoBuf)[Count];
   
   {Compare Buffer and OldBuffer}
   while (Buffer < EndBuffer) and (Buffer^ = OldBuffer^) do
    begin
     {Inc Buffer}
     Inc(Buffer);
     
     {Inc OldBuffer}
     Inc(OldBuffer);
    end; 
    
   {Check Result} 
   Update:=Buffer <> EndBuffer;  
  end;
  
 {Check Update} 
 if Update then
  begin
   {Setup Start}
   BufCounter:=0;
   X1:=ScreenWidth + 1;
   X2:=-1;
   Y1:=ScreenHeight + 1;
   Y2:=-1;
   
   {Find Changes}
   for LineCounter:=1 to ScreenHeight do
    begin
     for ColCounter := 1 to ScreenWidth do
      begin
       if (WordRec(VideoBuf^[BufCounter]).One <> WordRec(OldVideoBuf^[BufCounter]).One) or (WordRec(VideoBuf^[BufCounter]).Two <> WordRec(OldVideoBuf^[BufCounter]).Two) then
        begin
         if ColCounter < X1 then X1:=ColCounter;
         if ColCounter > X2 then X2:=ColCounter;
         if LineCounter < Y1 then Y1:=LineCounter;
         if LineCounter > Y2 then Y2:=LineCounter;
        end;
       
       {Update Buffer}
       ConsoleBuffer[BufCounter].Ch:=Char(WordRec(VideoBuf^[BufCounter]).One);
       ConsoleBuffer[BufCounter].Forecolor:=ConsoleColors[WordRec(VideoBuf^[BufCounter]).Two and $F];
       ConsoleBuffer[BufCounter].Backcolor:=ConsoleColors[(WordRec(VideoBuf^[BufCounter]).Two and $F0) shr 4];
        
       Inc(BufCounter);
      end;
    end;
   
   {Check Force}
   if Force then
    begin
     {Get Source}
     Source.X:=1;
     Source.Y:=1;
     
     {Get Dest}
     Dest.X:=1;
     Dest.Y:=1;
     
     {Get Skip,Width and Height}
     Skip:=0;
     Width:=ScreenWidth;
     Height:=ScreenHeight;
    end
   else
    begin
     {Get Source}
     Source.X:=X1;
     Source.Y:=Y1;
     
     {Get Dest}
     Dest.X:=X1;
     Dest.Y:=Y1;

     {Get Skip,Width and Height}
     Width:=(X2 - X1) + 1;
     Height:=(Y2 - Y1) + 1;
     Skip:=ScreenWidth - Width;
    end;
   
   {Console Window Output}
   ConsoleWindowOutput(WindowHandle,Source,Dest,@ConsoleBuffer[0],Width,Height,Skip);
   
   {Save Old Buffer}
   System.Move(VideoBuf^,OldVideoBuf^,VideoBufSize);
  end;
end;


procedure SysClearScreen;
begin
 {Udpate Screen}
 UpdateScreen(True);
end;


function SysSetVideoMode (const Mode : TVideoMode) : Boolean;
begin
 SysSetVideoMode:=False;
 {Check Mode}
 if (Mode.Col = ScreenWidth) and (Mode.Row = ScreenHeight) and (Mode.Color = ScreenColor) then
  begin
   SysSetVideoMode:=True
  end;
end;


function SysGetVideoModeCount : Word;
begin
 {Return mode count 1}
 SysGetVideoModeCount:=1;
end;


function SysGetVideoModeData (Index : Word; Var Data : TVideoMode) : boolean;
begin
 SysGetVideoModeData:=(Index = 0);
 if SysGetVideoModeData then
  begin
   Data.Col:=ScreenWidth;
   Data.Row:=ScreenHeight;
   Data.Color:=ScreenColor;
  end; 
end;


procedure SysSetCursorPos(NewCursorX, NewCursorY: Word);
begin
 if ConsoleWindowSetXY(WindowHandle,NewCursorX + 1,NewCursorY + 1) = ERROR_SUCCESS then
  begin
   CursorX:=NewCursorX;
   CursorY:=NewCursorY;
  end;
end;


function SysGetCursorType: Word;
begin
 if ConsoleWindowGetCursorState(WindowHandle) = CURSOR_STATE_OFF then
  begin
   SysGetCursorType:=crHidden
  end
 else 
  begin
   case ConsoleWindowGetCursorShape(WindowHandle) of
    CURSOR_SHAPE_LINE:SysGetCursorType:=crHalfBlock;
    CURSOR_SHAPE_BAR:SysGetCursorType:=crUnderline;
    CURSOR_SHAPE_BLOCK:SysGetCursorType:=crBlock;
   end;
  end;
end;


procedure SysSetCursorType(NewType: Word);
begin
 if NewType = crHidden then
  begin
   ConsoleWindowSetCursorState(WindowHandle,CURSOR_STATE_OFF);
  end
 else
  begin
   case NewType of
    crHalfBlock:ConsoleWindowSetCursorShape(WindowHandle,CURSOR_SHAPE_LINE);
    crUnderline:ConsoleWindowSetCursorShape(WindowHandle,CURSOR_SHAPE_BAR);
    crBlock:ConsoleWindowSetCursorShape(WindowHandle,CURSOR_SHAPE_BLOCK);
   end;
   ConsoleWindowSetCursorState(WindowHandle,CURSOR_STATE_ON);
  end;  
end;


function SysGetCapabilities: Word;
begin
 SysGetCapabilities:=cpColor or cpChangeCursor;
end;


const
 SysVideoDriver : TVideoDriver = (
  InitDriver : @SysInitVideo;
  DoneDriver : @SysDoneVideo;
  UpdateScreen : @SysUpdateScreen;
  ClearScreen : @SysClearScreen;
  SetVideoMode : @SysSetVideoMode;
  GetVideoModeCount : @SysGetVideoModeCount;
  GetVideoModeData : @SysGetVideoModeData;
  SetCursorPos : @SysSetCursorPos;
  GetCursorType : @SysGetCursorType;
  SetCursorType : @SysSetCursorType;
  GetCapabilities : @SysGetCapabilities
 );

initialization
 SetVideoDriver(SysVideoDriver);
 
end.
 