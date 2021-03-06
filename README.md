A FreeRTOS distribution for ARM microcontrollers
================================================

	Hugo Vincent <hugo.vincent@gmail.com>, 8 March 2011.

This is a real-time operating system for very small devices built around an ARM
microcontroller (with typically at least 16 kB of RAM and 64 kB of flash).

A core aim of this project is to provide a ready-to-use _distribution_ of FreeRTOS, 
in the sense that Linux distributions are much more than just the kernel. As such,
we include a clean, consistent build system, a fully functional standard C library
with well defined, portable ways of doing hardware abstraction, peripheral access,
filesystem access, and so on.

FEATURES:
---------

* Support for the ARM Cortex M3 and ARM7TDMI; currently the NXP LPC1768 and
  LPC2368 ports are working.
* Hard-realtime preemptive multitasking kernel (FreeRTOS v6.1.0).
* Supports protected memory on Cortex M3s that have an MPU (memory protection
  unit -- included in the LPC17xx series). Tasks that access memory they do no
  have permission to access are cleanly terminated and debug information is 
  printed to the console.
* Provides exception handlers. Bugs in application code that generate an ARM hardware
  exception or fault (attempt to access non-existent memory, undefined instruction
  etc) are trapped and debug output is shown. Shows a stack backtrace and processor
  state information. In addition, the kernel attempts to recover from such faults
  by cleanly terminating the responsible task. Similarly for tasks that overflow their
  application stack.
* Complete C library support (including `malloc`, standard file IO etc).
* C++ support, including lightweight STL (www.uSTL.sf.net), and exception handling.
* Ethernet networking with the lightweight uIP TCP/IP stack, including a web server.
* Support for power management (processor is aggressively idled when possible, 
  _coming soon:_ dynamic frequency scaling).
* Well integrated GNU toolchain and build system. 
* Build system lists total flash and RAM, and provides an estimate for
  available heap space for dynamically allocated (malloc'd) memory.
* A UNIX-like filesystem hierarchy. Devices can be accessed via their `/dev/`
  nodes. Filesystems (depending on target hardware) can be added to the root
  filesystem hierarchy, for example `/flash` or `/sd_card`.
  	* A read-only filesystem resident in on-chip flash is supported on all targets.
	* mbed (mbed.org) target supports semihosted local filesystem, accessible via
	  the mbed USB interface. Should also work with semihosting-compatible debuggers.
	* Read/write FAT filesystem on SD/microSD cards _(coming soon)_.
* One UART is used as the console, which is used for operating system messages,
  debug output, and standard IO (`printf` et. al.).
* POSIX APIs for threads, timers, sockets etc. _(coming soon)_. We're aiming
  for full POSIX 1003.13 Profile 52 support eventually.
* Device drivers for many on-chip and common off-chip peripherals.
* Aims not to drown in excessive configuration options.

INSTALATION:
------------

1. Download and install a compatible arm-none-eabi GNU toolchain, such as the
   toolchain at http://github.com/hugovincent/arm-eabi-toolchain.
2. Edit the configuration options at the top of the Makefile.
3. Run `make`.
4. Program the generated binary image to your hardware. The Makefile provides
   a `make install` target to install to suppoted boards.

USE:
----

To be written.

NOTES:
------

Tested with the Codesourcery 2010q1-188 arm-non-eabi toolchain, built from
source with http://github.com/hugovincent/arm-eabi-toolchain (on Mac OS X 10.6).
You will probably have problems with an official Codesourcery toolchain as a
number of compiler and C library options had to be changed to suit this project.
It is strongly recommended to use this customized toolchain. 

This has currently only been tested with mbed (www.mbed.org) hardware, some
versions of which use the NXP LPC2368, and some the LPC1768.

BOOT PROCESS:
-------------

This is a summary of roughly how early-boot through to OS running works. This example
is for Cortex-M3 - other ARM devices have a slightly different process at the start
(the C stack and other C runtime stuff is done in assembler code instead).

	<Reset>
	Hardware set's up a basic C stack with predefined stack pointer. Hardware jumps
	to Reset_Handler - these addresses are defined in the .vectors section.
	[Reset_Handler] 
		- this code does what is traditionally called crt0 (C run time). 
		- can't assume all C features are working
		- initialises C features like data (pre-initialized variables) and bss
		  (zero-initialized variables)
		- copy initial vector table from Flash to RAM and atomically perform relocation
		  of it
		- set up any faults and so forth (generally a good idea to attempt
		  to handle faults than to just ignore them, which will trigger reset)
		- optionally initialise a different stack (the "process stack")
		- pass control to Boot_Init()
		[Boot_Init]
			- call System_Init()
			[System_Init]
				- set up clocks and PLLs if applicable
				- enable clocks and if applicable switch core clock source (normally
				  to something faster)
				- enable power/clocks to core peripherals
				- if applicable, set up memory management/remapping/acceleration etc
			- call Board_EarlyInit()
			[Board_EarlyInit]
				- set NVIC vectors for low-level interrupts (supervisor call, system
				  timer tick (part of the Cortex M3 complex, not a SoC level timer), etc
				- if used, set up any debug communications channels, and
				- set up minimal pin multiplexing etc and peripheral settings so that
				  the debug UART works (the early/late dichotomy is so that debugging
				  or error messages during the late init/boot process can be seen, and
				  that certain boot operations can assume the presence and functionality
				  of certain OS functionality)
				- set any "unsafe" GPIOs to a safe value (things that might be left
				  floating at boot, but need to be in a defined state for safe operation
				- initialise the watch dog timer (optional)
			- call Console_EarlyInit()
			[Console_EarlyInit]
				- set up buffers etc so that printf or other IO machinery works as
				  intended. This might be done in a safe-but-slow manner
			- do any other C/C++ initialisation required (e.g. call C++ constructors)
			- call OS_Init()
			[OS_Init]
				- initialise core OS data structures like the task lists or the
				  device manager
				- these structures allow operating system functionality to be used from
				  here down (e.g. buffered, device-oriented stream IO; atexit();
				  POSIX-like signals etc.)
			- call Console_LateInit()
			[Console_LateInit]
				- re-initialise IO machinery to work in an efficient and thread-safe
				  manner
			- call Board_LateInit()
			[Board_LateInit]
				- initialise other IO/peripherals e.g EEPROM/flash where configuration
				  data might be stored, real-time clock/timer, other ("safe") GPIO etc
			- call main()
			[main]
				- initialise application-level data structures/objects
				- start application threads
				- call OS function to start the scheduler (this function does not return)
			- if main() ever returns, teardown or disable any "unsafe" things,
			  then power down while we wait for the Watch dog timer to reset us.

COPYING:
--------

Portions copyright Richard Barry, Real Time Engineers Ltd:

    FreeRTOS V6.1.0 - Copyright (C) 2010 Real Time Engineers Ltd.

    FreeRTOS is free software; you can redistribute it and/or modify it under
    the terms of the GNU General Public License (version 3) as published by the
    Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

Portions copyright Hugo Vincent:

	Copyright (C) 2010 Hugo Vincent <hugo.vincent@gmail.com>

	This program is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License (version 3) as published by
	the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

The FreeRTOS source code is licensed by the modified GNU General Public
License (GPL) text provided below.

This is a list of files for which Real Time Engineers Ltd or Hugo Vincent are
not the copyright owner and are NOT COVERED BY THE GPL.

1. Various header files provided by silicon manufacturers and tool vendors
   that define processor specific memory addresses and utility macros.
   Permission has been granted by the various copyright holders for these
   files to be included in the FreeRTOS download.  Users must ensure license
   conditions are adhered to for any use other than compilation of the
   FreeRTOS demo applications.

2. The uIP TCP/IP stack the copyright of which is held by Adam Dunkels.
   Users must ensure the open source license conditions stated at the top
   of each uIP source file is understood and adhered to.

3. Miscellaneous drivers, e.g. for Digi Xbee radios, SD cards etc. License
   text is in those files.


The GPL license text follows:


				GNU GENERAL PUBLIC LICENSE
				   Version 2, June 1991

	 Copyright (C) 1989, 1991 Free Software Foundation, Inc.
						   59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
	 Everyone is permitted to copy and distribute verbatim copies
	 of this license document, but changing it is not allowed.

					Preamble

	  The licenses for most software are designed to take away your
	freedom to share and change it.  By contrast, the GNU General Public
	License is intended to guarantee your freedom to share and change free
	software--to make sure the software is free for all its users.  This
	General Public License applies to most of the Free Software
	Foundation's software and to any other program whose authors commit to
	using it.  (Some other Free Software Foundation software is covered by
	the GNU Library General Public License instead.)  You can apply it to
	your programs, too.

	  When we speak of free software, we are referring to freedom, not
	price.  Our General Public Licenses are designed to make sure that you
	have the freedom to distribute copies of free software (and charge for
	this service if you wish), that you receive source code or can get it
	if you want it, that you can change the software or use pieces of it
	in new free programs; and that you know you can do these things.

	  To protect your rights, we need to make restrictions that forbid
	anyone to deny you these rights or to ask you to surrender the rights.
	These restrictions translate to certain responsibilities for you if you
	distribute copies of the software, or if you modify it.

	  For example, if you distribute copies of such a program, whether
	gratis or for a fee, you must give the recipients all the rights that
	you have.  You must make sure that they, too, receive or can get the
	source code.  And you must show them these terms so they know their
	rights.

	  We protect your rights with two steps: (1) copyright the software, and
	(2) offer you this license which gives you legal permission to copy,
	distribute and/or modify the software.

	  Also, for each author's protection and ours, we want to make certain
	that everyone understands that there is no warranty for this free
	software.  If the software is modified by someone else and passed on, we
	want its recipients to know that what they have is not the original, so
	that any problems introduced by others will not reflect on the original
	authors' reputations.

	  Finally, any free program is threatened constantly by software
	patents.  We wish to avoid the danger that redistributors of a free
	program will individually obtain patent licenses, in effect making the
	program proprietary.  To prevent this, we have made it clear that any
	patent must be licensed for everyone's free use or not licensed at all.

	  The precise terms and conditions for copying, distribution and
	modification follow.

				GNU GENERAL PUBLIC LICENSE
	   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

	  0. This License applies to any program or other work which contains
	a notice placed by the copyright holder saying it may be distributed
	under the terms of this General Public License.  The "Program", below,
	refers to any such program or work, and a "work based on the Program"
	means either the Program or any derivative work under copyright law:
	that is to say, a work containing the Program or a portion of it,
	either verbatim or with modifications and/or translated into another
	language.  (Hereinafter, translation is included without limitation in
	the term "modification".)  Each licensee is addressed as "you".

	Activities other than copying, distribution and modification are not
	covered by this License; they are outside its scope.  The act of
	running the Program is not restricted, and the output from the Program
	is covered only if its contents constitute a work based on the
	Program (independent of having been made by running the Program).
	Whether that is true depends on what the Program does.

	  1. You may copy and distribute verbatim copies of the Program's
	source code as you receive it, in any medium, provided that you
	conspicuously and appropriately publish on each copy an appropriate
	copyright notice and disclaimer of warranty; keep intact all the
	notices that refer to this License and to the absence of any warranty;
	and give any other recipients of the Program a copy of this License
	along with the Program.

	You may charge a fee for the physical act of transferring a copy, and
	you may at your option offer warranty protection in exchange for a fee.

	  2. You may modify your copy or copies of the Program or any portion
	of it, thus forming a work based on the Program, and copy and
	distribute such modifications or work under the terms of Section 1
	above, provided that you also meet all of these conditions:

		a) You must cause the modified files to carry prominent notices
		stating that you changed the files and the date of any change.

		b) You must cause any work that you distribute or publish, that in
		whole or in part contains or is derived from the Program or any
		part thereof, to be licensed as a whole at no charge to all third
		parties under the terms of this License.

		c) If the modified program normally reads commands interactively
		when run, you must cause it, when started running for such
		interactive use in the most ordinary way, to print or display an
		announcement including an appropriate copyright notice and a
		notice that there is no warranty (or else, saying that you provide
		a warranty) and that users may redistribute the program under
		these conditions, and telling the user how to view a copy of this
		License.  (Exception: if the Program itself is interactive but
		does not normally print such an announcement, your work based on
		the Program is not required to print an announcement.)

	These requirements apply to the modified work as a whole.  If
	identifiable sections of that work are not derived from the Program,
	and can be reasonably considered independent and separate works in
	themselves, then this License, and its terms, do not apply to those
	sections when you distribute them as separate works.  But when you
	distribute the same sections as part of a whole which is a work based
	on the Program, the distribution of the whole must be on the terms of
	this License, whose permissions for other licensees extend to the
	entire whole, and thus to each and every part regardless of who wrote it.

	Thus, it is not the intent of this section to claim rights or contest
	your rights to work written entirely by you; rather, the intent is to
	exercise the right to control the distribution of derivative or
	collective works based on the Program.

	In addition, mere aggregation of another work not based on the Program
	with the Program (or with a work based on the Program) on a volume of
	a storage or distribution medium does not bring the other work under
	the scope of this License.

	  3. You may copy and distribute the Program (or a work based on it,
	under Section 2) in object code or executable form under the terms of
	Sections 1 and 2 above provided that you also do one of the following:

		a) Accompany it with the complete corresponding machine-readable
		source code, which must be distributed under the terms of Sections
		1 and 2 above on a medium customarily used for software interchange; or,

		b) Accompany it with a written offer, valid for at least three
		years, to give any third party, for a charge no more than your
		cost of physically performing source distribution, a complete
		machine-readable copy of the corresponding source code, to be
		distributed under the terms of Sections 1 and 2 above on a medium
		customarily used for software interchange; or,

		c) Accompany it with the information you received as to the offer
		to distribute corresponding source code.  (This alternative is
		allowed only for noncommercial distribution and only if you
		received the program in object code or executable form with such
		an offer, in accord with Subsection b above.)

	The source code for a work means the preferred form of the work for
	making modifications to it.  For an executable work, complete source
	code means all the source code for all modules it contains, plus any
	associated interface definition files, plus the scripts used to
	control compilation and installation of the executable.  However, as a
	special exception, the source code distributed need not include
	anything that is normally distributed (in either source or binary
	form) with the major components (compiler, kernel, and so on) of the
	operating system on which the executable runs, unless that component
	itself accompanies the executable.

	If distribution of executable or object code is made by offering
	access to copy from a designated place, then offering equivalent
	access to copy the source code from the same place counts as
	distribution of the source code, even though third parties are not
	compelled to copy the source along with the object code.

	  4. You may not copy, modify, sublicense, or distribute the Program
	except as expressly provided under this License.  Any attempt
	otherwise to copy, modify, sublicense or distribute the Program is
	void, and will automatically terminate your rights under this License.
	However, parties who have received copies, or rights, from you under
	this License will not have their licenses terminated so long as such
	parties remain in full compliance.

	  5. You are not required to accept this License, since you have not
	signed it.  However, nothing else grants you permission to modify or
	distribute the Program or its derivative works.  These actions are
	prohibited by law if you do not accept this License.  Therefore, by
	modifying or distributing the Program (or any work based on the
	Program), you indicate your acceptance of this License to do so, and
	all its terms and conditions for copying, distributing or modifying
	the Program or works based on it.

	  6. Each time you redistribute the Program (or any work based on the
	Program), the recipient automatically receives a license from the
	original licensor to copy, distribute or modify the Program subject to
	these terms and conditions.  You may not impose any further
	restrictions on the recipients' exercise of the rights granted herein.
	You are not responsible for enforcing compliance by third parties to
	this License.

	  7. If, as a consequence of a court judgment or allegation of patent
	infringement or for any other reason (not limited to patent issues),
	conditions are imposed on you (whether by court order, agreement or
	otherwise) that contradict the conditions of this License, they do not
	excuse you from the conditions of this License.  If you cannot
	distribute so as to satisfy simultaneously your obligations under this
	License and any other pertinent obligations, then as a consequence you
	may not distribute the Program at all.  For example, if a patent
	license would not permit royalty-free redistribution of the Program by
	all those who receive copies directly or indirectly through you, then
	the only way you could satisfy both it and this License would be to
	refrain entirely from distribution of the Program.

	If any portion of this section is held invalid or unenforceable under
	any particular circumstance, the balance of the section is intended to
	apply and the section as a whole is intended to apply in other
	circumstances.

	It is not the purpose of this section to induce you to infringe any
	patents or other property right claims or to contest validity of any
	such claims; this section has the sole purpose of protecting the
	integrity of the free software distribution system, which is
	implemented by public license practices.  Many people have made
	generous contributions to the wide range of software distributed
	through that system in reliance on consistent application of that
	system; it is up to the author/donor to decide if he or she is willing
	to distribute software through any other system and a licensee cannot
	impose that choice.

	This section is intended to make thoroughly clear what is believed to
	be a consequence of the rest of this License.

	  8. If the distribution and/or use of the Program is restricted in
	certain countries either by patents or by copyrighted interfaces, the
	original copyright holder who places the Program under this License
	may add an explicit geographical distribution limitation excluding
	those countries, so that distribution is permitted only in or among
	countries not thus excluded.  In such case, this License incorporates
	the limitation as if written in the body of this License.

	  9. The Free Software Foundation may publish revised and/or new versions
	of the General Public License from time to time.  Such new versions will
	be similar in spirit to the present version, but may differ in detail to
	address new problems or concerns.

	Each version is given a distinguishing version number.  If the Program
	specifies a version number of this License which applies to it and "any
	later version", you have the option of following the terms and conditions
	either of that version or of any later version published by the Free
	Software Foundation.  If the Program does not specify a version number of
	this License, you may choose any version ever published by the Free Software
	Foundation.

	  10. If you wish to incorporate parts of the Program into other free
	programs whose distribution conditions are different, write to the author
	to ask for permission.  For software which is copyrighted by the Free
	Software Foundation, write to the Free Software Foundation; we sometimes
	make exceptions for this.  Our decision will be guided by the two goals
	of preserving the free status of all derivatives of our free software and
	of promoting the sharing and reuse of software generally.

					NO WARRANTY

	  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
	FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
	OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
	PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
	OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
	TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
	PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
	REPAIR OR CORRECTION.

	  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
	WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
	REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
	INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
	OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
	TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
	YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
	PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGES.

				 END OF TERMS AND CONDITIONS

			How to Apply These Terms to Your New Programs

	  If you develop a new program, and you want it to be of the greatest
	possible use to the public, the best way to achieve this is to make it
	free software which everyone can redistribute and change under these terms.

	  To do so, attach the following notices to the program.  It is safest
	to attach them to the start of each source file to most effectively
	convey the exclusion of warranty; and each file should have at least
	the "copyright" line and a pointer to where the full notice is found.

		<one line to give the program's name and a brief idea of what it does.>
		Copyright (C) <year>  <name of author>

		This program is free software; you can redistribute it and/or modify
		it under the terms of the GNU General Public License** as published by
		the Free Software Foundation; either version 2 of the License, or
		(at your option) any later version.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program; if not, write to the Free Software
		Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


	Also add information on how to contact you by electronic and paper mail.

	If the program is interactive, make it output a short notice like this
	when it starts in an interactive mode:

		Gnomovision version 69, Copyright (C) year name of author
		Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
		This is free software, and you are welcome to redistribute it
		under certain conditions; type `show c' for details.

	The hypothetical commands `show w' and `show c' should show the appropriate
	parts of the General Public License.  Of course, the commands you use may
	be called something other than `show w' and `show c'; they could even be
	mouse-clicks or menu items--whatever suits your program.

	You should also get your employer (if you work as a programmer) or your
	school, if any, to sign a "copyright disclaimer" for the program, if
	necessary.  Here is a sample; alter the names:

	  Yoyodyne, Inc., hereby disclaims all copyright interest in the program
	  `Gnomovision' (which makes passes at compilers) written by James Hacker.

	  <signature of Ty Coon>, 1 April 1989
	  Ty Coon, President of Vice

	This General Public License does not permit incorporating your program into
	proprietary programs.  If your program is a subroutine library, you may
	consider it more useful to permit linking proprietary applications with the
	library.  If this is what you want to do, use the GNU Library General
	Public License instead of this License.

GPL Exception
-------------

Any FreeRTOS source code, whether modified or in it's original release form, or whether
in whole or in part, can only be distributed by you under the terms of the GNU General
Public License plus this exception. An independent module is a module which is not
derived from or based on FreeRTOS.

	EXCEPTION TEXT:
	
	Clause 1

	Linking FreeRTOS statically or dynamically with other modules is making a
	combined work based on FreeRTOS. Thus, the terms and conditions of the GNU
	General Public License cover the whole combination.

	As a special exception, the copyright holder of FreeRTOS gives you permission
	to link FreeRTOS with independent modules that communicate with FreeRTOS
	solely through the FreeRTOS API interface, regardless of the license terms
	of these independent modules, and to copy and distribute the resulting
	combined work under terms of your choice, provided that:

	1) every copy of the combined work is accompanied by a written statement that
	   details to the recipient the version of FreeRTOS used and an offer by
	   yourself to provide the FreeRTOS source code (including any modifications
	   you may have made) should the recipient request it.
	2) The combined work is not itself an RTOS, scheduler, kernel or related product.
	3) The independent modules add significant and primary functionality to
	   FreeRTOS and do not merely extend the existing functionality already present
	   in FreeRTOS.
	
	Clause 2
	
	FreeRTOS may not be used for any competitive or comparative purpose, including
	the publication of any form of run time or compile time metric, without the
	express permission of Real Time Engineers Ltd. (this is the norm within the
	industry and is intended to ensure information accuracy).

