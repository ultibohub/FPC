{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by the Free Pascal development team.

    Borland Pascal 7 Compatible CRT Unit - Ultibo implentation

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit crt;

interface

{$i crth.inc}

procedure Window32(X1,Y1,X2,Y2: DWord);
procedure GotoXY32(X,Y: DWord);
function WhereX32: DWord;
function WhereY32: DWord;

implementation

uses
 GlobalConfig,
 GlobalConst,
 GlobalTypes,
 Console;
 
{****************************************************************************
                              Internal Routines
****************************************************************************}

var {Source: http://www.shikadi.net/moddingwiki/EGA_Palette}
 CrtColors:array[0..15] of LongWord = (
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
 
procedure CrtInit;
var
 Window:TWindowHandle;
 Console:PConsoleDevice;
begin
 {}
 Console:=ConsoleDeviceGetDefault;
 if Console <> nil then
  begin
   Window:=ConsoleWindowGetDefault(Console);
   if Window = INVALID_HANDLE_VALUE then
    begin
     Window:=ConsoleWindowCreate(Console,CONSOLE_CRT_POSITION,True);
     
    end;
    
   if Window <> INVALID_HANDLE_VALUE then
    begin
     ConsoleWindowGetViewport(Window,WindMinX,WindMinY,WindMaxX,WindMaxY);
   
     WindMax:=(((WindMaxY and $FF) - 1) shl 8) + ((WindMaxX and $FF) - 1);
     
    end; 
  end;  
end;

{****************************************************************************
                             Public Crt Functions
****************************************************************************}

procedure AssignCrt(var F: Text);
begin
 {}
 ConsoleAssignCrt(F);
end;

function KeyPressed: Boolean;
begin
 {}
 KeyPressed:=ConsoleKeyPressed;
end;

function ReadKey: Char;
begin
 {}
 ReadKey:=ConsoleReadKey;
end;
 
procedure TextMode (Mode: word);
begin
 {}
 ConsoleTextMode(Mode);
end;

procedure Window(X1,Y1,X2,Y2: Byte);
begin
 {}
 ConsoleWindow(X1,Y1,X2,Y2);
end;

procedure GotoXY(X,Y: tcrtcoord);
begin
 {}
 ConsoleGotoXY(X,Y);
end;

function WhereX: tcrtcoord;
begin
 {}
 WhereX:=ConsoleWhereX;
end;

function WhereY: tcrtcoord;
begin
 {}
 WhereY:=ConsoleWhereY;
end;

procedure ClrScr;
begin
 {}
 ConsoleClrScr;
end;

procedure ClrEol;
begin
 {}
 ConsoleClrEol;
end;

procedure InsLine;
begin
 {}
 ConsoleInsLine;
end;

procedure DelLine;
begin
 {}
 ConsoleDelLine;
end;

procedure TextColor(Color: Byte);
begin
 {}
 ConsoleTextColor(CrtColors[Color and $F]);
end;

procedure TextBackground(Color: Byte);
begin
 {}
 ConsoleTextBackground(CrtColors[Color and $F]);
end;

procedure LowVideo;
begin
 {}
 ConsoleLowVideo;
end;

procedure HighVideo;
begin
 {}
 ConsoleHighVideo;
end;

procedure NormVideo;
begin
 {}
 ConsoleNormVideo;
end;

procedure Delay(MS: Word);
begin
 {}
 ConsoleDelay(MS);
end;

procedure Sound(Hz: Word);
begin
 {}
 ConsoleSound(Hz);
end;

procedure NoSound;
begin
 {}
 ConsoleNoSound;
end;

{****************************************************************************
                             Extra Crt Functions
****************************************************************************}

procedure cursoron;
begin
 {Nothing}
end;

procedure cursoroff;
begin
 {Nothing}
end;

procedure cursorbig;
begin
 {Nothing}
end;
 
procedure Window32(X1,Y1,X2,Y2: DWord);
begin
 {}
 ConsoleWindow(X1,Y1,X2,Y2);
end;

procedure GotoXY32(X,Y: DWord);
begin
 {}
 ConsoleGotoXY(X,Y);
end;

function WhereX32: DWord;
begin
 {}
 WhereX32:=ConsoleWhereX;
end;

function WhereY32: DWord;
begin
 {}
 WhereY32:=ConsoleWhereY;
end;

initialization
 CrtInit;
 
end.
