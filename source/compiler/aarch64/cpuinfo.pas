{
    Copyright (c) 1998-2002 by the Free Pascal development team

    Basic Processor information for AArch64

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

Unit CPUInfo;

Interface

  uses
    globtype;

Type
   bestreal = double;
{$if FPC_FULLVERSION>20700}
   bestrealrec = TDoubleRec;
{$endif FPC_FULLVERSION>20700}
   ts32real = single;
   ts64real = double;
   ts80real = type extended;
   ts128real = type extended;
   ts64comp = comp;

   pbestreal=^bestreal;

   { possible supported processors for this target }
   tcputype =
      (cpu_none,
       cpu_armv8
      );

Type
   tfputype =
     (fpu_none,
      fpu_vfp
     );

   tcontrollertype =
     (ct_none,
     
      { Raspberry Pi3 (64 bit mode)}
      ct_rpi3a,
      ct_rpi3b,

      { Raspberry Pi4 (64 bit mode)}
      ct_rpi4b,
      ct_rpi400,
      
      { QEMU VersatilePB (64 bit mode)}
      ct_qemuvpb,
      
      { QEMU Raspberry Pi3 (64 bit mode)}
      ct_qemurpi3a,
      ct_qemurpi3b
      
     );

   tcontrollerdatatype = record
      controllertypestr, controllerunitstr: string[20];
      cputype: tcputype; fputype: tfputype;
      flashbase, flashsize, srambase, sramsize, eeprombase, eepromsize, bootbase, bootsize: dword;
   end;


Const
   { Is there support for dealing with multiple microcontrollers available }
   { for this platform? }
   ControllerSupport = true;
   {# Size of native extended floating point type }
   extended_size = 8;
   {# Size of a multimedia register               }
   mmreg_size = 16;
   { target cpu string (used by compiler options) }
   target_cpu_string = 'aarch64';

   { We know that there are fields after sramsize
     but we don't care about this warning }
   {$PUSH}
    {$WARN 3177 OFF}
   embedded_controllers : array [tcontrollertype] of tcontrollerdatatype =
   (
      (controllertypestr:''; controllerunitstr:''; cputype:cpu_none; fputype:fpu_none; flashbase:0; flashsize:0; srambase:0; sramsize:0),
      
      { Raspberry Pi3}
      (controllertypestr:'RPI3A'; controllerunitstr:'BOOTRPI3'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$20000000),
      (controllertypestr:'RPI3B'; controllerunitstr:'BOOTRPI3'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$40000000),

      { Raspberry Pi4}
      (controllertypestr:'RPI4B'; controllerunitstr:'BOOTRPI4'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$40000000),
      (controllertypestr:'RPI400'; controllerunitstr:'BOOTRPI4'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$40000000),

      { QEMU VersatilePB}
      (controllertypestr:'QEMUVPB'; controllerunitstr:'BOOTQEMUVPB'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$10000000),

      { QEMU Raspberry Pi3}
      (controllertypestr:'QEMURPI3A'; controllerunitstr:'BOOTRPI3'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$20000000),
      (controllertypestr:'QEMURPI3B'; controllerunitstr:'BOOTRPI3'; cputype:cpu_armv8; fputype:fpu_vfp; flashbase:$00000000; flashsize:$00000000; srambase:$00080000; sramsize:$40000000)
      
    );
   {$POP}

   { calling conventions supported by the code generator }
   supported_calling_conventions : tproccalloptions = [
     pocall_internproc,
     pocall_safecall,
     pocall_stdcall,
     { same as stdcall only different name mangling }
     pocall_cdecl,
     { same as stdcall only different name mangling }
     pocall_cppdecl,
     { same as stdcall but floating point numbers are handled like equal sized integers }
     pocall_softfloat,
     { same as stdcall (requires that all const records are passed by
       reference, but that's already done for stdcall) }
     pocall_mwpascal,
     { used for interrupt handling }
     pocall_interrupt
   ];

   cputypestr : array[tcputype] of string[8] = ('',
     'ARMV8'
   );

   fputypestr : array[tfputype] of string[9] = ('',
     'VFP'
   );


   { Supported optimizations, only used for information }
   supported_optimizerswitches = genericlevel1optimizerswitches+
                                 genericlevel2optimizerswitches+
                                 genericlevel3optimizerswitches-
                                 { no need to write info about those }
                                 [cs_opt_level1,cs_opt_level2,cs_opt_level3]+
                                 [cs_opt_regvar,cs_opt_loopunroll,cs_opt_tailrecursion,
				  cs_opt_nodecse,cs_opt_reorder_fields,cs_opt_fastmath];

   level1optimizerswitches = genericlevel1optimizerswitches;
   level2optimizerswitches = genericlevel2optimizerswitches + level1optimizerswitches +
     [cs_opt_regvar,cs_opt_stackframe,cs_opt_tailrecursion,cs_opt_nodecse];
   level3optimizerswitches = genericlevel3optimizerswitches + level2optimizerswitches + [{,cs_opt_loopunroll}];
   level4optimizerswitches = genericlevel4optimizerswitches + level3optimizerswitches + [];

Implementation

end.

