{
    This unit implements support import,export,link routines
    for the Ultibo target

    Copyright (c) 2015 by Garry Wood

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit t_ultibo;

{$i fpcdefs.inc}

interface

  uses
    symsym,symdef,
    import,export,link;

  type
    TImportLibUltibo=class(timportlib)
      procedure GenerateLib;override;
    end;

    TExportLibUltibo=class(texportlib)
      procedure PrepareLib(const s : string);override;
      procedure ExportProcedure(hp : texported_item);override;
      procedure ExportVar(hp : texported_item);override;
      procedure GenerateLib;override;
    end;

    TLinkerUltibo=class(texternallinker)
     private
        Function  WriteResponseFile(isdll:boolean;makelib:boolean): Boolean;
        
        function  AddKernelTrailer(const fn: String): Boolean;
     public
        constructor Create; override;
        procedure SetDefaultInfo; override;
        function  MakeExecutable:boolean; override;
        function  MakeSharedLibrary:boolean;override;
        function PostProcessExecutable(const fn : string;isdll:boolean):boolean;
     end;

implementation

    uses
       SysUtils,
       cutils,cfileutl,cclasses,
       verbose,systems,globtype,globals,
       symconst,comphook,script,
       fmodule,aasmbase,aasmtai,aasmdata,aasmcpu,cpubase,cpuinfo,i_ultibo,ogbase;

{*****************************************************************************
                             TImportLibUltibo
*****************************************************************************}

procedure TImportLibUltibo.GenerateLib;
var
  i : longint;
  ImportLibrary : TImportLibrary;
begin
  for i:=0 to current_module.ImportLibraryList.Count-1 do
    begin
      ImportLibrary:=TImportLibrary(current_module.ImportLibraryList[i]);
      current_module.linkothersharedlibs.add(ImportLibrary.Name,link_always);
    end;
end;

{*****************************************************************************
                             TExportLibUltibo
*****************************************************************************}

procedure TExportLibUltibo.PrepareLib(const s:string);
begin

end;


procedure TExportLibUltibo.ExportProcedure(hp : texported_item);
var
  hp2 : texported_item;
begin
  { first test the index value }
  if (hp.options and eo_index)<>0 then
   begin
     Message1(parser_e_no_export_with_index_for_target,'ultibo');
     exit;
   end;
  { now place in correct order }
  hp2:=texported_item(current_module._exports.first);
  while assigned(hp2) and
     (hp.name^>hp2.name^) do
    hp2:=texported_item(hp2.next);
  { insert hp there !! }
  if assigned(hp2) and (hp2.name^=hp.name^) then
    begin
      { this is not allowed !! }
      Message1(parser_e_export_name_double,hp.name^);
      exit;
    end;
  if hp2=texported_item(current_module._exports.first) then
    current_module._exports.concat(hp)
  else if assigned(hp2) then
    begin
       hp.next:=hp2;
       hp.previous:=hp2.previous;
       if assigned(hp2.previous) then
         hp2.previous.next:=hp;
       hp2.previous:=hp;
    end
  else
    current_module._exports.concat(hp);
end;


procedure TExportLibUltibo.ExportVar(hp : texported_item);
begin
  hp.is_var:=true;
  exportprocedure(hp);
end;


procedure TExportLibUltibo.GenerateLib;
var
  hp2 : texported_item;
  pd  : tprocdef;
begin
  hp2:=texported_item(current_module._exports.first);
  while assigned(hp2) do
   begin
     if (not hp2.is_var) and
        (hp2.sym.typ=procsym) then
      begin
        { the manglednames can already be the same when the procedure
          is declared with cdecl }
        pd:=tprocdef(tprocsym(hp2.sym).ProcdefList[0]);
        if pd.mangledname<>hp2.name^ then
         begin
{$ifdef i386}
           { place jump in al_procedures }
           current_asmdata.asmlists[al_procedures].concat(Tai_align.Create_op(4,$90));
           current_asmdata.asmlists[al_procedures].concat(Tai_symbol.Createname_global(hp2.name^,AT_FUNCTION,0));
           current_asmdata.asmlists[al_procedures].concat(Taicpu.Op_sym(A_JMP,S_NO,current_asmdata.RefAsmSymbol(pd.mangledname)));
           current_asmdata.asmlists[al_procedures].concat(Tai_symbol_end.Createname(hp2.name^));
{$endif i386}
         end;
      end
     else
      Message1(parser_e_no_export_of_variables_for_target,'ultibo');
     hp2:=texported_item(hp2.next);
   end;
end;

{*****************************************************************************
                                  TLinkerUltibo
*****************************************************************************}

Constructor TLinkerUltibo.Create;
begin
  Inherited Create;
  SharedLibFiles.doubles:=true;
  StaticLibFiles.doubles:=true;
end;


procedure TLinkerUltibo.SetDefaultInfo;
const
{$ifdef mips}
  {$ifdef mipsel}
    platform_select='-EL';
  {$else}
    platform_select='-EB';
  {$endif}
{$else}
  platform_select='';
{$endif}
begin
  with Info do
   begin
     ExeCmd[1]:='ld -g '+platform_select+' $OPT $DYNLINK $STATIC $GCSECTIONS $STRIP -L. -o $EXE -T $RES';
     DllCmd[1]:='ld -g '+platform_select+' $OPT $DYNLINK $STATIC $GCSECTIONS $STRIP $SONAME -shared -L. -o $EXE $RES';
     DllCmd[2]:='strip --strip-unneeded $EXE';
   end;
end;


Function TLinkerUltibo.WriteResponseFile(isdll:boolean;makelib:boolean): Boolean;
Var
  linkres  : TLinkRes;
  i        : longint;
  HPath    : TCmdStrListItem;
  s,s1,s2  : TCmdStr;
  prtobject: TCmdStr;
  prtobj,
  cprtobj  : string[80];
  linklibc : boolean;
  found1,
  found2   : boolean;
{$if defined(ARM)}
  LinkStr  : string;
{$endif}
begin
  WriteResponseFile:=False;
  linklibc:=(SharedLibFiles.Find('c')<>nil);
{$if defined(ARM) or defined(i386) or defined(AARCH64)}
  {$ifdef ARM}
  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
     ct_rpia,
     ct_rpib,
     ct_rpizero,
     ct_rpi2b,
     ct_rpi3b,
     ct_qemuvpb:
      begin
       prtobj:=embedded_controllers[current_settings.controllertype].controllerunitstr;
       cprtobj:=embedded_controllers[current_settings.controllertype].controllerunitstr;
      end;
     else
      begin
       prtobj:='';
       cprtobj:='';
      end;
    end;
   end
  else
   begin
    prtobj:='';
    cprtobj:='';
   end;
  {$endif ARM}
  {$ifdef i386}
  if not current_module.islibrary then
   begin
    //To Do
    prtobj:='';
    cprtobj:='';
   end
  else
   begin
    prtobj:='';
    cprtobj:='';
   end;
  {$endif i386}
  {$ifdef AARCH64}
  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
     ct_rpi3b,
     ct_qemuvpb:
      begin
       prtobj:=embedded_controllers[current_settings.controllertype].controllerunitstr;
       cprtobj:=embedded_controllers[current_settings.controllertype].controllerunitstr;
      end;
     else
      begin
       prtobj:='';
       cprtobj:='';
      end;
    end;
   end
  else
   begin
    prtobj:='';
    cprtobj:='';
   end;
  {$endif AARCH64}
{$else}
  if not current_module.islibrary then
   begin
    prtobj:='prt0';
    cprtobj:='cprt0';
   end
  else
   begin
    prtobj:='';
    cprtobj:='';
   end;
{$endif}
  if linklibc then
    prtobj:=cprtobj;

  { Open link.res file }
  LinkRes:=TLinkRes.Create(outputexedir+Info.ResName,true);

  { Write path to search libraries }
  HPath:=TCmdStrListItem(current_module.locallibrarysearchpath.First);
  while assigned(HPath) do
   begin
    s:=HPath.Str;
    if (cs_link_on_target in current_settings.globalswitches) then
     s:=ScriptFixFileName(s);
    LinkRes.Add('-L'+s);
    HPath:=TCmdStrListItem(HPath.Next);
   end;
  HPath:=TCmdStrListItem(LibrarySearchPath.First);
  while assigned(HPath) do
   begin
    s:=HPath.Str;
    if s<>'' then
     LinkRes.Add('SEARCH_DIR("'+s+'")');
    HPath:=TCmdStrListItem(HPath.Next);
   end;

  LinkRes.Add('INPUT (');
  { add objectfiles, start with prt0 always }
  //s:=FindObjectFile('prt0','',false);
  if prtobj<>'' then
    begin
      s:=FindObjectFile(prtobj,'',false);
      prtobject:=s;
      LinkRes.AddFileName(s);
    end;

  { try to add crti and crtbegin if linking to C }
  if linklibc then
   begin
     if librarysearchpath.FindFile('crtbegin.o',false,s) then
      LinkRes.AddFileName(s);
     if librarysearchpath.FindFile('crti.o',false,s) then
      LinkRes.AddFileName(s);
   end;

  while not ObjectFiles.Empty do
   begin
    s:=ObjectFiles.GetFirst;
    {$if defined(ARM) or defined(i386) or defined(AARCH64)}
    if (s<>'') and (upper(s) <> upper(prtobject)) then
    {$else}
    if s<>'' then
    {$endif}
     begin
      { vlink doesn't use SEARCH_DIR for object files }
      if not(cs_link_on_target in current_settings.globalswitches) then
       s:=FindObjectFile(s,'',false);
      LinkRes.AddFileName((maybequoted(s)));
     end;
   end;

  { Write staticlibraries }
  if not StaticLibFiles.Empty then
   begin
    { vlink doesn't need, and doesn't support GROUP }
    if (cs_link_on_target in current_settings.globalswitches) then
     begin
      LinkRes.Add(')');
      LinkRes.Add('GROUP(');
     end;
    while not StaticLibFiles.Empty do
     begin
      S:=StaticLibFiles.GetFirst;
      LinkRes.AddFileName((maybequoted(s)));
     end;
   end;

  if (cs_link_on_target in current_settings.globalswitches) then
   begin
    LinkRes.Add(')');

    { Write sharedlibraries like -l<lib>, also add the needed dynamic linker
      here to be sure that it gets linked this is needed for glibc2 systems (PFV) }
    linklibc:=false;
    while not SharedLibFiles.Empty do
     begin
      S:=SharedLibFiles.GetFirst;
      if s<>'c' then
       begin
        i:=Pos(target_info.sharedlibext,S);
        if i>0 then
         Delete(S,i,255);
        LinkRes.Add('-l'+s);
       end
      else
       begin
        LinkRes.Add('-l'+s);
        linklibc:=true;
       end;
     end;
    { be sure that libc&libgcc is the last lib }
    if linklibc then
     begin
      LinkRes.Add('-lc');
      LinkRes.Add('-lgcc');
     end;
   end
  else
   begin
    while not SharedLibFiles.Empty do
     begin
      S:=SharedLibFiles.GetFirst;
      LinkRes.Add('lib'+s+target_info.staticlibext);
     end;
    LinkRes.Add(')');
   end;

  { objects which must be at the end }
  if linklibc then
   begin
     found1:=librarysearchpath.FindFile('crtend.o',false,s1);
     found2:=librarysearchpath.FindFile('crtn.o',false,s2);
     if found1 or found2 then
      begin
        LinkRes.Add('INPUT(');
        if found1 then
         LinkRes.AddFileName(s1);
        if found2 then
         LinkRes.AddFileName(s2);
        LinkRes.Add(')');
      end;
   end;

{$ifdef ARM}
  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
        ct_none:
             begin
             end;
        { Raspberry Pi}
        ct_rpia,
        ct_rpib,
        ct_rpizero:
          begin
           with embedded_controllers[current_settings.controllertype] do
            with linkres do
              begin
                Add('ENTRY(_START)');
              end;
          end;
        { Raspberry Pi2 / Raspberry Pi3}
        ct_rpi2b,
        ct_rpi3b:
          begin
           with embedded_controllers[current_settings.controllertype] do
            with linkres do
              begin
                Add('ENTRY(_START)');
              end;
          end;
        { QEMU VersatilePB}
        ct_qemuvpb:
          begin
           with embedded_controllers[current_settings.controllertype] do
            with linkres do
              begin
                Add('ENTRY(_START)');
              end;
          end;

      else
        if not (cs_link_nolink in current_settings.globalswitches) then
        	 internalerror(200902011);
    end;
   end;

  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
     ct_rpia,
     ct_rpib,
     ct_rpizero,
     ct_rpi2b,
     ct_rpi3b,
     ct_qemuvpb:
      begin
       with linkres do
        begin
         Add('SECTIONS');
         Add('{');
         Add('    .text 0x' + IntToHex(embedded_controllers[current_settings.controllertype].srambase,8) + ':');
         Add('    {');
         Add('    _text_start = .;');
         Add('    KEEP(*(.init, .init.*))');
         Add('    *(.text, .text.*)');
         Add('    *(.strings)');
         Add('    *(.rodata, .rodata.*)');
         Add('    *(.comment)');
         Add('    _etext = .;');
         Add('    }');

         Add('    .data ALIGN(4096):');
         Add('    {');
         Add('    _data = .;');
         Add('    *(.data, .data.*)');
         Add('    KEEP(*(.fpc .fpc.n_version .fpc.n_links))');
         Add('    _edata = .;');
         Add('    }');

         Add('    .bss ALIGN(4096):');
         Add('    {');
         Add('    _bss_start = .;');
         Add('    *(.bss, .bss.*)');
         Add('    *(COMMON)');
         Add('    }');
         Add('    _bss_end = ALIGN(4096);');
         Add('}');
         Add('_end = .;');
         end;
      end;
    end;
   end;
{$endif ARM}
 
{$ifdef i386}
  if not current_module.islibrary then
   begin
    //To Do
   end;
{$endif i386}

{$ifdef AARCH64}
  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
        ct_none:
             begin
             end;
        { Raspberry Pi3}
        ct_rpi3b:
          begin
           with embedded_controllers[current_settings.controllertype] do
            with linkres do
              begin
                Add('ENTRY(_START)');
              end;
          end;
        { QEMU VersatilePB}
        ct_qemuvpb:
          begin
           with embedded_controllers[current_settings.controllertype] do
            with linkres do
              begin
                Add('ENTRY(_START)');
              end;
          end;

      else
        if not (cs_link_nolink in current_settings.globalswitches) then
        	 internalerror(200902011);
    end;
   end;

  if not current_module.islibrary then
   begin
    case current_settings.controllertype of
     ct_rpi3b,
     ct_qemuvpb:
      begin
       with linkres do
        begin
         Add('SECTIONS');
         Add('{');
         Add('    .text 0x' + IntToHex(embedded_controllers[current_settings.controllertype].srambase,8) + ':');
         Add('    {');
         Add('    _text_start = .;');
         Add('    KEEP(*(.init, .init.*))');
         Add('    *(.text, .text.*)');
         Add('    *(.strings)');
         Add('    *(.rodata, .rodata.*)');
         Add('    *(.comment)');
         Add('    _etext = .;');
         Add('    }');

         Add('    .data ALIGN(4096):');
         Add('    {');
         Add('    _data = .;');
         Add('    *(.data, .data.*)');
         Add('    KEEP(*(.fpc .fpc.n_version .fpc.n_links))');
         Add('    _edata = .;');
         Add('    }');

         Add('    .bss ALIGN(4096):');
         Add('    {');
         Add('    _bss_start = .;');
         Add('    *(.bss, .bss.*)');
         Add('    *(COMMON)');
         Add('    }');
         Add('    _bss_end = ALIGN(4096);');
         Add('}');
         Add('_end = .;');
         end;
      end;
    end;
   end;
{$endif AARCH64}

  { Write and Close response }
  linkres.writetodisk;
  linkres.free;

  WriteResponseFile:=True;

end;

function TLinkerUltibo.AddKernelTrailer(const fn: String): Boolean;
{ The Raspberry Pi firmware checks for a trailer on the end of the image file to
  determine whether or not to enable device tree support or revert to legacy ATAGs.
  
  Since Ultibo does not support device tree we need to mark our kernel image to
  say that DT is not supported in order to make the firmware pass ATAGs to us.
  
  The script used to do this for the Linux kernel can be found here:
  
  https://github.com/raspberrypi/linux/blob/rpi-4.4.y/scripts/mkknlimg
  
  There are a number of supported trailer atoms which can be added but for our
  purpose we only need to add the magic value (which goes last) and the DTOK
  atom with a value of 0 instead of 1}
  
 function FileSize(Handle:THandle):Int64;
 var
   Current : Int64;
 begin
   Current:=FileSeek(Handle,0,fsFromCurrent);
   FileSize:=FileSeek(Handle,0,fsFromEnd);
   FileSeek(Handle,Current,fsFromBeginning);
 end;
 
 const
   TRAILER_BLANK:array[0..3] of Byte = (0,0,0,0);
 
   TRAILER_MAGIC:array[0..3] of Char = ('R','P','T','L');
   TRAILER_DTOK:array[0..3] of Char = ('D','T','O','K');
  
 type
   PTrailerAtom = ^TTrailerAtom;
   TTrailerAtom = record
    Value:LongWord;
    Length:LongWord;
    Name:array[0..3] of Char;
   end;
  
 var
   Null : Byte;
   Size : LongWord;
   Total : LongWord;
   FileHandle : THandle;
   DTOKAtom : TTrailerAtom;
   MagicAtom : TTrailerAtom;
begin
  AddKernelTrailer:=False;
  
  FileHandle:=FileOpen(fn,fmOpenReadWrite or fmShareDenyWrite);
  if FileHandle = THandle(-1) then Exit;
  try
   { Get Starting Size }
   Size:=2 * SizeOf(TRAILER_BLANK);
  
   { Create Magic Atom }
   MagicAtom.Value:=0;
   MagicAtom.Length:=SizeOf(TRAILER_MAGIC);
   MagicAtom.Name:=TRAILER_MAGIC;
   { Add to Size }
   Inc(Size,SizeOf(MagicAtom));
 
   { Create DTOK Atom }
   DTOKAtom.Value:=0;
   DTOKAtom.Length:=SizeOf(TRAILER_DTOK);
   DTOKAtom.Name:=TRAILER_DTOK;
   { Add to Size }
   Inc(Size,SizeOf(DTOKAtom));
 
   { Set Total Size }
   MagicAtom.Value:=Size;
  
   {Move to End}
   FileSeek(FileHandle,0,fsFromEnd);
   
   {Get Total Size}
   Total:=FileSize(FileHandle);
   
   {Round Kernel to 4 bytes}
   Null:=0;
   while (Total and $3) <> 0 do
    begin
     FileWrite(FileHandle,Null,SizeOf(Byte));
   
     {Get Total Size}
     Total:=FileSize(FileHandle);
    end;
   
   {Write Blank}
   FileWrite(FileHandle,TRAILER_BLANK,SizeOf(TRAILER_BLANK));
   
   {Write Blank}
   FileWrite(FileHandle,TRAILER_BLANK,SizeOf(TRAILER_BLANK));
   
   {Write DTOK}
   FileWrite(FileHandle,DTOKAtom,SizeOf(TTrailerAtom));
   
   {Write Magic}
   FileWrite(FileHandle,MagicAtom,SizeOf(TTrailerAtom));
  finally
   FileClose(FileHandle);
  end;
  
  AddKernelTrailer:=True;
end;

function TLinkerUltibo.MakeExecutable:boolean;
var
  binstr,
  cmdstr  : TCmdStr;
  success : boolean;
  StaticStr,
  GCSectionsStr,
  DynLinkStr,
  StripStr: string;
begin
  if not(cs_link_nolink in current_settings.globalswitches) then
   Message1(exec_i_linking,current_module.exefilename);

  { for future use }
  StaticStr:='';
  StripStr:='';
  DynLinkStr:='';
  GCSectionsStr:='--gc-sections';

{ Write used files and libraries }
  WriteResponseFile(false,false);

{ Call linker }
  SplitBinCmd(Info.ExeCmd[1],binstr,cmdstr);
  Replace(cmdstr,'$OPT',Info.ExtraOptions);
  if not(cs_link_on_target in current_settings.globalswitches) then
   begin
    Replace(cmdstr,'$EXE',(maybequoted(ScriptFixFileName(ChangeFileExt(current_module.exefilename,'.elf')))));
    Replace(cmdstr,'$RES',(maybequoted(ScriptFixFileName(outputexedir+Info.ResName))));
    Replace(cmdstr,'$STATIC',StaticStr);
    Replace(cmdstr,'$STRIP',StripStr);
    Replace(cmdstr,'$GCSECTIONS',GCSectionsStr);
    Replace(cmdstr,'$DYNLINK',DynLinkStr);
   end
  else
   begin
    Replace(cmdstr,'$EXE',maybequoted(ScriptFixFileName(ChangeFileExt(current_module.exefilename,'.elf'))));
    Replace(cmdstr,'$RES',maybequoted(ScriptFixFileName(outputexedir+Info.ResName)));
    Replace(cmdstr,'$STATIC',StaticStr);
    Replace(cmdstr,'$STRIP',StripStr);
    Replace(cmdstr,'$GCSECTIONS',GCSectionsStr);
    Replace(cmdstr,'$DYNLINK',DynLinkStr);
   end;
  success:=DoExec(FindUtil(utilsprefix+BinStr),cmdstr,true,false);

{ Remove ReponseFile }
  if success and not(cs_link_nolink in current_settings.globalswitches) then
   DeleteFile(outputexedir+Info.ResName);

{ Post process }
  if success and not(cs_link_nolink in current_settings.globalswitches) then
    success:=PostProcessExecutable(current_module.exefilename+'.elf',false);

  if success and (target_info.system in [system_arm_ultibo,system_i386_ultibo,system_aarch64_ultibo]) then
    begin
     {$ifdef ARM}
     case current_settings.controllertype of
      ct_rpia,
      ct_rpib,
      ct_rpizero:begin
        { Create kernel image }
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel.img',true,false);
        
        {Add kernel trailer}
        if success then
          begin
           success:=AddKernelTrailer(ExtractFilePath(current_module.exefilename) + 'kernel.img');
          end;
       end;
      ct_rpi2b,
      ct_rpi3b:begin
        { Create kernel image }
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel7.img',true,false);
          
        {Add kernel trailer}
        if success then
          begin
           success:=AddKernelTrailer(ExtractFilePath(current_module.exefilename) + 'kernel7.img');
          end;
       end;
      ct_qemuvpb:begin
        { Create kernel image }
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel.bin',true,false);
       end;
     end;  
     {$endif ARM}
     {$ifdef i386}
     //To Do
     {$endif i386}
     {$ifdef AARCH64}
     case current_settings.controllertype of
      ct_rpi3b:begin
        { Create kernel image }
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel8.img',true,false);
          
        {Add kernel trailer}
        if success then
          begin
           success:=AddKernelTrailer(ExtractFilePath(current_module.exefilename) + 'kernel8.img');
          end;
       end;
      ct_qemuvpb:begin
        { Create kernel image }
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel64.bin',true,false);
       end;
     end;  
     {$endif AARCH64}
    end;

  MakeExecutable:=success;   { otherwise a recursive call to link method }
end;

function TLinkerUltibo.MakeSharedLibrary:boolean;
var
  binstr,
  cmdstr,
  SoNameStr : TCmdStr;
  success : boolean;
  StaticStr,
  GCSectionsStr,
  DynLinkStr,
  StripStr: string;
begin
  MakeSharedLibrary:=false;
  if not(cs_link_nolink in current_settings.globalswitches) then
   Message1(exec_i_linking,current_module.sharedlibfilename);

  { for future use }
  StaticStr:='';
  StripStr:='';
  DynLinkStr:='';
  GCSectionsStr:='--gc-sections';

  { Write used files and libraries }
    WriteResponseFile(true,true);

    SoNameStr:='-soname '+ExtractFileName(current_module.sharedlibfilename);

    { Call linker }
    SplitBinCmd(Info.DllCmd[1],binstr,cmdstr);
    Replace(cmdstr,'$OPT',Info.ExtraOptions);
    if not(cs_link_on_target in current_settings.globalswitches) then
     begin
      Replace(cmdstr,'$EXE',(maybequoted(ScriptFixFileName(ChangeFileExt(current_module.sharedlibfilename,'.so')))));
      Replace(cmdstr,'$RES',(maybequoted(ScriptFixFileName(outputexedir+Info.ResName))));
      Replace(cmdstr,'$STATIC',StaticStr);
      Replace(cmdstr,'$STRIP',StripStr);
      Replace(cmdstr,'$GCSECTIONS',GCSectionsStr);
      Replace(cmdstr,'$DYNLINK',DynLinkStr);
      Replace(cmdstr,'$SONAME',SoNameStr);
     end
    else
     begin
      Replace(cmdstr,'$EXE',maybequoted(ScriptFixFileName(ChangeFileExt(current_module.sharedlibfilename,'.so'))));
      Replace(cmdstr,'$RES',maybequoted(ScriptFixFileName(outputexedir+Info.ResName)));
      Replace(cmdstr,'$STATIC',StaticStr);
      Replace(cmdstr,'$STRIP',StripStr);
      Replace(cmdstr,'$GCSECTIONS',GCSectionsStr);
      Replace(cmdstr,'$DYNLINK',DynLinkStr);
      Replace(cmdstr,'$SONAME',SoNameStr);
     end;
    success:=DoExec(FindUtil(utilsprefix+BinStr),cmdstr,true,false);

  { Strip the library ? }
    if success and (cs_link_strip in current_settings.globalswitches) then
     begin
       SplitBinCmd(Info.DllCmd[2],binstr,cmdstr);
       Replace(cmdstr,'$EXE',maybequoted(current_module.sharedlibfilename));
       success:=DoExec(FindUtil(utilsprefix+binstr),cmdstr,true,false);
     end;

  { Remove ReponseFile }
    if (success) and not(cs_link_nolink in current_settings.globalswitches) then
     DeleteFile(outputexedir+Info.ResName);

    MakeSharedLibrary:=success;   { otherwise a recursive call to link method }
end;

function TLinkerUltibo.PostProcessExecutable(const fn : string;isdll:boolean):boolean;
  type
    TElf32header=packed record
      magic0123         : longint;
      file_class        : byte;
      data_encoding     : byte;
      file_version      : byte;
      padding           : array[$07..$0f] of byte;

      e_type            : word;
      e_machine         : word;
      e_version         : longint;
      e_entry           : longint;          { entrypoint }
      e_phoff           : longint;          { program header offset }

      e_shoff           : longint;          { sections header offset }
      e_flags           : longint;
      e_ehsize          : word;             { elf header size in bytes }
      e_phentsize       : word;             { size of an entry in the program header array }
      e_phnum           : word;             { 0..e_phnum-1 of entrys }
      e_shentsize       : word;             { size of an entry in sections header array }
      e_shnum           : word;             { 0..e_shnum-1 of entrys }
      e_shstrndx        : word;             { index of string section header }
    end;
    TElf32sechdr=packed record
      sh_name           : longint;
      sh_type           : longint;
      sh_flags          : longint;
      sh_addr           : longint;

      sh_offset         : longint;
      sh_size           : longint;
      sh_link           : longint;
      sh_info           : longint;

      sh_addralign      : longint;
      sh_entsize        : longint;
    end;

  function MayBeSwapHeader(h : telf32header) : telf32header;
    begin
      result:=h;
      if source_info.endian<>target_info.endian then
        with h do
          begin
            result.e_type:=swapendian(e_type);
            result.e_machine:=swapendian(e_machine);
            result.e_version:=swapendian(e_version);
            result.e_entry:=swapendian(e_entry);
            result.e_phoff:=swapendian(e_phoff);
            result.e_shoff:=swapendian(e_shoff);
            result.e_flags:=swapendian(e_flags);
            result.e_ehsize:=swapendian(e_ehsize);
            result.e_phentsize:=swapendian(e_phentsize);
            result.e_phnum:=swapendian(e_phnum);
            result.e_shentsize:=swapendian(e_shentsize);
            result.e_shnum:=swapendian(e_shnum);
            result.e_shstrndx:=swapendian(e_shstrndx);
          end;
    end;

  function MaybeSwapSecHeader(h : telf32sechdr) : telf32sechdr;
    begin
      result:=h;
      if source_info.endian<>target_info.endian then
        with h do
          begin
            result.sh_name:=swapendian(sh_name);
            result.sh_type:=swapendian(sh_type);
            result.sh_flags:=swapendian(sh_flags);
            result.sh_addr:=swapendian(sh_addr);
            result.sh_offset:=swapendian(sh_offset);
            result.sh_size:=swapendian(sh_size);
            result.sh_link:=swapendian(sh_link);
            result.sh_info:=swapendian(sh_info);
            result.sh_addralign:=swapendian(sh_addralign);
            result.sh_entsize:=swapendian(sh_entsize);
          end;
    end;

  var
    f : file;

  function ReadSectionName(pos : longint) : String;
    var
      oldpos : longint;
      c : char;
    begin
      oldpos:=filepos(f);
      seek(f,pos);
      Result:='';
      while true do
        begin
          blockread(f,c,1);
          if c=#0 then
            break;
          Result:=Result+c;
        end;
      seek(f,oldpos);
    end;

  var
    elfheader : TElf32header;
    secheader : TElf32sechdr;
    i : longint;
    stringoffset : longint;
    secname : string;
  begin
    PostProcessExecutable:=false;
    { open file }
    assign(f,fn);
    {$push}{$I-}
    reset(f,1);
    if ioresult<>0 then
      Message1(execinfo_f_cant_open_executable,fn);
    { read header }
    blockread(f,elfheader,sizeof(tElf32header));
    elfheader:=MayBeSwapHeader(elfheader);
    seek(f,elfheader.e_shoff);
    { read string section header }
    seek(f,elfheader.e_shoff+sizeof(TElf32sechdr)*elfheader.e_shstrndx);
    blockread(f,secheader,sizeof(secheader));
    secheader:=MaybeSwapSecHeader(secheader);
    stringoffset:=secheader.sh_offset;

    seek(f,elfheader.e_shoff);
    status.datasize:=0;
    for i:=0 to elfheader.e_shnum-1 do
      begin
        blockread(f,secheader,sizeof(secheader));
        secheader:=MaybeSwapSecHeader(secheader);
        secname:=ReadSectionName(stringoffset+secheader.sh_name);
        if secname='.text' then
          begin
            Message1(execinfo_x_codesize,tostr(secheader.sh_size));
            status.codesize:=secheader.sh_size;
          end
        else if secname='.data' then
          begin
            Message1(execinfo_x_initdatasize,tostr(secheader.sh_size));
            inc(status.datasize,secheader.sh_size);
          end
        else if secname='.bss' then
          begin
            Message1(execinfo_x_uninitdatasize,tostr(secheader.sh_size));
            inc(status.datasize,secheader.sh_size);
          end;

      end;
    close(f);
    {$pop}
    if ioresult<>0 then
      ;
    PostProcessExecutable:=true;
  end;


{*****************************************************************************
                                     Initialize
*****************************************************************************}

initialization
{$ifdef arm}
  RegisterLinker(ld_ultibo,TLinkerUltibo);
  RegisterImport(system_arm_ultibo,TImportLibUltibo);
  RegisterExport(system_arm_ultibo,TExportLibUltibo);
  RegisterTarget(system_arm_ultibo_info);
{$endif arm}

{$ifdef i386}
  RegisterLinker(ld_ultibo,TLinkerUltibo);
  RegisterImport(system_i386_ultibo,TImportLibUltibo);
  RegisterExport(system_i386_ultibo,TExportLibUltibo);
  RegisterTarget(system_i386_ultibo_info);
{$endif i386}

{$ifdef AARCH64}
  RegisterLinker(ld_ultibo,TLinkerUltibo);
  RegisterImport(system_aarch64_ultibo,TImportLibUltibo);
  RegisterExport(system_aarch64_ultibo,TExportLibUltibo);
  RegisterTarget(system_aarch64_ultibo_info);
{$endif AARCH64}

end.
