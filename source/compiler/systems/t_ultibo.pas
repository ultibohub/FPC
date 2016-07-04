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


implementation

    uses
       SysUtils,
       cutils,cfileutl,cclasses,
       globtype,globals,systems,verbose,comphook,script,fmodule,i_ultibo,link,
       cpuinfo;

    type
       TLinkerUltibo=class(texternallinker)
       private
          Function  WriteResponseFile: Boolean;
       public
          constructor Create; override;
          procedure SetDefaultInfo; override;
          function  MakeExecutable:boolean; override;
          function postprocessexecutable(const fn : string;isdll:boolean):boolean;
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
   end;
end;


Function TLinkerUltibo.WriteResponseFile: Boolean;
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
  case current_settings.controllertype of
   ct_rpia,
   ct_rpib,
   ct_rpizero,
   ct_rpi2b,
   ct_rpi3b:
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
  {$endif ARM}
  {$ifdef i386}
  //To Do
  prtobj:='';
  cprtobj:='';
  {$endif i386}
  {$ifdef AARCH64}
  //To Do
  prtobj:='';
  cprtobj:='';
  {$endif AARCH64}
{$else}
  prtobj:='prt0';
  cprtobj:='cprt0';
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
        
    else
      if not (cs_link_nolink in current_settings.globalswitches) then
      	 internalerror(200902011);
  end;

  case current_settings.controllertype of
   ct_rpia,
   ct_rpib,
   ct_rpizero,
   ct_rpi2b,
   ct_rpi3b:
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
{$endif ARM}
 
{$ifdef i386}
//To Do
{$endif i386}

{$ifdef AARCH64}
//To Do
{$endif AARCH64}

  { Write and Close response }
  linkres.writetodisk;
  linkres.free;

  WriteResponseFile:=True;

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
  { for future use }
  StaticStr:='';
  StripStr:='';
  DynLinkStr:='';

  GCSectionsStr:='--gc-sections';
  //if not(cs_link_extern in current_settings.globalswitches) then
  if not(cs_link_nolink in current_settings.globalswitches) then
   Message1(exec_i_linking,current_module.exefilename);

{ Write used files and libraries }
  WriteResponseFile();

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

  if success and (target_info.system in [system_arm_ultibo]) then
    begin
     {$ifdef ARM}
     case current_settings.controllertype of
      ct_rpia,
      ct_rpib,
      ct_rpizero:begin
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel.img',true,false);
       end;
      ct_rpi2b,
      ct_rpi3b:begin
        success:=DoExec(FindUtil(utilsprefix+'objcopy'),'-O binary '+
          ChangeFileExt(current_module.exefilename,'.elf')+' kernel7.img',true,false);
       end;
     end;  
     {$endif ARM}
     {$ifdef i386}
     //To Do
     {$endif i386}
     {$ifdef AARCH64}
     //To Do
     {$endif AARCH64}
    end;

  MakeExecutable:=success;   { otherwise a recursive call to link method }
end;


function TLinkerUltibo.postprocessexecutable(const fn : string;isdll:boolean):boolean;
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
    postprocessexecutable:=false;
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
    postprocessexecutable:=true;
  end;


{*****************************************************************************
                                     Initialize
*****************************************************************************}

initialization
{$ifdef arm}
  RegisterLinker(ld_ultibo,TLinkerUltibo);
  RegisterTarget(system_arm_ultibo_info);
{$endif arm}

{$ifdef i386}
  RegisterLinker(ld_ultibo,TLinkerUltibo);
  RegisterTarget(system_i386_ultibo_info);
{$endif i386}

{$ifdef AARCH64}
//To Do
{$endif AARCH64}

end.
