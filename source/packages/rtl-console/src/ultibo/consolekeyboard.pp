{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    Keyboard unit for Ultibo

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit ConsoleKeyboard;

interface

{$i keybrdh.inc}

implementation

uses
 GlobalConst,GlobalConfig,GlobalTypes,Keyboard,SysUtils;
 
{$i keyboard.inc}

var
 LastShiftState:Byte;

function TranslateShiftState(const Data:TKeyboardData): Byte;
var
 ShiftState:Byte;
begin
 {Get Shift State} 
 ShiftState:=0;
 if (Data.Modifiers and (KEYBOARD_LEFT_CTRL or KEYBOARD_RIGHT_CTRL)) <> 0 then
  begin
   ShiftState:=ShiftState or kbCtrl;
  end;
 if (Data.Modifiers and (KEYBOARD_LEFT_ALT or KEYBOARD_RIGHT_ALT)) <> 0 then
  begin
   ShiftState:=ShiftState or kbAlt;
  end;
 if (Data.Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
  begin
   ShiftState:=ShiftState or kbShift;
  end;
  
 TranslateShiftState:=ShiftState;
end;


function TranslateKey(const Data:TKeyboardData): TKeyEvent;
var
 Key:TKeyEvent;
 CharCode:Byte;
 ScanCode:Byte;
begin
 {We use the KeyCode value since it has already been translated by the key mapping}
 TKeyRecord(Key).Flags:=kbPhys;
 
 {Get Char Code}
 CharCode:=Byte(Data.CharCode);
 
 {Check Key Code (Normal Scan Codes)}
 case Data.KeyCode of
  {<ESC>1234567890-=<BACK>}
  KEY_CODE_ESCAPE:begin
    ScanCode:=$01;
   end;
  KEY_CODE_1,KEY_CODE_EXCLAMATION:begin
    ScanCode:=$02;
   end;
  KEY_CODE_2,KEY_CODE_AT:begin
    ScanCode:=$03;
   end;
  KEY_CODE_3,KEY_CODE_NUMBER:begin
    ScanCode:=$04;
   end;
  KEY_CODE_4,KEY_CODE_DOLLAR:begin
    ScanCode:=$05;
   end;
  KEY_CODE_5,KEY_CODE_PERCENT:begin
    ScanCode:=$06;
   end;
  KEY_CODE_6,KEY_CODE_CARET:begin
    ScanCode:=$07;
   end;
  KEY_CODE_7,KEY_CODE_AMPERSAND:begin
    ScanCode:=$08;
   end;
  KEY_CODE_8,KEY_CODE_ASTERISK:begin
    ScanCode:=$09;
   end;
  KEY_CODE_9,KEY_CODE_LEFT_BRACKET:begin
    ScanCode:=$0A;
   end;
  KEY_CODE_0,KEY_CODE_RIGHT_BRACKET:begin
    ScanCode:=$0B;
   end;
  KEY_CODE_MINUS,KEY_CODE_UNDERSCORE:begin
    ScanCode:=$0C;
   end;
  KEY_CODE_EQUALS,KEY_CODE_PLUS:begin
    ScanCode:=$0D;
   end;
  KEY_CODE_BACKSPACE:begin
    ScanCode:=$0E;
   end;
  {<TAB>QWERTYUIOP[]<ENTER>}
  KEY_CODE_TAB:begin
    ScanCode:=$0F;
   end;
  KEY_CODE_Q,KEY_CODE_CAPITAL_Q:begin
    ScanCode:=$10;
   end;
  KEY_CODE_W,KEY_CODE_CAPITAL_W:begin
    ScanCode:=$11;
   end;
  KEY_CODE_E,KEY_CODE_CAPITAL_E:begin
    ScanCode:=$12;
   end;
  KEY_CODE_R,KEY_CODE_CAPITAL_R:begin
    ScanCode:=$13;
   end;
  KEY_CODE_T,KEY_CODE_CAPITAL_T:begin
    ScanCode:=$14;
   end;
  KEY_CODE_Y,KEY_CODE_CAPITAL_Y:begin
    ScanCode:=$15;
   end;
  KEY_CODE_U,KEY_CODE_CAPITAL_U:begin
    ScanCode:=$16;
   end;
  KEY_CODE_I,KEY_CODE_CAPITAL_I:begin
    ScanCode:=$17;
   end;
  KEY_CODE_O,KEY_CODE_CAPITAL_O:begin
    ScanCode:=$18;
   end;
  KEY_CODE_P,KEY_CODE_CAPITAL_P:begin
    ScanCode:=$19;
   end;
  KEY_CODE_LEFT_SQUARE,KEY_CODE_LEFT_BRACE:begin
    ScanCode:=$1A;
   end;
  KEY_CODE_RIGHT_SQUARE,KEY_CODE_RIGHT_BRACE:begin
    ScanCode:=$1B;
   end;
  KEY_CODE_ENTER:begin
    ScanCode:=$1C;
   end;
  {~ASDFGHJKL;'}
  KEY_CODE_A,KEY_CODE_CAPITAL_A:begin
    ScanCode:=$1E;
   end;
  KEY_CODE_S,KEY_CODE_CAPITAL_S:begin
    ScanCode:=$1F;
   end;
  KEY_CODE_D,KEY_CODE_CAPITAL_D:begin
    ScanCode:=$20;
   end;
  KEY_CODE_F,KEY_CODE_CAPITAL_F:begin
    ScanCode:=$21;
   end;
  KEY_CODE_G,KEY_CODE_CAPITAL_G:begin
    ScanCode:=$22;
   end;
  KEY_CODE_H,KEY_CODE_CAPITAL_H:begin
    ScanCode:=$23;
   end;
  KEY_CODE_J,KEY_CODE_CAPITAL_J:begin
    ScanCode:=$24;
   end;
  KEY_CODE_K,KEY_CODE_CAPITAL_K:begin
    ScanCode:=$25;
   end;
  KEY_CODE_L,KEY_CODE_CAPITAL_L:begin
    ScanCode:=$26;
   end;
  KEY_CODE_SEMICOLON,KEY_CODE_COLON:begin
    ScanCode:=$27;
   end;
  KEY_CODE_QUOTATION,KEY_CODE_APOSTROPHE:begin
    ScanCode:=$28;
   end;
  KEY_CODE_GRAVE,KEY_CODE_TILDE:begin
    ScanCode:=$29;
   end;
  {\ZXCVBNM,./}
  KEY_CODE_BACKSLASH,KEY_CODE_PIPE:begin
    ScanCode:=$2B;
   end;
  KEY_CODE_Z,KEY_CODE_CAPITAL_Z:begin
    ScanCode:=$2C;
   end;
  KEY_CODE_X,KEY_CODE_CAPITAL_X:begin
    ScanCode:=$2D;
   end;
  KEY_CODE_C,KEY_CODE_CAPITAL_C:begin
    ScanCode:=$2E;
   end;
  KEY_CODE_V,KEY_CODE_CAPITAL_V:begin
    ScanCode:=$2F;
   end;
  KEY_CODE_B,KEY_CODE_CAPITAL_B:begin
    ScanCode:=$30;
   end;
  KEY_CODE_N,KEY_CODE_CAPITAL_N:begin
    ScanCode:=$31;
   end;
  KEY_CODE_M,KEY_CODE_CAPITAL_M:begin
    ScanCode:=$32;
   end;
  KEY_CODE_COMMA,KEY_CODE_LESSTHAN:begin
    ScanCode:=$33;
   end;
  KEY_CODE_PERIOD,KEY_CODE_GREATERTHAN:begin
    ScanCode:=$34;
   end;
  KEY_CODE_SLASH,KEY_CODE_QUESTION:begin
    ScanCode:=$35;
   end;
  {F1-F10}
  KEY_CODE_F1..KEY_CODE_F10:begin
    ScanCode:=(Data.KeyCode - KEY_CODE_F1) + $3B;
   end;
  {F11-F12} 
  KEY_CODE_F11..KEY_CODE_F12:begin
    ScanCode:=(Data.KeyCode - KEY_CODE_F11) + $85;
   end;
  {Home/Up/PgUp/Left/Right/End/Down/PgDn/Ins/Del}
  KEY_CODE_HOME:begin
    ScanCode:=$47;
   end;
  KEY_CODE_UP_ARROW:begin
    ScanCode:=$48;
   end;
  KEY_CODE_PAGEUP:begin
    ScanCode:=$49;
   end;
  KEY_CODE_LEFT_ARROW:begin
    ScanCode:=$4B;
   end;
  KEY_CODE_CENTER:begin
    ScanCode:=$4C;
   end;
  KEY_CODE_RIGHT_ARROW:begin
    ScanCode:=$4D;
   end;
  KEY_CODE_END:begin
    ScanCode:=$4F;
   end;
  KEY_CODE_DOWN_ARROW:begin
    ScanCode:=$50;
   end;
  KEY_CODE_PAGEDN:begin
    ScanCode:=$51;
   end;
  KEY_CODE_INSERT:begin
    ScanCode:=$52;
   end;
  KEY_CODE_DELETE:begin
    CharCode:=$00;
    ScanCode:=$53;
   end;
 end; 
 
 {Check Scan Code (Normal Scan Codes)}
 case Data.ScanCode of
  SCAN_CODE_KEYPAD_PLUS:begin
    ScanCode:=$4A;
   end;
  SCAN_CODE_KEYPAD_MINUS:begin
    ScanCode:=$4E;
   end;
 end; 
 
 {Get Key Code}
 TKeyRecord(Key).KeyCode:=(ScanCode shl 8) or CharCode;

 {Check for Alt}
 if (Data.Modifiers and (KEYBOARD_LEFT_ALT or KEYBOARD_RIGHT_ALT)) <> 0 then 
  begin
   {Check Key Code (Alt Scan Codes)}
   case Data.KeyCode of
    {Alt F1-F10}
    KEY_CODE_F1..KEY_CODE_F10:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F1) + $68;
     end;
    {Alt F11-F12} 
    KEY_CODE_F11..KEY_CODE_F12:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F11) + $8B;
     end;
    {Alt ESC/Space/Back} 
    KEY_CODE_ESCAPE:begin
      ScanCode:=$01;
     end;
    KEY_CODE_SPACE:begin
      ScanCode:=$02;
     end;
    KEY_CODE_BACKSPACE:begin
      {Check for Shift}
      if (Data.Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
       begin
        ScanCode:=$09;
       end
      else
       begin
        ScanCode:=$08;
       end;
     end;
    {Alt Home/Up/PgUp/Left/Right/End/Down/PgDn/Ins/Del}
    KEY_CODE_HOME:begin
      ScanCode:=$97;
     end;
    KEY_CODE_UP_ARROW:begin
      ScanCode:=$98;
     end;
    KEY_CODE_PAGEUP:begin
      ScanCode:=$99;
     end;
    KEY_CODE_LEFT_ARROW:begin
      ScanCode:=$9B;
     end;
    KEY_CODE_RIGHT_ARROW:begin
      ScanCode:=$9D;
     end;
    KEY_CODE_END:begin
      ScanCode:=$9F;
     end;
    KEY_CODE_DOWN_ARROW:begin
      ScanCode:=$A0;
     end;
    KEY_CODE_PAGEDN:begin
      ScanCode:=$A1;
     end;
    KEY_CODE_INSERT:begin
      ScanCode:=$A2;
     end;
    KEY_CODE_DELETE:begin
      ScanCode:=$A3;
     end;
    KEY_CODE_TAB:begin
      ScanCode:=$A5;
     end;
   end;
  
   {Check for AltGr}
   if (Data.Modifiers and KEYBOARD_ALTGR) = 0 then
    begin
     {Reset Char Code}
     CharCode:=$00;

     {Check Key Code (Alt Scan Codes)}
     case Data.KeyCode of
      {Alt 1/2/3/4/5/6/7/8/9/0/Minus/Equal}
      KEY_CODE_1:begin
        ScanCode:=$78;
       end;
      KEY_CODE_2:begin
        ScanCode:=$79;
       end;
      KEY_CODE_3:begin
        ScanCode:=$7A;
       end;
      KEY_CODE_4:begin
        ScanCode:=$7B;
       end;
      KEY_CODE_5:begin
        ScanCode:=$7C;
       end;
      KEY_CODE_6:begin
        ScanCode:=$7D;
       end;
      KEY_CODE_7:begin
        ScanCode:=$7E;
       end;
      KEY_CODE_8:begin
        ScanCode:=$7F;
       end;
      KEY_CODE_9:begin
        ScanCode:=$80;
       end;
      KEY_CODE_0:begin
        ScanCode:=$81;
       end;
      KEY_CODE_MINUS:begin
        ScanCode:=$82;
       end;
      KEY_CODE_EQUALS:begin
        ScanCode:=$83;
       end;
     end;
    end;
   
   {Check Scan Code (Alt Scan Codes)}
   case Data.ScanCode of
    {Alt Asterisk/Plus}
    SCAN_CODE_KEYPAD_ASTERISK:begin
      ScanCode:=$37;
     end;
    SCAN_CODE_KEYPAD_PLUS:begin
      ScanCode:=$4E;
     end;
   end;
   
   {Update Key Code}
   TKeyRecord(Key).KeyCode:=(ScanCode shl 8) or CharCode;
  end
  
 {Check for Ctrl}
 else if (Data.Modifiers and (KEYBOARD_LEFT_CTRL or KEYBOARD_RIGHT_CTRL)) <> 0 then
  begin
   {Check Key Code (Ctrl Scan Codes)}
   case Data.KeyCode of
    {Ctrl F1-F10}
    KEY_CODE_F1..KEY_CODE_F10:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F1) + $5E;
     end;
    {Ctrl F11-F12} 
    KEY_CODE_F11..KEY_CODE_F12:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F11) + $89;
     end;
    {Ctrl Ins/Del} 
    KEY_CODE_INSERT:begin
      ScanCode:=$04;
     end;
    KEY_CODE_DELETE:begin
      ScanCode:=$06;
     end;
    {Ctrl PrtSc/Left/Right/End/PgDn/Home/PgUp/Up/Minus/Down/Tab}
    KEY_CODE_PRINTSCREEN:begin
      ScanCode:=$72;
     end;
    KEY_CODE_LEFT_ARROW:begin
      ScanCode:=$73;
     end;
    KEY_CODE_RIGHT_ARROW:begin
      ScanCode:=$74;
     end;
    KEY_CODE_END:begin
      ScanCode:=$75;
     end;
    KEY_CODE_PAGEDN:begin
      ScanCode:=$76;
     end;
    KEY_CODE_HOME:begin
      ScanCode:=$77;
     end;
    KEY_CODE_PAGEUP:begin
      ScanCode:=$84;
     end;
    KEY_CODE_UP_ARROW:begin
      ScanCode:=$8D;
     end;
    KEY_CODE_MINUS:begin
      ScanCode:=$8E;
     end;
    KEY_CODE_CENTER:begin
      ScanCode:=$8F;
     end;    
    KEY_CODE_DOWN_ARROW:begin
      ScanCode:=$91;
     end;
    KEY_CODE_TAB:begin
      ScanCode:=$94;
     end;
    {Ctrl 2} 
    KEY_CODE_2:begin
      ScanCode:=$03;
     end;
    {Ctrl-A to Ctrl-Z (^A to ^A)}
    KEY_CODE_A..KEY_CODE_Z:begin
      CharCode:=Data.KeyCode - (KEY_CODE_A - 1); {Minus 0x60}
     end;
    {Ctrl-A to Ctrl-Z (^A to ^A)}
    KEY_CODE_CAPITAL_A..KEY_CODE_CAPITAL_A:begin
      CharCode:=Data.KeyCode - (KEY_CODE_CAPITAL_A - 1);  {Minus 0x40}
     end;
    {Ctrl-[ (^[)}
    KEY_CODE_LEFT_SQUARE:begin 
      CharCode:=27;
     end;
    {Ctrl-\ (^\)}
    KEY_CODE_BACKSLASH:begin
      CharCode:=28;
     end;
    {Ctrl-] (^])}
    KEY_CODE_RIGHT_SQUARE:begin
      CharCode:=29;
     end;
    {Ctrl-^ (^^)}
    KEY_CODE_6,KEY_CODE_CARET:begin
      CharCode:=30;
     end;
    {Ctrl-_ (^_)}
    {KEY_CODE_MINUS,}KEY_CODE_UNDERSCORE:begin
      CharCode:=31;
     end;
   end; 
   
   {Check Scan Code (Ctrl Scan Codes)}
   case Data.ScanCode of
    {Ctrl Plus}
    SCAN_CODE_KEYPAD_PLUS:begin
      ScanCode:=$90;
     end;
   end;
   
   {Update Key Code}
   TKeyRecord(Key).KeyCode:=(ScanCode shl 8) or CharCode;
  end
  
 {Check for Shift}
 else if (Data.Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
  begin
   {Check Key Code (Shift Scan Codes)}
   case Data.KeyCode of
    {Shift F1-F10}
    KEY_CODE_F1..KEY_CODE_F10:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F1) + $54;
     end;
    {Shift F11-F12} 
    KEY_CODE_F11..KEY_CODE_F12:begin
      ScanCode:=(Data.KeyCode - KEY_CODE_F11) + $87;
     end;
    {Shift Ins/Del/Tab} 
    KEY_CODE_INSERT:begin
      ScanCode:=$05;
     end;
    KEY_CODE_DELETE:begin
      ScanCode:=$07;
     end;
    KEY_CODE_TAB:begin
      ScanCode:=$0F;
     end;
   end; 
   
   {Update Key Code}
   TKeyRecord(Key).KeyCode:=(ScanCode shl 8) or CharCode;
  end;
 
 {Get Shift State} 
 LastShiftState:=TranslateShiftState(Data);
 TKeyRecord(Key).ShiftState:=LastShiftState;
 
 TranslateKey:=Key;
end;


procedure SysInitKeyboard;
begin
 LastShiftState:=0;
end;


procedure SysDoneKeyboard;
begin
 {Nothing}
end;


function SysGetKeyEvent: TKeyEvent;
var
 Key:TKeyEvent;
 
 Count:LongWord;
 Status:LongWord;
 Data:TKeyboardData;
begin
 {Read Next Key}
 Status:=KeyboardRead(@Data,SizeOf(TKeyboardData),Count);
 while Status = ERROR_SUCCESS do
  begin
   {Exclude Key Up and Dead Key events}
   if (Data.Modifiers and (KEYBOARD_KEYUP or KEYBOARD_DEADKEY)) = 0 then
    begin
     {Translate Key}
     Key:=TranslateKey(Data);
     
     Break;
    end; 
     
   {Get Next Key}
   Status:=KeyboardRead(@Data,SizeOf(TKeyboardData),Count);
  end;
 if Status <> ERROR_SUCCESS then 
  begin
   Key:=0;
  end;  
  
 SysGetKeyEvent:=Key;
end;


function SysPollKeyEvent: TKeyEvent;
var
 Key:TKeyEvent;

 Count:LongWord;
 Status:LongWord;
 Data:TKeyboardData;
begin
 {Peek Next Key}
 Status:=KeyboardReadEx(@Data,SizeOf(TKeyboardData),KEYBOARD_FLAG_NON_BLOCK or KEYBOARD_FLAG_PEEK_BUFFER,Count);
 while Status = ERROR_SUCCESS do
  begin
   {Exclude Key Up and Dead Key events}
   if (Data.Modifiers and (KEYBOARD_KEYUP or KEYBOARD_DEADKEY)) = 0 then
    begin
     {Translate Key}
     Key:=TranslateKey(Data);
    
     Break;
    end
   else
    begin
     {Remove Next Key}
     KeyboardRead(@Data,SizeOf(TKeyboardData),Count);
    end;    
     
   {Peek Next Key}
   Status:=KeyboardReadEx(@Data,SizeOf(TKeyboardData),KEYBOARD_FLAG_NON_BLOCK or KEYBOARD_FLAG_PEEK_BUFFER,Count);
  end;
 if Status <> ERROR_SUCCESS then 
  begin
   Key:=0;
  end;  
 
 SysPollKeyEvent:=Key;
end;


function SysGetShiftState: Byte;
begin
 SysGetShiftState:=LastShiftState;
end;


function SysTranslateKeyEvent(KeyEvent: TKeyEvent): TKeyEvent;
begin
 {Check for Physical}
 if KeyEvent and $03000000 = $03000000 then
  begin
   {Check Char Code}
   if (KeyEvent and $000000FF) <> 0 then
    begin
     {Change to ASCII}
     SysTranslateKeyEvent:=KeyEvent and $00FFFFFF;
     Exit;
    end;
   
   {Check Scan Code}
   case (KeyEvent AND $0000FF00) shr 8 of
    {F1..F10}
    $3B..$44     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $3B + $02000000;
    {F11,F12}
    $85..$86     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $85 + $02000000;
    {Shift F1..F10}
    $54..$5D     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $54 + $02000000;
    {Shift F11,F12}
    $87..$88     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $87 + $02000000;
    {Alt F1..F10}
    $68..$71     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $68 + $02000000;
    {Alt F11,F12}
    $8B..$8C     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $8B + $02000000;
    {Ctrl F1..F10}
    $5E..$67     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $5E + $02000000;
    {Ctrl F11,F12}
    $89..$8A     : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $89 + $02000000;

    {Home (Normal,Ctrl,Alt)}
    $47,$77,$97  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdHome + $02000000;
    {Up (Normal,Ctrl,Alt)}
    $48,$8D,$98  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdUp + $02000000;
    {PgUp (Normal,Ctrl,Alt)}
    $49,$84,$99  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdPgUp + $02000000;
    {Left (Normal,Ctrl,Alt)}
    $4b,$73,$9B  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdLeft + $02000000;
    {Right (Normal,Ctrl,Alt)}
    $4d,$74,$9D  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdRight + $02000000;
    {End (Normal,Ctrl,Alt)}
    $4f,$75,$9F  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdEnd + $02000000;
    {Down (Normal,Ctrl,Alt)}
    $50,$91,$A0  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdDown + $02000000;
    {PgDn (Normal,Ctrl,Alt)}
    $51,$76,$A1  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdPgDn + $02000000;
    {Insert (Normal,Ctrl,Alt)}
    $52,$92,$A2  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdInsert + $02000000;
    {Delete (Normal,Ctrl,Alt)}
    $53,$93,$A3  : SysTranslateKeyEvent:=(KeyEvent AND $FCFF0000) + kbdDelete + $02000000;
   else
    begin
     {No Change}
     SysTranslateKeyEvent:=KeyEvent;
    end; 
   end;
  end
 else
  begin
   {No Change}
   SysTranslateKeyEvent:=KeyEvent;
  end;
end;


const
 SysKeyboardDriver : TKeyboardDriver = (
  InitDriver : @SysInitKeyBoard;
  DoneDriver : @SysDoneKeyBoard;
  GetKeyEvent : @SysGetKeyEvent;
  PollKeyEvent : @SysPollKeyEvent;
  GetShiftState : @SysGetShiftState;
  TranslateKeyEvent : @SysTranslateKeyEvent; 
  TranslateKeyEventUnicode : Nil;
 );
 
begin
 SetKeyboardDriver(SysKeyboardDriver);
end.
 