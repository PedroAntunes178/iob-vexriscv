include config.mk

# Rules
.PHONY: vexriscv clean qemu

CPU ?= LinuxGen
#CPU ?= GenFullNoMmuNoCache

# Support targets
os_dir:
	-@mkdir $(VEX_SOFTWARE_DIR)/OS_build

# Primary targets
vexriscv:
	cp $(VEX_SOFTWARE_DIR)/vexriscv_core/* $(VEX_SUBMODULES_DIR)/VexRiscv/src/main/scala/vexriscv/demo/ && \
		cd submodules/VexRiscv && sbt "runMain vexriscv.demo.$(CPU)" && \
		cp VexRiscv.v $(VEXRISCV_SRC_DIR)

build-opensbi: clean-opensbi os_dir
	cp -r $(VEX_SOFTWARE_DIR)/opensbi_platform/* $(VEX_SUBMODULES_DIR)/OpenSBI/platform/ && \
		cd $(VEX_SUBMODULES_DIR)/OpenSBI && $(MAKE) run PLATFORM=iob_soc

build-rootfs: clean-rootfs os_dir
	cd $(VEX_SUBMODULES_DIR)/busybox && \
		cp $(VEX_SOFTWARE_DIR)/rootfs_busybox/busybox_config $(VEX_SUBMODULES_DIR)/busybox/configs/iob_defconfig && \
		$(MAKE) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- iob_defconfig && \
		CROSS_COMPILE=riscv64-unknown-linux-gnu- $(MAKE) -j$(nproc) && \
		CROSS_COMPILE=riscv64-unknown-linux-gnu- $(MAKE) install && \
		cd _install/ && cp $(VEX_SOFTWARE_DIR)/rootfs_busybox/init init && \
		mkdir -p dev && sudo mknod dev/console c 5 1 && sudo mknod dev/ram0 b 1 0 && \
		find -print0 | cpio -0oH newc | gzip -9 > $(VEX_OS_DIR)/rootfs.cpio.gz

build-linux-kernel: clean-linux-kernel os_dir
	cd $(VEX_SUBMODULES_DIR)/Linux && \
		cp $(VEX_SOFTWARE_DIR)/linux_config $(VEX_SUBMODULES_DIR)/Linux/arch/riscv/configs/iob_soc_defconfig && \
		$(MAKE) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- iob_soc_defconfig && \
		$(MAKE) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j2 && \
		cp $(VEX_SUBMODULES_DIR)/Linux/arch/riscv/boot/Image $(VEX_OS_DIR)

build-dts: os_dir
	dtc -O dtb -o $(VEX_OS_DIR)/iob_soc.dtb $(VEX_SOFTWARE_DIR)/iob_soc.dts

build-buildroot: clean-buildroot
	@wget https://buildroot.org/downloads/buildroot-2022.05.2.tar.gz && tar -xvzf buildroot-2022.05.2.tar.gz -C $(VEX_SUBMODULES_DIR) && \
		cd $(VEX_SUBMODULES_DIR)/buildroot-2022.05.2/ && \
		$(MAKE) BR2_EXTERNAL=$(VEX_SOFTWARE_DIR)/buildroot iob_soc_defconfig && $(MAKE) -j2 && \
		cp $(VEX_SUBMODULES_DIR)/buildroot-2022.05.2/output/images/Image $(VEX_OS_DIR)

build-OS: clean-OS build-dts build-opensbi build-rootfs build-linux-kernel

## BuildRoot QEMU to deprecate ##
build-qemu: clean-buildroot
	mkdir qemu_LinuxOS && \
		cd buildroot && $(MAKE) qemu_riscv32_virt_defconfig && $(MAKE) -j2 && \
		cp buildroot/output/images/* qemu_LinuxOS

run-qemu:
	qemu-system-riscv32 -M virt -bios qemu_LinuxOS/fw_jump.elf -kernel qemu_LinuxOS/Image -append "rootwait root=/dev/vda ro" -drive file=qemu_LinuxOS/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 -netdev user,id=net0 -device virtio-net-device,netdev=net0 -nographic



#
# Clean
#
clean-opensbi:
	cd $(VEX_SUBMODULES_DIR)/OpenSBI && $(MAKE) distclean

clean-rootfs:
	cd $(VEX_SUBMODULES_DIR)/busybox && $(MAKE) distclean

clean-linux-kernel:
	cd $(VEX_SUBMODULES_DIR)/Linux && $(MAKE) ARCH=riscv distclean

clean-buildroot:
	-@rm -rf $(VEX_SUBMODULES_DIR)/buildroot-2022.05.2 && \
		rm buildroot-2022.05.2.tar.gz

clean-OS:
	@rm -rf $(VEX_OS_DIR)/*

clean-all: clean-OS
