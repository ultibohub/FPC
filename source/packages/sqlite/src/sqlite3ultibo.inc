{
Ultibo SQLite OS interface include file.

Copyright (C) 2016 - SoftOz Pty Ltd.

Arch
====

 <All>

Boards
======

 <All>

Licence
=======

 LGPLv2.1 with static linking exception (See COPYING.modifiedLGPL.txt)
 
Credits
=======

 Information for this unit was obtained from:
 
References
==========

  SQLite - https://www.sqlite.org/
  
  SQLite Custom Builds - https://www.sqlite.org/custombuild.html
  
SQLite3Ultibo
=============

 This file provides the OS interface required by SQLite to run on top of Ultibo.
 This includes the mutex subsystem, the memory allocation subsystem and the 
 VFS implementation.
 
 For more information see section 5.0 "Porting SQLite To A New Operating System"
 of the SQLite Custom Builds document here:
 
  https://www.sqlite.org/custombuild.html
 
 Building SQLite for Ultibo:
 
   Download the latest amalgamation from https://www.sqlite.org/amalgamation.html
   and compile the sqlite3.c file as a static library using the following commands.
   
  ARMv6: 
  
   arm-none-eabi-gcc -O2 -mabi=aapcs -marm -march=armv6 -mfpu=vfp -mfloat-abi=hard -DSQLITE_OS_OTHER=1 -DSQLITE_OMIT_LOAD_EXTENSION -c sqlite3.c
   arm-none-eabi-ar rcs libsqlite3.a sqlite3.o
   
   Dump:
    arm-none-eabi-objdump -d libsqlite3.a > libsqlite3.list
    
  ARMv7: 
  
   arm-none-eabi-gcc -O2 -mabi=aapcs -marm -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard -DSQLITE_OS_OTHER=1 -DSQLITE_OMIT_LOAD_EXTENSION -c sqlite3.c
   arm-none-eabi-ar rcs libsqlite3.a sqlite3.o
   
   Dump:
    arm-none-eabi-objdump -d libsqlite3.a > libsqlite3.list
   
  ARMv8: 
  
   aarch64-none-elf-gcc -O2 -march=armv8-a -DSQLITE_OS_OTHER=1 -DSQLITE_OMIT_LOAD_EXTENSION -c sqlite3.c
   aarch64-none-elf-ar rcs libsqlite3.a sqlite3.o
   
   Note: Later versions of GCC add -mabi=lp64
   
   Dump:
    aarch64-none-elf-objdump -d libsqlite3.a > libsqlite3.list
   
}

{--$DEFINE SQLITE3_DEBUG}  {Enable debug output/counters for SQLite functions (Default: Off)} 

{==============================================================================}
{==============================================================================}
{C Libraries (Needed here to ensure that libc.a and libgcc.a are listed last in the link.res file)(Fixed in 1.3.075)}
{--$linklib c}
{--$linklib gcc}

{==============================================================================}
{==============================================================================}
{SQLite Internal constants}
const
 NO_LOCK         = 0;
 SHARED_LOCK     = 1;
 RESERVED_LOCK   = 2;
 PENDING_LOCK    = 3;
 EXCLUSIVE_LOCK  = 4;

{==============================================================================}
{==============================================================================}
{SQLite Internal types}
type
 psqlite3_ultibo_file = ^sqlite3_ultibo_file;
 sqlite3_ultibo_file = record
   pMethod:psqlite3_io_methods; {Must be first}
   pVfs:psqlite3_vfs;           {The VFS used to open this file}
   Handle:THandle;
   Filename:String;
   AccessMode:LongWord;
   ShareMode:LongWord;
   CreateFlags:LongWord;
   FileAttributes:LongWord;
   LockType:LongInt;
   ChunkSize:LongInt;
   LastErrno:LongWord;
 end;
 
{==============================================================================}
{==============================================================================}
{SQLite Internal variables}
var
 sqlite3_ultibo_vfs: sqlite3_vfs;
 sqlite3_ultibo_io_methods: sqlite3_io_methods;
 sqlite3_ultibo_mem_methods: sqlite3_mem_methods;
 sqlite3_ultibo_mutex_methods: sqlite3_mutex_methods;
 
 sqlite3_ultibo_mutex_master: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_mem: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_open: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_prng: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_lru: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_pmem: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_app1: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_app2: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_app3: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_vfs1: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_vfs2: TMutexHandle = INVALID_HANDLE_VALUE;
 sqlite3_ultibo_mutex_vfs3: TMutexHandle = INVALID_HANDLE_VALUE;
 
 sqlite3_ultibo_initialized: Boolean;
 sqlite3_ultibo_os_initialized: Boolean;
 
{==============================================================================}
{==============================================================================}
{Forward Declarations} 
function sqlite3_ultibo_vfs_CurrentTimeInt64(vfs: psqlite3_vfs; time: psqlite3_int64): cint; cdecl; forward;
 
{==============================================================================}
{==============================================================================}
{SQLite Memory Allocation functions (See: https://www.sqlite.org/c3ref/mem_methods.html)}
function sqlite3_ultibo_mem_malloc(size : cint) : pointer; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_malloc (size=' + IntToStr(size) + ')');
 {$ENDIF}
 
 Result:=GetMem(size);
end;

{==============================================================================}

procedure sqlite3_ultibo_mem_free(p : pointer); cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_free (p=' + IntToHex(PtrUInt(p),8) + ')');
 {$ENDIF}
 
 FreeMem(p);
end;

{==============================================================================}

function sqlite3_ultibo_mem_realloc(p : pointer;size : cint) : pointer; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_realloc (p=' + IntToHex(PtrUInt(p),8) + ' size=' + IntToStr(size) + ')');
 {$ENDIF}
 
 Result:=ReallocMem(p,size);
end;

{==============================================================================}

function sqlite3_ultibo_mem_size(p : pointer) : cint; cdecl;
begin
 {}
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_size (p=' + IntToHex(PtrUInt(p),8) + ')');
 {$ENDIF}
 
 Result:=MemSize(p);
end;

{==============================================================================}

function sqlite3_ultibo_mem_roundup(size : cint) : cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_roundup (size=' + IntToStr(size) + ')');
 {$ENDIF}
 
 Result:=RoundUp(size,HEAP_MIN_ALIGNMENT);
end;

{==============================================================================}

function sqlite3_ultibo_mem_init(p : pointer): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_init');
 {$ENDIF}
 
 Result:=SQLITE_OK;
end;

{==============================================================================}

procedure sqlite3_ultibo_mem_shutdown(p : pointer); cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mem_shutdown (p=' + IntToHex(PtrUInt(p),8) + ')');
 {$ENDIF}
end;
 
{==============================================================================}
{==============================================================================}
{SQLite Mutex functions (See: https://www.sqlite.org/c3ref/mutex_alloc.html)}
function sqlite3_ultibo_mutex_init(): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_init');
 {$ENDIF}
 
 {Create Static Mutexes (Documentation says it must be safe to call this multiple times)}
 if sqlite3_ultibo_mutex_master = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_master:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_mem = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_mem:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_open = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_open:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_prng = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_prng:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_lru = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_lru:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_pmem = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_pmem:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_app1 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_app1:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_app2 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_app2:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_app3 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_app3:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_vfs1 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_vfs1:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_vfs2 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_vfs2:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
  
 if sqlite3_ultibo_mutex_vfs3 = INVALID_HANDLE_VALUE then
  begin
   sqlite3_ultibo_mutex_vfs3:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
  end;
 
 {Return Result}
 Result:=SQLITE_OK;
end;

{==============================================================================}

function sqlite3_ultibo_mutex_end(): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_end');
 {$ENDIF}

 {Destroy Static Mutexes}
 MutexDestroy(sqlite3_ultibo_mutex_master);
 MutexDestroy(sqlite3_ultibo_mutex_mem);
 MutexDestroy(sqlite3_ultibo_mutex_open);
 MutexDestroy(sqlite3_ultibo_mutex_prng);
 MutexDestroy(sqlite3_ultibo_mutex_lru);
 MutexDestroy(sqlite3_ultibo_mutex_pmem);
 MutexDestroy(sqlite3_ultibo_mutex_app1);
 MutexDestroy(sqlite3_ultibo_mutex_app2);
 MutexDestroy(sqlite3_ultibo_mutex_app3);
 MutexDestroy(sqlite3_ultibo_mutex_vfs1);
 MutexDestroy(sqlite3_ultibo_mutex_vfs2);
 MutexDestroy(sqlite3_ultibo_mutex_vfs3);
 
 {Return Result}
 Result:=SQLITE_OK;
end;

{==============================================================================}

function sqlite3_ultibo_mutex_alloc(n: cint): psqlite3_mutex; cdecl;
var
 Handle:TMutexHandle;
begin
 {}
 Result:=nil;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_alloc (n=' + IntToStr(n) + ')');
 {$ENDIF}
 
 {Check Type}
 case n of
  {Dynamic}
  SQLITE_MUTEX_FAST,SQLITE_MUTEX_RECURSIVE:begin
    Handle:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
    if Handle <> INVALID_HANDLE_VALUE then
     begin
      Result:=psqlite3_mutex(Handle);
     end;
   end;
  {Static}
  SQLITE_MUTEX_STATIC_MASTER:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_master);
  SQLITE_MUTEX_STATIC_MEM:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_mem);
  SQLITE_MUTEX_STATIC_OPEN:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_open);
  SQLITE_MUTEX_STATIC_PRNG:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_prng);
  SQLITE_MUTEX_STATIC_LRU:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_lru);
  SQLITE_MUTEX_STATIC_PMEM:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_pmem);
  SQLITE_MUTEX_STATIC_APP1:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_app1);
  SQLITE_MUTEX_STATIC_APP2:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_app2);
  SQLITE_MUTEX_STATIC_APP3:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_app3);
  SQLITE_MUTEX_STATIC_VFS1:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_vfs1);
  SQLITE_MUTEX_STATIC_VFS2:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_vfs2);
  SQLITE_MUTEX_STATIC_VFS3:Result:=psqlite3_mutex(sqlite3_ultibo_mutex_vfs3); 
 end; 
end;

{==============================================================================}

procedure sqlite3_ultibo_mutex_free(mtx: psqlite3_mutex); cdecl; 
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_free (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}

 {Check mtx}
 if mtx = nil then Exit;
 
 {Destroy Mutex}
 MutexDestroy(TMutexHandle(mtx));
end;

{==============================================================================}

procedure sqlite3_ultibo_mutex_enter(mtx: psqlite3_mutex); cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_enter (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}
 
 {Check mtx}
 if mtx = nil then Exit;
 
 {Lock Mutex}
 MutexLock(TMutexHandle(mtx));
end;

{==============================================================================}

function sqlite3_ultibo_mutex_try(mtx: psqlite3_mutex): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_try (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}
 
 {Check mtx}
 if mtx = nil then
  begin
   Result:=SQLITE_OK;
  end
 else
  begin
   {Try Mutex}
   if MutexTryLock(TMutexHandle(mtx)) = ERROR_SUCCESS then
    begin
     Result:=SQLITE_OK;
    end 
   else
    begin
     Result:=SQLITE_BUSY;   
    end; 
  end;
end;

{==============================================================================}

procedure sqlite3_ultibo_mutex_leave(mtx: psqlite3_mutex); cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_leave (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}

 {Check mtx}
 if mtx = nil then Exit;
 
 {Unlock Mutex}
 MutexUnlock(TMutexHandle(mtx));
end;

{==============================================================================}

function sqlite3_ultibo_mutex_held(mtx: psqlite3_mutex): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_held (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}

 {Check mtx}
 if mtx = nil then
  begin
   {Return True}
   Result:=1;
  end
 else 
  begin
   if MutexOwner(TMutexHandle(mtx)) = ThreadGetCurrent then
    begin
     Result:=1;
    end
   else
    begin
     Result:=0;
    end;
  end; 
end;

{==============================================================================}

function sqlite3_ultibo_mutex_notheld(mtx: psqlite3_mutex): cint; cdecl;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_mutex_notheld (mtx=' + IntToHex(PtrUInt(mtx),8) + ')');
 {$ENDIF}

 {Check mtx}
 if mtx = nil then
  begin
   {Return True}
   Result:=1;
  end
 else 
  begin
   if MutexOwner(TMutexHandle(mtx)) <> ThreadGetCurrent then
    begin
     Result:=1;
    end
   else
    begin
     Result:=0;
    end;
  end; 
end;

{==============================================================================}
{==============================================================================}
{SQLite VFS functions (See: https://www.sqlite.org/c3ref/vfs.html)}
{Version 1}
function sqlite3_ultibo_vfs_Open(vfs: psqlite3_vfs; zName: pansichar; id: psqlite3_file; flags: cint; pOutFlags: pcint): cint; cdecl;
{Open a file}
var
 Handle:THandle;
 Filename:String;
 AccessMode:LongWord;
 ShareMode:LongWord;
 CreateFlags:LongWord;
 FileAttributes:LongWord;
 pFile:psqlite3_ultibo_file;
 
 eType:cint;
 isExclusive:Boolean;
 isDelete:Boolean;
 isCreate:Boolean;
 isReadonly:Boolean; 
 isReadWrite:Boolean;
 isOpenJournal:Boolean;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check Vfs}
 if vfs = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Open (vfs=' + IntToHex(PtrUInt(vfs),8) + ' zName=' + zName + ' id=' + IntToHex(PtrUInt(id),8) + ' flags=' + IntToHex(flags,8) + ')');
 {$ENDIF}
 
 {Check id}
 if id = nil then Exit;
 
 {Get Type}
 eType:=flags and $FFFFFF00;  {Type of file to open}
 
 {Check Flags}
 isExclusive:=(flags and SQLITE_OPEN_EXCLUSIVE) <> 0;
 isDelete:=(flags and SQLITE_OPEN_DELETEONCLOSE) <> 0;
 isCreate:=(flags and SQLITE_OPEN_CREATE) <> 0;
 isReadonly:=(flags and SQLITE_OPEN_READONLY) <> 0;
 isReadWrite:=(flags and SQLITE_OPEN_READWRITE) <> 0;
 isOpenJournal:=(isCreate and ((eType = SQLITE_OPEN_MASTER_JOURNAL) or (eType = SQLITE_OPEN_MAIN_JOURNAL) or (eType = SQLITE_OPEN_WAL)));
 
 {Check the following statements are true:
   (a) Exactly one of the READWRITE and READONLY flags must be set, and
   (b) if CREATE is set, then READWRITE must also be set, and
   (c) if EXCLUSIVE is set, then CREATE must also be set.
   (d) if DELETEONCLOSE is set, then CREATE must also be set}
 if isReadonly and isReadWrite then Exit;
 if isCreate and not(isReadWrite) then Exit;
 if isExclusive and not(isCreate) then Exit;
 if isDelete and not(isCreate) then Exit;

 {The main DB, main journal, WAL file and master journal are never
  automatically deleted. Nor are they ever temporary files}  
 if isDelete or (zName = nil) then
  begin
   if eType = SQLITE_OPEN_MAIN_DB then Exit;
   if eType = SQLITE_OPEN_MAIN_JOURNAL then Exit;
   if eType = SQLITE_OPEN_MASTER_JOURNAL then Exit;
   if eType = SQLITE_OPEN_WAL then Exit;
  end;  
  
 {Check that the upper layer has set one of the "file-type" flags}
 if (eType <> SQLITE_OPEN_MAIN_DB) and (eType <> SQLITE_OPEN_TEMP_DB)
  and (eType <> SQLITE_OPEN_MAIN_JOURNAL) and (eType <> SQLITE_OPEN_TEMP_JOURNAL)
  and (eType <> SQLITE_OPEN_SUBJOURNAL) and (eType <> SQLITE_OPEN_MASTER_JOURNAL) 
  and (eType <> SQLITE_OPEN_TRANSIENT_DB) and (eType <> SQLITE_OPEN_WAL) then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Update pFile}
 FillChar(pFile^,SizeOf(sqlite3_ultibo_file),0);
 pFile^.Handle:=INVALID_HANDLE_VALUE;
 
 {Check zName}
 if zName = nil then
  begin
   {Get Filename (Temporary)}
   Filename:='C:\' + IntToHex(ThreadGetCurrent,8) + IntToHex(GetTickCount64,8) + '.tmp';
   //sqlite3_temp_directory //To Do
  end
 else
  begin
   {Get Filename}
   Filename:=zName;
  end;  

 {Check Directory}
 if FSDirectoryExists(Filename) then
  begin
   Result:=SQLITE_CANTOPEN_ISDIR;
   Exit;
  end;
 
 {Get Access Mode}
 if isReadWrite then
  begin
   AccessMode:=GENERIC_READ or GENERIC_WRITE;
  end 
 else
  begin
   AccessMode:=GENERIC_READ;
  end; 
 
 {Get Share Mode}
 ShareMode:=FILE_SHARE_READ or FILE_SHARE_WRITE;
 
 {Get Create Flags}
 {SQLITE_OPEN_EXCLUSIVE is used to make sure that a new file is  created. SQLite
   doesn't use it to indicate "exclusive access" as it is usually understood}
 if isExclusive then
  begin
   {Creates a new file, only if it does not already exist. If the file exists, it fails}
   CreateFlags:=CREATE_NEW;
  end
 else if isCreate then
  begin
   {Open existing file, or create if it doesn't exist}
   CreateFlags:=OPEN_ALWAYS;
  end
 else
  begin
   {Opens a file, only if it exists}
   CreateFlags:=OPEN_EXISTING;
  end;  
  
 {Get File Attributes} 
 if isDelete then 
  begin
   FileAttributes:=FILE_ATTRIBUTE_TEMPORARY or FILE_ATTRIBUTE_HIDDEN or FILE_FLAG_DELETE_ON_CLOSE;
  end
 else
  begin
   FileAttributes:=FILE_ATTRIBUTE_NORMAL;
  end;  
 
 {Create File}
 Handle:=FSCreateFile(Filename,AccessMode,ShareMode,CreateFlags,FileAttributes);
 if Handle = INVALID_HANDLE_VALUE then
  begin
   Result:=SQLITE_CANTOPEN;
   Exit;
  end;
 
 {Update pFile}
 pFile^.pMethod:=@sqlite3_ultibo_io_methods;
 pFile^.pVfs:=vfs;
 pFile^.Handle:=Handle;
 pFile^.Filename:=zName;
 pFile^.AccessMode:=AccessMode;
 pFile^.ShareMode:=ShareMode;
 pFile^.CreateFlags:=CreateFlags;
 pFile^.FileAttributes:=FileAttributes;
 
 {Check pOutFlags}
 if pOutFlags <> nil then
  begin
   {Return pOutFlags}
   if isReadWrite then
    begin
     pOutFlags^:=SQLITE_OPEN_READWRITE;
    end
   else
    begin
     pOutFlags^:=SQLITE_OPEN_READONLY;
    end;
  end;  
  
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then 
  begin
   {Check pOutFlags}
   if pOutFlags = nil then
    begin
     PlatformLogDebug('sqlite3_ultibo_vfs_Open (Result=' + IntToStr(Result) + ')');
    end
   else
    begin
     PlatformLogDebug('sqlite3_ultibo_vfs_Open (Result=' + IntToStr(Result) + ' pOutFlags=' + IntToStr(pOutFlags^) + ')');
    end;    
  end;
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_Delete(vfs: psqlite3_vfs; zName: pansichar; syncDir: cint): cint; cdecl;
{Delete the named file}
var
 Filename:String;
 Attributes:LongWord;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check Vfs}
 if vfs = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Delete (vfs=' + IntToHex(PtrUInt(vfs),8) + ' zName=' + zName + ' syncDir=' + IntToStr(syncDir) + ')');
 {$ENDIF}
 
 {Check zName}
 if zName = nil then Exit;
 
 {Get Filename}
 Filename:=zName;
 
 {Get Attributes}
 Attributes:=FSFileGetAttr(Filename);
 if Attributes = INVALID_FILE_ATTRIBUTES then
  begin
   Result:=SQLITE_IOERR_DELETE_NOENT;
   Exit;
  end;
  
 {Check Directory}
 if (Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
  begin
   Result:=SQLITE_ERROR;
   Exit;
  end;
  
 {Delete File}
 if not FSDeleteFile(Filename) then
  begin
   Result:=SQLITE_ERROR;
   Exit;
  end;
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Delete (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_Access(vfs: psqlite3_vfs; zName: pansichar; flags: cint; pResOut: pcint): cint; cdecl;
{Check the existence and status of a file}
var
 Filename:String;
 Attributes:LongWord;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check Vfs}
 if vfs = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Access (vfs=' + IntToHex(PtrUInt(vfs),8) + ' zName=' + zName + ' flags=' + IntToHex(flags,8) + ')');
 {$ENDIF}
 
 {Check zName}
 if zName = nil then Exit;
 
 {Check pResOut}
 if pResOut = nil then Exit;
 
 {Get Filename}
 Filename:=zName;
 
 {Get Attributes}
 Attributes:=FSFileGetAttr(Filename);

 {Check flags}
 case flags of 
  SQLITE_ACCESS_READ,SQLITE_ACCESS_EXISTS:begin
    {Return pResOut}
    pResOut^:=0;
    if Attributes <> INVALID_FILE_ATTRIBUTES then
     begin
      pResOut^:=1;
     end;
   end;
  SQLITE_ACCESS_READWRITE:begin
    {Return pResOut}
    pResOut^:=0;
    if (Attributes <> INVALID_FILE_ATTRIBUTES) and ((Attributes and FILE_ATTRIBUTE_READONLY) = 0) then
     begin
      pResOut^:=1;
     end;
   end;
 end; 
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Access (Result=' + IntToStr(Result) + ' pResOut=' + IntToStr(pResOut^) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_FullPathname(vfs: psqlite3_vfs; zName: pansichar; nOut: cint; zOut: pansichar): cint; cdecl;
{Turn a relative pathname into a full pathname.  Write the full
 pathname into zOut[].  zOut[] will be at least pVfs->mxPathname
 bytes in size}
var
 Fullname:String; 
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check Vfs}
 if vfs = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_FullPathname (vfs=' + IntToHex(PtrUInt(vfs),8) + ' zName=' + zName + ' nOut=' + IntToStr(nOut) + ')');
 {$ENDIF}
 
 {Check zOut}
 if zOut = nil then Exit;
 
 {Check Exists}
 if FSFileExists(zName) or FSDirectoryExists(zName) then
  begin
   {Get Fullname}
   Fullname:=FSGetFullPathName(zName);
  end
 else
  begin
   {Get Fullname}
   Fullname:=FSGetCurrentDir + zName; //To Do //Normalize and resolve path
   //sqlite3_data_directory //To Do
  end;  
 
 {Return Fullname}
 StrLCopy(zOut,PChar(Fullname),nOut);
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_FullPathname (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_Randomness(vfs: psqlite3_vfs; nByte: cint; zOut: pansichar): cint; cdecl;
{Write up to nBuf bytes of randomness into zBuf}
 type
  PEntropyGatherer = ^TEntropyGatherer;
  TEntropyGatherer = record
   a    : pansichar; {Gather entropy into this buffer}
   na   : cint;      {Size of a[] in bytes}
   i    : cint;      {XOR next input into a[i]}
   nXor : cint;      {Number of XOR operations done}
  end;
 
 procedure xorMemory(p: PEntropyGatherer; x: pansichar; sz: cint);
 {Mix sz bytes of entropy into p}
 var
  j:cint;
  k:cint;
 begin
  {}
  k:=p^.i;
  for j:=0 to sz - 1 do
   begin
    Byte(p^.a[k]):=Byte(p^.a[k]) xor Byte(x[j]);
    Inc(k);
    
    if k >= p^.na then k:=0;
   end;
  
  p^.i:=k;
  p^.nXor:=p^.nXor + sz;
 end;
 
var
 e:TEntropyGatherer;
 x:SYSTEMTIME;
 pid:DWORD;
 cnt:ULONGLONG;
 id:TGUID;
begin
 {}
 Result:=0;
 
 {Check Vfs}
 if vfs = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Randomness (vfs=' + IntToHex(PtrUInt(vfs),8) + ' nByte=' + IntToStr(nByte) + ')');
 {$ENDIF}
 
 {Check zOut}
 if zOut = nil then Exit;
 
 {Zero the zOut buffer}
 FillChar(zOut^,nByte,0);
 
 {Setup Entropy Gatherer}
 e.a:=zOut;
 e.na:=nByte;
 e.nXor:=0;
 e.i:=0;
 
 {Get System Time}
 GetLocalTime(x);
 xorMemory(@e,PAnsiChar(@x),SizeOf(SYSTEMTIME));
 
 {Get Current Thread}
 pid:=ThreadGetCurrent;
 xorMemory(@e,PAnsiChar(@pid),SizeOf(DWORD));
 
 {Get Tick Count}
 cnt:=GetTickCount64;
 xorMemory(@e,PAnsiChar(@cnt),SizeOf(ULONGLONG));

 {Create GUID}
 FillChar(id,SizeOf(TGUID),0);
 id:=CreateGUID;
 xorMemory(@e,PAnsiChar(@id),SizeOf(TGUID));

 {Create GUID}
 FillChar(id,SizeOf(TGUID),0);
 id:=CreateGUID;
 xorMemory(@e,PAnsiChar(@id),SizeOf(TGUID));
 
 {Return Result}
 if e.nXor > nByte then Result:=nByte else Result:=e.nXor;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Randomness (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_Sleep(vfs: psqlite3_vfs; microseconds: cint): cint; cdecl;    
{Sleep for a little while.  Return the amount of time slept}
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Sleep (vfs=' + IntToHex(PtrUInt(vfs),8) + ' microseconds=' + IntToStr(microseconds) + ')');
 {$ENDIF}
 
 {Sleep}
 ThreadSleep((microseconds + 999) div 1000);
 
 {Return Result}
 Result:=((microseconds + 999) div 1000) * 1000;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_Sleep (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_CurrentTime(vfs: psqlite3_vfs; time: pcdouble): cint; cdecl;
{** Find the current time (in Universal Coordinated Time).  Write the
** current time and date as a Julian Day number into *prNow and
** return 0.  Return 1 if the time and date cannot be found.
}
var
 Status:cint;
 Time64:sqlite3_int64;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_CurrentTime (vfs=' + IntToHex(PtrUInt(vfs),8) + ')');
 {$ENDIF}

 {Get Time 64}
 Status:=sqlite3_ultibo_vfs_CurrentTimeInt64(vfs,@Time64);
 if Status <> 0 then
  begin
   {Return Current Time}
   time^:=Time64 / 86400000.0;
  end;
  
 {Return Result}
 Result:=Status;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_CurrentTime (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_vfs_GetLastError(vfs: psqlite3_vfs; nBuf: cint; zBuf: pansichar): cint; cdecl;
{The idea is that this function works like a combination of
 GetLastError() and FormatMessage() on Windows (or errno and
 strerror_r() on Unix). After an error is returned by an OS
 function, SQLite calls this function with zBuf pointing to
 a buffer of nBuf bytes. The OS layer should populate the
 buffer with a nul-terminated UTF-8 encoded error message
 describing the last IO error to have occurred within the calling
 thread}
var
 Value:String;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_GetLastError (vfs=' + IntToHex(PtrUInt(vfs),8) + ' nBuf=' + IntToStr(nBuf) + ')');
 {$ENDIF}
 
 {Return Result}
 Result:=ThreadGetLastError;
 
 {Get String}
 Value:=ErrorToString(Result);
 
 {Copy String}
 StrLCopy(zBuf,PChar(Value),nBuf);
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_GetLastError (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}
{Version 2 or later}
function sqlite3_ultibo_vfs_CurrentTimeInt64(vfs: psqlite3_vfs; time: psqlite3_int64): cint; cdecl; 	
{Find the current time (in Universal Coordinated Time).  Write into *piNow
 the current time and date as a Julian Day number times 86_400_000.  In
 other words, write into *piNow the number of milliseconds since the Julian
 epoch of noon in Greenwich on November 24, 4714 B.C according to the
 proleptic Gregorian calendar.

 On success, return SQLITE_OK.  Return SQLITE_ERROR if the time and date
 cannot be found}
var
 Value:SysUtils.FILETIME;
 MaxValue:sqlite3_int64;
 FiletimeEpoch:sqlite3_int64; 
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_CurrentTimeInt64 (vfs=' + IntToHex(PtrUInt(vfs),8) + ')');
 {$ENDIF}
 
 {Get Epoch}
 FiletimeEpoch:=23058135 * 8640000;
 
 {Get Max Value}
 MaxValue:=2000000000 + 2000000000 + 294967296; 

 {Get System Time}
 Int64(Value):=ClockGetTime;
 
 {Return Current Time}
 time^:=FiletimeEpoch + (Value.dwHighDateTime * MaxValue) + (Value.dwLowDateTime div 10000);
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_vfs_CurrentTimeInt64 (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}
{==============================================================================}
{SQLite IO functions (See: https://www.sqlite.org/c3ref/io_methods.html}
{Version 1}
function sqlite3_ultibo_io_Close(id: psqlite3_file): cint; cdecl;
{Close a file}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Close (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);

 {Close file}
 if not FSCloseFile(pFile^.Handle) then
  begin
   Result:=SQLITE_IOERR_CLOSE;
   Exit;
  end; 
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Close (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Read(id: psqlite3_file; pBuf: pointer; amt: cint; offset: sqlite3_int64): cint; cdecl;
{Read data from a file into a buffer.  Return SQLITE_OK if all
 bytes were read successfully and SQLITE_IOERR if anything goes
 wrong}
var
 nRead:cint;
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Read (id=' + IntToHex(PtrUInt(id),8) + ' amt=' + IntToStr(amt) + ' offset=' + IntToStr(offset) + ')');
 {$ENDIF}
 
 {Check pBuf}
 if pBuf = nil then Exit;
 
 {Check amt}
 if amt <= 0 then Exit;
 
 {Check offset}
 if offset < 0 then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Seek file}
 if FSFileSeekEx(pFile^.Handle,offset,FILE_BEGIN) = -1 then
  begin
   Result:=SQLITE_FULL;
   Exit;
  end;
  
 {Read file} 
 nRead:=FSFileRead(pFile^.Handle,pBuf^,amt);
 if nRead < amt then
  begin
   {Short read (Unread parts of the buffer must be zero-filled)}
   FillChar(Pointer(pBuf + nRead)^,amt - nRead,0);
   
   Result:=SQLITE_IOERR_SHORT_READ;
   Exit;
  end;
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Read (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Write(id: psqlite3_file; pBuf: pointer; amt: cint; offset: sqlite3_int64): cint; cdecl;
{Write data from a buffer into a file.  Return SQLITE_OK on success
 or some other error code on failure}
var
 nWrite:cint;
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Write (id=' + IntToHex(PtrUInt(id),8) + ' amt=' + IntToStr(amt) + ' offset=' + IntToStr(offset) + ')');
 {$ENDIF}
 
 {Check pBuf}
 if pBuf = nil then Exit;
 
 {Check amt}
 if amt <= 0 then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Seek file}
 if FSFileSeekEx(pFile^.Handle,offset,FILE_BEGIN) = -1 then
  begin
   Result:=SQLITE_IOERR_SEEK;
   Exit;
  end;
 
 {Write file} 
 nWrite:=FSFileWrite(pFile^.Handle,pBuf^,amt);
 if nWrite < amt then
  begin
   Result:=SQLITE_IOERR_WRITE;
   Exit;
  end;
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Write (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Truncate(id: psqlite3_file; size: sqlite3_int64): cint; cdecl;
{Truncate an open file to a specified size}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Truncate (id=' + IntToHex(PtrUInt(id),8) + ' size=' + IntToStr(size) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {If the user has configured a chunk-size for this file, truncate the file so that it consists of an integer
  number of chunks (i.e. the actual file size after the operation may be larger than the requested size)}
 if pFile^.ChunkSize > 0 then
  begin
   size:=((size + pFile^.ChunkSize - 1) div pFile^.ChunkSize) * pFile^.ChunkSize;
  end;
 
 {Seek File}
 if FSFileSeekEx(pFile^.Handle,size,FILE_BEGIN) = -1 then
  begin
   Result:=SQLITE_IOERR_TRUNCATE;
   Exit;
  end;
 
 {Set End Of File}
 if not FSSetEndOfFile(pFile^.Handle) then
  begin
   Result:=SQLITE_IOERR_TRUNCATE;
   Exit;
  end;
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Truncate (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Sync(id: psqlite3_file; flags: cint): cint; cdecl;
{Make sure all writes to a particular file are committed to disk}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Sync (id=' + IntToHex(PtrUInt(id),8) + ' flags=' + IntToHex(flags,8) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Check Handle}
 if pFile^.Handle = INVALID_HANDLE_VALUE then
  begin
   Result:=SQLITE_IOERR_FSYNC;
   Exit;
  end; 
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Sync (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_FileSize(id: psqlite3_file; pSize: psqlite3_int64): cint; cdecl;
{Determine the current size of a file in bytes}
var
 Size:Int64;
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_FileSize (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Check pSize}
 if pSize = nil then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Get size}
 Size:=FSFileSizeEx(pFile^.Handle);
 if Size = -1 then
  begin
   Result:=SQLITE_IOERR_FSTAT;
   Exit;
  end;
 
 {Return pSize}
 pSize^:=Size;
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_FileSize (pSize=' + IntToStr(pSize^) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Lock(id: psqlite3_file; locktype: cint): cint; cdecl;
{Lock the file with the lock specified by parameter locktype - one
 of the following:

     (1) SHARED_LOCK
     (2) RESERVED_LOCK
     (3) PENDING_LOCK
     (4) EXCLUSIVE_LOCK

 Sometimes when requesting one lock state, additional lock states
 are inserted in between.  The locking might fail on one of the later
 transitions leaving the lock state different from what it started but
 still short of its goal.  The following chart shows the allowed
 transitions and the inserted intermediate states:

    UNLOCKED -> SHARED
    SHARED -> RESERVED
    SHARED -> (PENDING) -> EXCLUSIVE
    RESERVED -> (PENDING) -> EXCLUSIVE
    PENDING -> EXCLUSIVE

 This routine will only increase a lock.  The winUnlock() routine
 erases all locks at once and returns us immediately to locking level 0.
 It is not possible to lower the locking level one step at a time.  You
 must go straight to locking level 0}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Lock (id=' + IntToHex(PtrUInt(id),8) + ' locktype=' + IntToStr(locktype) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {If there is already a lock of this type or more restrictive on the file, do nothing}
 if pFile^.LockType >= locktype then
  begin
   Result:=SQLITE_OK;
   Exit;
  end;
  
 {Do not allow any kind of write-lock on a read-only database}
 if pFile^.AccessMode = GENERIC_READ then
  begin
   Result:=SQLITE_IOERR_LOCK;
   Exit;
  end;
  
 {Make sure the locking sequence is correct}
 //To Do //Support internally, see winLock in sqlite3.c for WinCE implementation
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Lock (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Unlock(id: psqlite3_file; locktype: cint): cint; cdecl;
{Lower the locking level on file descriptor id to locktype.  locktype
 must be either NO_LOCK or SHARED_LOCK
 
 If the locking level of the file descriptor is already at or below
 the requested locking level, this routine is a no-op.

 It is not possible for this routine to fail if the second argument
 is NO_LOCK.  If the second argument is SHARED_LOCK then this routine
 might return SQLITE_IOERR}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Unlock (id=' + IntToHex(PtrUInt(id),8) + ' locktype=' + IntToStr(locktype) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
  
 //To Do //Support internally, see winLock in sqlite3.c for WinCE implementation
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Unlock (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_CheckReservedLock(id: psqlite3_file; pResOut: pcint): cint; cdecl;
{This routine checks if there is a RESERVED lock held on the specified
 file by this or any other process. If such a lock is held, return
 non-zero, otherwise zero}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_CheckReservedLock (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Check pResOut}
 if pResOut = nil then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Check LockType}
 if pFile^.LockType >= RESERVED_LOCK then
  begin
   {Return Result}
   Result:=1;
  end
 else
  begin 
  
   //To Do //Support internally, see winLock in sqlite3.c for WinCE implementation
   
   {Return Result}
   Result:=SQLITE_OK;
  end;
  
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_CheckReservedLock (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;
 
{==============================================================================}

function sqlite3_ultibo_io_FileControl(id: psqlite3_file; op: cint; pArg: pointer): cint; cdecl;
{Control and query of the open file handle}
var
 oldSz:sqlite3_int64;
 newSz:sqlite3_int64;
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_FileControl (id=' + IntToHex(PtrUInt(id),8) + ' op=' + IntToStr(op) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 {Check op}
 case op of
  SQLITE_FCNTL_LOCKSTATE:begin
    pcint(pArg)^:=pFile^.LockType;
    
    Result:=SQLITE_OK;
   end;
  SQLITE_FCNTL_LAST_ERRNO:begin
    pcint(pArg)^:=pFile^.LastErrno;
    
    Result:=SQLITE_OK;
   end;
  SQLITE_FCNTL_CHUNK_SIZE:begin
    pFile^.ChunkSize:=pcint(pArg)^;
    
    Result:=SQLITE_OK;
   end;
  SQLITE_FCNTL_SIZE_HINT:begin
    if pFile^.ChunkSize > 0 then
     begin    
      oldSz:=FSFileSizeEx(pFile^.Handle);
      if oldSz = -1 then
       begin
        Result:=SQLITE_IOERR_FSTAT;
        Exit;
       end;
       
      newSz:=psqlite3_int64(pArg)^;
      if newSz > oldSz then
       begin
        Result:=sqlite3_ultibo_io_Truncate(id,newSz);
        Exit;
       end;
     end;

    Result:=SQLITE_OK;     
   end;
  SQLITE_FCNTL_PERSIST_WAL:begin
    //To Do
   end;
  SQLITE_FCNTL_POWERSAFE_OVERWRITE:begin
    //To Do
   end;
  SQLITE_FCNTL_VFSNAME:begin
    //To Do //sqlite3_mprintf()
   end;
  SQLITE_FCNTL_WIN32_GET_HANDLE:begin
    //To Do
   end;
  SQLITE_FCNTL_WIN32_SET_HANDLE:begin
    //To Do
   end;
  SQLITE_FCNTL_TEMPFILENAME:begin
    //To Do
   end;
 end;
 
 {Return Result}
 Result:=SQLITE_NOTFOUND;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_FileControl (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_SectorSize(id: psqlite3_file): cint; cdecl;
{Return the sector size in bytes of the underlying block device for
 the specified file. This is almost always 512 bytes, but may be
 larger for some devices.

 SQLite code assumes this function cannot fail. It also assumes that
 if two files are created in the same file-system directory (i.e.
 a database and its journal file) that the sector size will be the
 same for both}
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_SectorSize (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Return Result}
 Result:=SQLITE_DEFAULT_SECTOR_SIZE;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_SectorSize (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_DeviceCharacteristics(id: psqlite3_file): cint; cdecl;
{Return a vector of device characteristics}
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_DeviceCharacteristics (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Return Result}
 Result:=SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_DeviceCharacteristics (Result=' + IntToHex(Result,8) + ')');
 {$ENDIF}
end;

{==============================================================================}
{Version 2 or later}
function sqlite3_ultibo_io_ShmMap(id: psqlite3_file; iPg: cint; pgsz: cint;  pp: ppointer): cint; cdecl;
{This function is called to obtain a pointer to region iRegion of the
 shared-memory associated with the database file fd. Shared-memory regions
 are numbered starting from zero. Each shared-memory region is szRegion
 bytes in size.

 If an error occurs, an error code is returned and *pp is set to NULL.

 Otherwise, if the isWrite parameter is 0 and the requested shared-memory
 region has not been allocated (by any client, including one running in a
 separate process), then *pp is set to NULL and SQLITE_OK returned. If
 isWrite is non-zero and the requested shared-memory region has not yet
 been allocated, it is allocated by this function.

 If the shared-memory region has already been allocated or is allocated by
 this call as described above, then it is mapped into this processes
 address space (if it is not already), *pp is set to point to the mapped
 memory and SQLITE_OK returned}
 
{Note: Not supported in Ultibo}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmMap (id=' + IntToHex(PtrUInt(id),8) + ' iPg=' + IntToStr(iPg) + ' pgsz=' + IntToStr(pgsz) + ')');
 {$ENDIF}
 
 {Check pp}
 if pp = nil then Exit;
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 //To Do
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmMap (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_ShmLock(id: psqlite3_file; offset: cint; n: cint; flags: cint): cint; cdecl;
{Change the lock state for a shared-memory segment}
 
{Note: Not supported in Ultibo}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmLock (id=' + IntToHex(PtrUInt(id),8) + ' offset=' + IntToStr(offset) + ' n=' + IntToStr(n) + ' flags=' + IntToHex(flags,8) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 //To Do
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmLock (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

procedure sqlite3_ultibo_io_ShmBarrier(id: psqlite3_file); cdecl;
{Implement a memory barrier or memory fence on shared memory.

 All loads and stores begun before the barrier must complete before
 any load or store begun after the barrier}
begin
 {}
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmBarrier (id=' + IntToHex(PtrUInt(id),8) + ')');
 {$ENDIF}
 
 {Data Memory Barrier}
 DataMemoryBarrier;
end;

{==============================================================================}

function sqlite3_ultibo_io_ShmUnmap(id: psqlite3_file; deleteFlag: cint): cint; cdecl;
{Close a connection to shared-memory.  Delete the underlying
 storage if deleteFlag is true}
 
{Note: Not supported in Ultibo}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmUnmap (id=' + IntToHex(PtrUInt(id),8) + ' deleteFlag=' + IntToStr(deleteFlag) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 //To Do
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_ShmUnmap (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}
{Version 3 or later}
function sqlite3_ultibo_io_Fetch(id: psqlite3_file; iOfst: sqlite3_int64; iAmt: cint; pp: ppointer): cint; cdecl;
{If possible, return a pointer to a mapping of file fd starting at offset
 iOff. The mapping must be valid for at least nAmt bytes.

 If such a pointer can be obtained, store it in *pp and return SQLITE_OK.
 Or, if one cannot but no error occurs, set *pp to 0 and return SQLITE_OK.
 Finally, if an error does occur, return an SQLite error code. The final
 value of *pp is undefined in this case.

 If this function does return a pointer, the caller must eventually
 release the reference by calling sqlite3_ultibo_io_Unfetch()}
 
{Note: Not supported in Ultibo}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Fetch (id=' + IntToHex(PtrUInt(id),8) + ' iOfst=' + IntToStr(iOfst) + ' iAmt=' + IntToStr(iAmt) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 //To Do
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Fetch (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_io_Unfetch(id: psqlite3_file; iOfst: sqlite3_int64; p: pointer): cint; cdecl;
{If the third argument is non-NULL, then this function releases a
 reference obtained by an earlier call to sqlite3_ultibo_io_Fetch(). The second
 argument passed to this function must be the same as the corresponding
 argument that was passed to the sqlite3_ultibo_io_Fetch() invocation.

 Or, if the third argument is NULL, then this function is being called
 to inform the VFS layer that, according to POSIX, any existing mapping
 may now be invalid and should be unmapped}
 
{Note: Not supported in Ultibo}
var
 pFile:psqlite3_ultibo_file;
begin
 {}
 Result:=SQLITE_ERROR;
 
 {Check id}
 if id = nil then Exit;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Unfetch (id=' + IntToHex(PtrUInt(id),8) + ' iOfst=' + IntToStr(iOfst) + ')');
 {$ENDIF}
 
 {Get pFile}
 pFile:=psqlite3_ultibo_file(id);
 
 //To Do
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_io_Unfetch (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;
     
{==============================================================================}
{==============================================================================}
{SQLite Initialization functions}
procedure sqlite3_ultibo_init;
begin
 {}
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_init');
 {$ENDIF}

 {Check Initialized}
 if sqlite3_ultibo_initialized then Exit;
 
 {Configure Memory Allocation methods}
 sqlite3_ultibo_mem_methods.xMalloc:=@sqlite3_ultibo_mem_malloc;
 sqlite3_ultibo_mem_methods.xFree:=@sqlite3_ultibo_mem_free;
 sqlite3_ultibo_mem_methods.xRealloc:=@sqlite3_ultibo_mem_realloc;
 sqlite3_ultibo_mem_methods.xSize:=@sqlite3_ultibo_mem_size;
 sqlite3_ultibo_mem_methods.xRoundup:=@sqlite3_ultibo_mem_roundup;
 sqlite3_ultibo_mem_methods.xInit:=@sqlite3_ultibo_mem_init;
 sqlite3_ultibo_mem_methods.xShutdown:=@sqlite3_ultibo_mem_shutdown;
 sqlite3_ultibo_mem_methods.pAppData:=nil;
 sqlite3_config(SQLITE_CONFIG_MALLOC,@sqlite3_ultibo_mem_methods);
 
 {Configure Mutex methods}
 sqlite3_ultibo_mutex_methods.xMutexInit:=@sqlite3_ultibo_mutex_init;
 sqlite3_ultibo_mutex_methods.xMutexEnd:=@sqlite3_ultibo_mutex_end;
 sqlite3_ultibo_mutex_methods.xMutexAlloc:=@sqlite3_ultibo_mutex_alloc;
 sqlite3_ultibo_mutex_methods.xMutexFree:=@sqlite3_ultibo_mutex_free;
 sqlite3_ultibo_mutex_methods.xMutexEnter:=@sqlite3_ultibo_mutex_enter;
 sqlite3_ultibo_mutex_methods.xMutexTry:=@sqlite3_ultibo_mutex_try;
 sqlite3_ultibo_mutex_methods.xMutexLeave:=@sqlite3_ultibo_mutex_leave;
 sqlite3_ultibo_mutex_methods.xMutexHeld:=@sqlite3_ultibo_mutex_held;
 sqlite3_ultibo_mutex_methods.xMutexNotheld:=@sqlite3_ultibo_mutex_notheld;
 sqlite3_config(SQLITE_CONFIG_MUTEX,@sqlite3_ultibo_mutex_methods);
 
 sqlite3_ultibo_initialized:=True;
end;

{==============================================================================}
{==============================================================================}
{SQLite OS functions}
function sqlite3_ultibo_os_init: cint; cdecl; public name 'sqlite3_os_init';
{Ultibo implementation of sqlite3_os_init function}
begin
 {}
 Result:=SQLITE_ERROR;

 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_os_init');
 {$ENDIF}
 
 {Check Initialized}
 if not sqlite3_ultibo_os_initialized then
  begin
   {Configure VFS Methods}
   {Version 1 methods}
   sqlite3_ultibo_vfs.iVersion:=2; {Support version 2 only}
   sqlite3_ultibo_vfs.szOsFile:=SizeOf(sqlite3_ultibo_file);
   sqlite3_ultibo_vfs.mxPathname:=MAX_PATH;
   sqlite3_ultibo_vfs.pNext:=nil;   
   sqlite3_ultibo_vfs.zName:='ultibo';
   sqlite3_ultibo_vfs.pAppData:=nil;
   sqlite3_ultibo_vfs.xOpen:=@sqlite3_ultibo_vfs_Open;
   sqlite3_ultibo_vfs.xDelete:=@sqlite3_ultibo_vfs_Delete;
   sqlite3_ultibo_vfs.xAccess:=@sqlite3_ultibo_vfs_Access;
   sqlite3_ultibo_vfs.xFullPathname:=@sqlite3_ultibo_vfs_FullPathname;
   sqlite3_ultibo_vfs.xDlOpen:=nil;  
   sqlite3_ultibo_vfs.xDlError:=nil;
   sqlite3_ultibo_vfs.xDlSym:=nil;  
   sqlite3_ultibo_vfs.xDlClose:=nil;
   sqlite3_ultibo_vfs.xRandomness:=@sqlite3_ultibo_vfs_Randomness;
   sqlite3_ultibo_vfs.xSleep:=@sqlite3_ultibo_vfs_Sleep;
   sqlite3_ultibo_vfs.xCurrentTime:=@sqlite3_ultibo_vfs_CurrentTime;
   sqlite3_ultibo_vfs.xGetLastError:=@sqlite3_ultibo_vfs_GetLastError;
   {Version 2 or later methods}
   sqlite3_ultibo_vfs.xCurrentTimeInt64:=@sqlite3_ultibo_vfs_CurrentTimeInt64;
   {Version 3 or later methods}
   sqlite3_ultibo_vfs.xSetSystemCall:=nil; 
   sqlite3_ultibo_vfs.xGetSystemCall:=nil; 
   sqlite3_ultibo_vfs.xNextSystemCall:=nil;
   
   {Register VFS Methods (Default)}
   sqlite3_vfs_register(@sqlite3_ultibo_vfs,1);
   
   {Configure IO Methods}
   sqlite3_ultibo_io_methods.iVersion:=1; {Support version 1 only}
   sqlite3_ultibo_io_methods.xClose:=@sqlite3_ultibo_io_Close; 
   sqlite3_ultibo_io_methods.xRead:=@sqlite3_ultibo_io_Read;    
   sqlite3_ultibo_io_methods.xWrite:=@sqlite3_ultibo_io_Write;   
   sqlite3_ultibo_io_methods.xTruncate:=@sqlite3_ultibo_io_Truncate; 
   sqlite3_ultibo_io_methods.xSync:=@sqlite3_ultibo_io_Sync;     
   sqlite3_ultibo_io_methods.xFileSize:=@sqlite3_ultibo_io_FileSize;  
   sqlite3_ultibo_io_methods.xLock:=@sqlite3_ultibo_io_Lock;    
   sqlite3_ultibo_io_methods.xUnlock:=@sqlite3_ultibo_io_Unlock;   
   sqlite3_ultibo_io_methods.xCheckReservedLock:=@sqlite3_ultibo_io_CheckReservedLock; 
   sqlite3_ultibo_io_methods.xFileControl:=@sqlite3_ultibo_io_FileControl;  
   sqlite3_ultibo_io_methods.xSectorSize:=@sqlite3_ultibo_io_SectorSize;   
   sqlite3_ultibo_io_methods.xDeviceCharacteristics:=@sqlite3_ultibo_io_DeviceCharacteristics; 
   {Version 2 or later methods}
   sqlite3_ultibo_io_methods.xShmMap:=@sqlite3_ultibo_io_ShmMap;   
   sqlite3_ultibo_io_methods.xShmLock:=@sqlite3_ultibo_io_ShmLock;   
   sqlite3_ultibo_io_methods.xShmBarrier:=@sqlite3_ultibo_io_ShmBarrier; 
   sqlite3_ultibo_io_methods.xShmUnmap:=@sqlite3_ultibo_io_ShmUnmap; 
   {Version 3 or later methods}
   sqlite3_ultibo_io_methods.xFetch:=@sqlite3_ultibo_io_Fetch;   
   sqlite3_ultibo_io_methods.xUnfetch:=@sqlite3_ultibo_io_Unfetch;  
   
   sqlite3_ultibo_os_initialized:=True;
  end; 
  
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_os_init (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}

function sqlite3_ultibo_os_end: cint; cdecl; public name 'sqlite3_os_end';
{Ultibo implementation of sqlite3_os_end function}
begin
 {}
 Result:=SQLITE_ERROR;

 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_os_end');
 {$ENDIF}
 
 {Check Initialized}
 if sqlite3_ultibo_os_initialized then
  begin
   {Deregister VFS Methods}
   sqlite3_vfs_unregister(@sqlite3_ultibo_vfs);
 
   sqlite3_ultibo_os_initialized:=False;
  end; 
 
 {Return Result}
 Result:=SQLITE_OK;
 
 {$IFDEF SQLITE3_DEBUG}
 if PLATFORM_LOG_ENABLED then PlatformLogDebug('sqlite3_ultibo_os_end (Result=' + IntToStr(Result) + ')');
 {$ENDIF}
end;

{==============================================================================}
{==============================================================================}
