#
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2019 Western Digital Corporation or its affiliates.
#

# Compiler pre-processor flags
platform-cppflags-y =

# C Compiler and assembler flags.
platform-cflags-y =
platform-asflags-y =

# Linker flags: additional libraries and object files that the platform
# code needs can be added here
platform-ldflags-y =

#
# Command for platform specific "make run"
# Useful for development and debugging on plaftform simulator (such as QEMU)
#
platform-runcmd = cp build/platform/iob_soc/firmware/*.bin ../../software/OS_build

#
# Platform RISC-V XLEN, ABI, ISA and Code Model configuration.
# These are optional parameters but platforms can optionaly provide it.
# Some of these are guessed based on GCC compiler capabilities
#
PLATFORM_RISCV_XLEN = 32
PLATFORM_RISCV_ABI = ilp32
PLATFORM_RISCV_ISA = rv32imac
# PLATFORM_RISCV_CODE_MODEL = medany

# Firmware load address configuration. This is mandatory.
FW_TEXT_START=0x00000000

# Optional parameter for path to external FDT
# FW_FDT_PATH="path to platform flattened device tree file"

#
# Dynamic firmware configuration.
# Optional parameters are commented out. Uncomment and define these parameters
# as needed.
#
FW_DYNAMIC=n

#
# Jump firmware configuration.
# Optional parameters are commented out. Uncomment and define these parameters
# as needed.
#
FW_JUMP=y
# This needs to be 4MB aligned for 32-bit support
# This needs to be 2MB aligned for 64-bit support
ifeq ($(PLATFORM_RISCV_XLEN), 32)
FW_JUMP_ADDR=0x00400000
else
FW_JUMP_ADDR=0x00200000
endif
FW_JUMP_FDT_ADDR=0x00F80000

#
# Firmware with payload configuration.
# Optional parameters are commented out. Uncomment and define these parameters
# as needed.
#
FW_PAYLOAD=y
# This needs to be 4MB aligned for 32-bit support
# This needs to be 2MB aligned for 64-bit support
ifeq ($(PLATFORM_RISCV_XLEN), 32)
FW_PAYLOAD_OFFSET=0x400000
else
FW_PAYLOAD_OFFSET=0x200000
endif
# FW_PAYLOAD_ALIGN=0x1000
# FW_PAYLOAD_PATH="path to next boot stage binary image file"
FW_PAYLOAD_FDT_ADDR=0x00F80000
