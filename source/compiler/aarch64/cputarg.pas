{
    Copyright (c) 2001-2002 by Peter Vreman

    Includes the AArch64 dependent target units

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
unit cputarg;

{$i fpcdefs.inc}

interface


implementation

    uses
      systems { prevent a syntax error when nothing is included }

{**************************************
             Targets
**************************************}

    {$ifndef NOTARGETLINUX}
      ,t_linux
    {$endif}
    {$ifndef NOTARGETBSD}
      ,t_bsd
    {$endif}
    {$ifndef NOTARGETULTIBO}
      ,t_ultibo
    {$endif}

{**************************************
             Assemblers
**************************************}

    {$ifndef NOAGCPUGAS}
      ,agcpugas
    {$endif}

{**************************************
        Assembler Readers
**************************************}

  {$ifndef NoRaarmgas}
       ,racpugas
  {$endif NoRaarmgas}

{**************************************
             Debuginfo
**************************************}

  {$ifndef NoDbgDwarf}
      ,dbgdwarf
  {$endif NoDbgDwarf}
      ;

end.
