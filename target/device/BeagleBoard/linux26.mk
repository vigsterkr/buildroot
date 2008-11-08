#############################################################
#
# Linux kernel 2.6 target
#
#############################################################
ifneq ($(filter $(TARGETS),linux26),)


# Version of Linux to download and then apply patches to
DOWNLOAD_LINUX26_VERSION=2.6.27
# Version of Linux after applying any patches
LINUX26_VERSION=2.6.27-omap1-dirty
#LINUX_HEADERS_VERSION=$(LINUX26_VERSION)

LINUX26_SOURCE=linux-$(DOWNLOAD_LINUX26_VERSION).tar.bz2
LINUX26_SITE=http://ftp.kernel.org/pub/linux/kernel/v2.6

LINUX26_FORMAT=uImage
LINUX26_BINLOC=$(LINUX26_FORMAT)

# Linux kernel configuration file
LINUX26_KCONFIG=$(BR2_BOARD_PATH)/linux26.beagle.config

# File name for the Linux kernel binary
LINUX26_KERNEL=linux-kernel-$(LINUX26_VERSION)-$(KERNEL_ARCH).srec

# Version of Linux AFTER patches
LINUX26_DIR=$(BUILD_DIR)/linux-$(LINUX26_VERSION)

# kernel patches
LINUX26_PATCH_DIR=target/device/BeagleBoard/kernel-patches/

LINUX26_MAKE_FLAGS = $(TARGET_CONFIGURE_OPTS) ARCH=$(KERNEL_ARCH) \
	PATH=$(TARGET_PATH) INSTALL_MOD_PATH=$(TARGET_DIR) \
	CROSS_COMPILE=$(KERNEL_CROSS)

#$(DL_DIR)/$(LINUX26_SOURCE):
#	 $(WGET) -P $(DL_DIR) $(LINUX26_SITE)/$(LINUX26_SOURCE)

#$(LINUX26_KCONFIG):
#	@if [ ! -f "$(LINUX26_KCONFIG)" ]; then \
		echo ""; \
		echo "You should create a .config for your kernel"; \
		echo "and install it as $(LINUX26_KCONFIG)"; \
		echo ""; \
		sleep 5; \
	fi

endif
