#############################################################
#
# full kernel tarballs >= 2.6.19.1
#
#############################################################

ifeq ($(LINUX_HEADERS_VERSION),)
LINUX_HEADERS_VERSION:=$(KERNEL_MAJORVERSION).$(KERNEL_PATCHLEVEL)$(if $(KERNEL_SUBLEVEL),.$(KERNEL_SUBLEVEL))$(KERNEL_EXTRAVERSION)
LINUX_HEADERS_SITE:=$(BR2_KERNEL_MIRROR)/linux/kernel/v2.6
LINUX_HEADERS_SOURCE:=linux-$(LINUX_HEADERS_VERSION).tar.bz2
LINUX_HEADERS_CAT:=$(BZCAT)
LINUX_HEADERS_UNPACK_DIR:=$(TOOL_BUILD_DIR)/linux-$(LINUX_HEADERS_VERSION)
LINUX_HEADERS_DIR:=$(TOOL_BUILD_DIR)/linux
LINUX_HEADERS_IS_KERNEL=y
endif

ifeq ("$(DEFAULT_KERNEL_HEADERS)","2.6.22.1")
LINUX_RT_VERSION:=rt9
endif

ifeq ("$(DEFAULT_KERNEL_HEADERS)","2.6.21.5")
LINUX_RT_VERSION:=rt20
endif

ifeq ($(LINUX_HEADERS_IS_KERNEL),y)
# Need to redefine KERNEL_HEADERS_PATCH_DIR if you want
# board specific kernel headers
KERNEL_HEADERS_PATCH_DIR:=toolchain/kernel-headers/empty
LINUX_HEADERS_DEPENDS:=

ifeq ($(BR2_KERNEL_HEADERS_RT),y)
LINUX_RT_SOURCE:=patch-$(LINUX_HEADERS_VERSION)-$(LINUX_RT_VERSION)
LINUX_RT_SITE:=$(BR2_KERNEL_MIRROR)/linux/kernel/projects/rt/older/
LINUX_HEADERS_DEPENDS+=$(DL_DIR)/$(LINUX_RT_SOURCE)
$(DL_DIR)/$(LINUX_RT_SOURCE):
	$(WGET) -P $(DL_DIR) $(LINUX_RT_SITE)/$(LINUX_RT_SOURCE)
endif

$(LINUX_HEADERS_UNPACK_DIR)/.unpacked: $(DL_DIR)/$(LINUX_HEADERS_SOURCE)  
	@echo "*** Using kernel-headers generated from kernel source"
	rm -rf $(LINUX_HEADERS_DIR)
	[ -d $(TOOL_BUILD_DIR) ] || $(INSTALL) -d $(TOOL_BUILD_DIR)
	$(LINUX_HEADERS_CAT) $(DL_DIR)/$(LINUX_HEADERS_SOURCE) | tar -C $(TOOL_BUILD_DIR) $(TAR_OPTIONS) -
ifeq ($(BR2_USE_UPDATES),y)
	if [ -d $(LINUX_HEADERS_UNPACK_DIR)/.git ] ; then \
		$(GIT) pull ; \
	fi
endif
	touch $@

$(LINUX_HEADERS_UNPACK_DIR)/.patched: $(LINUX_HEADERS_UNPACK_DIR)/.unpacked $(LINUX_HEADERS_DEPENDS)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) toolchain/kernel-headers \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
ifeq ($(BR2_KERNEL_HEADERS_IPMI),y)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) toolchain/kernel-headers/ipmi \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
endif
ifeq ($(BR2_KERNEL_HEADERS_LZMA),y)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) toolchain/kernel-headers/lzma \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
endif
ifeq ($(BR2_KERNEL_HEADERS_RT),y)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) $(DL_DIR) $(LINUX_RT_SOURCE)
endif
ifeq ($(BR2_KERNEL_HEADERS_PATCH_DIR),y)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) $(KERNEL_HEADERS_PATCH_DIR) \
		\*.patch{,.gz,.bz2}
endif
ifeq ($(BR2_PACKAGE_OPENSWAN),y)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) package/openswan \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
endif
	touch $@

$(LINUX_HEADERS_DIR)/.configured: $(LINUX_HEADERS_UNPACK_DIR)/.patched
	$(INSTALL) -D $(LINUX26_KCONFIG) $(LINUX_HEADERS_DIR)/.config
	# some arches need archprepare
	# FIXME: WTH! archprepare does not honour INSTALL_HDR_PATH
	-(cd $(LINUX_HEADERS_UNPACK_DIR); \
	 $(MAKE) ARCH=$(KERNEL_ARCH) \
	 	HOSTCC="$(HOSTCC)" HOSTCFLAGS="$(HOSTCFLAGS)" \
		HOSTCXX="$(HOSTCXX)" \
		KCONFIG_CONFIG="$(LINUX_HEADERS_DIR)/.config" \
		INSTALL_HDR_PATH=$(LINUX_HEADERS_DIR) archprepare; \
	)
	rm -f $(LINUX_HEADERS_DIR)/.config $(LINUX_HEADERS_DIR)/.oldconfig
	(cd $(LINUX_HEADERS_UNPACK_DIR); \
	 $(MAKE) ARCH=$(KERNEL_ARCH) \
	 	HOSTCC="$(HOSTCC)" HOSTCFLAGS="$(HOSTCFLAGS)" \
		HOSTCXX="$(HOSTCXX)" \
		INSTALL_HDR_PATH=$(LINUX_HEADERS_DIR) headers_install; \
	)
	touch $@

endif
