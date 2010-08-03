# For mbed <http://www.mbed.org>
# Hugo Vincent, April 25 2010
#
# Note: after installing an arm-eabi-none* toolchain using the instructions at
# http://github.com/hugovincent/arm-eabi-toolchain, run setup-colorgcc.sh in util/
#
# Targets you can Make:
#	all		- Build all code and produce a binary suitable for installation.
#	install	- Install to an attached mbed device. Set INSTALL_PATH below to suit.
#	clean	- Delete all temporary build products.
#	dep		- Compute interdependecies between source files. Useful if you're
#			  hacking on the source (otherwise you need to make clean && make).
#	disasm	- Produce a disassembly listing of the whole program.
#

# Set CPU type here (can be lpc2368 for older mbeds, or lpc1768 for newer ones):
TARGET=lpc1768

# Set programming method here (can be mbed or serial_isp):
PROG_TYPE=mbed
#ISP_OPT=/dev/tty.usbserial-isp 115200 12000

# Set local options here:
INSTALL_PATH=/Volumes/MBED/
BINNAME=RTOSDemo
TOOLPRE=util/arm-none-eabi

#------------------------------------------------------------------------------
# Stuff specific to LPC2368 target:
ifeq ($(TARGET), lpc2368)
CPUFLAGS= \
		-mcpu=arm7tdmi-s
COMMON_FLAGS= \
		-DTARGET_LPC23xx \
		-DPLAT_NAME="\"LPC2368\"" \
		-Iinclude/LPC2368
PORT_DIR= \
		ARM7_LPC23xx
ASM_SOURCE= \
		mach/cpu-lpc2368/crt0.s
C_SOURCE= \
		mach/cpu-lpc2368/exception_handlers.c
endif

#------------------------------------------------------------------------------
# Stuff specific to LPC1768 target:
ifeq ($(TARGET), lpc1768)
CPUFLAGS= \
		-mcpu=cortex-m3 \
		-mthumb
COMMON_FLAGS= \
		-DTARGET_LPC17xx \
		-DCORE_HAS_MPU \
		-DPLAT_NAME="\"LPC1768\"" \
		-Iinclude/LPC1768
LINKER_FLAGS= \
		-mthumb \
		-mcpu=cortex-m3
PORT_DIR= \
		ARM_CM3_MPU
EXTRA_LDFLAGS= \
		-mcpu=cortex-m3 \
		-mthumb
C_SOURCE= \
		mach/cpu-lpc1768/core_cm3.c \
		mach/cpu-lpc1768/crt0.c \
		mach/cpu-lpc1768/fault_handlers.c \
		lib/mpu_manager.c
endif

#------------------------------------------------------------------------------
# Compiler, Assembler and Linker Options:

DEBUG=-DNDEBUG=1 -g
OPTIM=-O2
LDSCRIPT=mach/cpu-$(TARGET)/$(TARGET).ld
ODIR=.buildtmp

COMMON_FLAGS += \
		$(CPUFLAGS) \
		$(DEBUG) \
		$(OPTIM) \
		-I . \
		-I include \
		-I kernel/include \
		-I kernel/port/$(PORT_DIR) \
		-Wall -Wimplicit -Wpointer-arith -Wcast-align \
		-Wswitch -Wreturn-type -Wshadow -Wunused \
		-fexceptions -fsection-anchors -fomit-frame-pointer \
		-ffunction-sections -fdata-sections \
		-mfloat-abi=soft -mtp=soft -mabi=aapcs

CFLAGS = $(COMMON_FLAGS) \
		-std=gnu99 -Wc++-compat

CXXFLAGS= $(COMMON_FLAGS) \
		-I lib/ustl/public -nostdinc++ \
		-fno-rtti \
		-fno-enforce-eh-specs \
		-fno-use-cxa-get-exception-ptr \
		-fno-stack-protector

LINKER_FLAGS= \
		-T$(LDSCRIPT) $(EXTRA_LDFLAGS) \
		-Wl,--gc-sections -Wl,-O3 \
		-Wl,-Map=$(BINNAME).map \
		-mabi=aapcs -static \
		-nostartfiles -nodefaultlibs \
		-Wl,--start-group -lgcc -lc -lm -lsupc++ -Wl,--end-group

ASM_FLAGS= \
		$(CPUFLAGS) \
		-x assembler-with-cpp

#------------------------------------------------------------------------------
# Source Code:

# Core Operating System
C_SOURCE+= \
		mach/cpu-$(TARGET)/device_init.c \
		mach/board-mbed/board_init.c \
		mach/cpu-$(TARGET)/power_management.c \
		kernel/list.c \
		kernel/queue.c \
		kernel/tasks.c \
		kernel/port/$(PORT_DIR)/port.c \
		kernel/malloc_wrappers.c \
		lib/debug_support.c \
		lib/device_manager.c \
		lib/freertos_hooks.c \
		lib/semifs.c \
		lib/romfs.c \
		lib/console.c \
		lib/os_init.c
CXX_SOURCE+= \
		Main.cpp \

# C/C++ library and operating system calls
C_SOURCE+= \
		lib/syscalls/chmod.c \
		lib/syscalls/close.c \
		lib/syscalls/environ.c \
		lib/syscalls/execve.c \
		lib/syscalls/exit.c \
		lib/syscalls/fstat.c \
		lib/syscalls/fsync.c \
		lib/syscalls/getpid.c \
		lib/syscalls/gettimeofday.c \
		lib/syscalls/isatty.c \
		lib/syscalls/ioctl.c \
		lib/syscalls/kill.c \
		lib/syscalls/link.c \
		lib/syscalls/lseek.c \
		lib/syscalls/mkdir.c \
		lib/syscalls/mkfifo.c \
		lib/syscalls/open.c \
		lib/syscalls/read.c \
		lib/syscalls/reent.c \
		lib/syscalls/rename.c \
		lib/syscalls/sbrk.c \
		lib/syscalls/stat.c \
		lib/syscalls/syscalls_util.c \
		lib/syscalls/system.c \
		lib/syscalls/times.c \
		lib/syscalls/unlink.c \
		lib/syscalls/wait.c \
		lib/syscalls/write.c
CXX_SOURCE+= \
		lib/min_c++.cpp
#include lib/ustl/ustl.mk

# Peripheral device drivers
C_SOURCE+= \
		drivers/uart/uart.c \
		drivers/uart/uart_fractional_baud.c \
		drivers/gpio/gpio.c \
		drivers/emac/emac.c \
		drivers/wdt/wdt.c

# Example Tasks
C_SOURCE+= \
		example_tasks/BlockQ.c \
		example_tasks/blocktim.c \
		example_tasks/flash.c \
		example_tasks/integer.c \
		example_tasks/GenQTest.c \
		example_tasks/QPeek.c \
		example_tasks/dynamic.c

## Webserver Task
#C_SOURCE+= \
#		example_tasks/webserver/uIP_Task.c \
#		example_tasks/webserver/httpd.c \
#		example_tasks/webserver/httpd-cgi.c \
#		example_tasks/webserver/httpd-fs.c \
#		example_tasks/webserver/http-strings.c

## uIP Networking Library
#C_SOURCE+= \
#		lib/uip/uip_arp.c \
#		lib/uip/psock.c \
#		lib/uip/timer.c \
#		lib/uip/uip.c

# Tests
CXX_SOURCE+= \
		tests/Cxx_Test.cpp \
		tests/Malloc_Test.cpp \
		tests/FileIO_Test.cpp \
		tests/Debug_Abort_Test.cpp

#------------------------------------------------------------------------------
# Build Rules:

C_OBJS     = $(patsubst %.c,$(ODIR)/%.o, $(C_SOURCE))
CXX_OBJS   = $(patsubst %.cpp,$(ODIR)/%.o, $(CXX_SOURCE))
ASM_OBJS   = $(patsubst %.s,$(ODIR)/%.o, $(ASM_SOURCE))

OBJS       = $(C_OBJS) $(CXX_OBJS) $(ASM_OBJS)

all: $(BINNAME).bin

# Binary suitable for installation on mbed
$(BINNAME).bin : $(BINNAME).elf
	@echo "  [Converting to binary ] $(BINNAME).bin"
	@$(TOOLPRE)-objcopy $(BINNAME).elf -O binary $(BINNAME).bin
	@python util/memory-usage.py $(TARGET) $(BINNAME).elf
	@echo

# ELF file (intermediate linking product, also used for various checks)
$(BINNAME).elf : $(OBJS)
	@echo "  [Linking...           ] $@"
	@$(TOOLPRE)-gcc $(OBJS) -o $@ $(LINKER_FLAGS)

# C/C++ Code:
$(C_OBJS) : $(ODIR)/%.o : %.c $(ODIR)/exists
	@echo "  [Compiling  (C)  ] $<"
	@$(TOOLPRE)-gcc -c $(CFLAGS) $< -o $@

$(CXX_OBJS) : $(ODIR)/%.o : %.cpp $(ODIR)/exists
	@echo "  [Compiling  (C++)] $<"
	@$(TOOLPRE)-g++ -c $(CXXFLAGS) $< -o $@

# ARM Assembler Code:
$(ASM_OBJS) : $(ODIR)/%.o : %.s $(ODIR)/exists
	@echo "  [Assembling (asm)] $<"
	@$(TOOLPRE)-gcc -c $(ASM_FLAGS) $< -o $@

# This target ensures the temporary build product directories exist
$(ODIR)/exists:
	@mkdir -p $(ODIR)/drivers/uart $(ODIR)/drivers/gpio $(ODIR)/drivers/rtc
	@mkdir -p $(ODIR)/drivers/emac $(ODIR)/drivers/wdt
	@mkdir -p $(ODIR)/mach/board-mbed $(ODIR)/mach/cpu-$(TARGET)
	@mkdir -p $(ODIR)/kernel $(ODIR)/mach/cpu-common $(ODIR)/kernel/port/$(PORT_DIR)
	@mkdir -p $(ODIR)/example_tasks $(ODIR)/example_tasks/webserver $(ODIR)/lib/uip
	@mkdir -p $(ODIR)/lib/ustl $(ODIR)/tests $(ODIR)/lib/syscalls
	@touch $(ODIR)/exists

# UIP script build rules
example_tasks/webserver/http-strings.c: util/uip_makestrings
	@echo "  [Making uIP http-strings ]"
	@pushd example_tasks/webserver > /dev/null && ../../util/uip_makestrings && popd > /dev/null

example_tasks/webserver/httpd-fsdata.c: util/uip_makefsdata example_tasks/webserver/httpd-fs/*.html
	@echo "  [Making uIP httpd-fs ]"
	@pushd example_tasks/webserver > /dev/null && ../../util/uip_makefsdata && popd > /dev/null

example_tasks/webserver/httpd-fs.c: example_tasks/webserver/httpd-fsdata.c
example_tasks/webserver/httpd.c: example_tasks/webserver/http-strings.c

# RomFS script build rules
lib/romfs_data.h: util/build_romfs.py romfs/*
	@echo "  [Packaging RomFS data]"
	@python util/build_romfs.py lib/romfs_data.h romfs/

lib/romfs.c: lib/romfs_data.h

#------------------------------------------------------------------------------
# Psuedo-targets:

.PHONY: disasm clean install
disasm :
	@echo "  [Disassembling binary ] $(BINNAME)-disassembled.s"
	@$(TOOLPRE)-objdump -D $(BINNAME).elf > $(BINNAME)-disassembled.s

clean:
	@echo "  [Cleaning...          ]"
	@rm -rf $(ODIR) $(BINNAME).elf $(BINNAME).bin $(BINNAME)-disassembled.s $(BINNAME).map example_tasks/webserver/http-strings.* example_tasks/webserver/httpd-fsdata.c

install: $(BINNAME).bin
ifeq ($(PROG_TYPE), mbed)
	@echo "  [Installing to mbed...]"
	@cp $(BINNAME).bin $(INSTALL_PATH)
	@echo "  [Done.                ]"
else ifeq ($(PROG_TYPE), serial_isp)
	@echo "  [Installing by ISP... ]"
	@./util/lpc21isp/lpc21isp -wipe -bin $(BINNAME).bin $(ISP_OPT)
	@echo "  [Done.                ]"
endif

#------------------------------------------------------------------------------
# Dependency Management (run make dep to generate, otherwise ignored)

DEPS_C         = $(patsubst %.c,$(ODIR)/%.d, $(C_SOURCE))
DEPS_CXX       = $(patsubst %.cpp,$(ODIR)/%.d, $(CXX_SOURCE))

.PHONY: dep
dep : $(DEPS_C) $(DEPS_CXX)

$(DEPS_C) : $(ODIR)/%.d : %.c $(ODIR)/exists
	@echo "  [Finding dependencies ] $<"
	@$(TOOLPRE)-gcc -MM $(CFLAGS) -MT $(patsubst %.c,$(ODIR)/%.o, $<) $< -MF $@

$(DEPS_CXX) : $(ODIR)/%.d : %.cpp $(ODIR)/exists
	@echo "  [Finding dependencies ] $<"
	@$(TOOLPRE)-g++ -MM $(CXXFLAGS) -MT $(patsubst %.cpp,$(ODIR)/%.o, $<) $< -MF $@

-include $(shell find . -name "*.d")

