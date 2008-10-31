ifeq ($(ARCH),powerpc)

#############################################################
#
# yaboot
#
#############################################################
#YABOOT_SOURCE:=yaboot-1.3.13.tar.gz
#YABOOT_SITE:=http://penguinppc.org/bootloaders/yaboot
YABOOT_VERSION:=1.3.14
YABOOT_SOURCE:=yaboot-$(YABOOT_VERSION).tar.gz
YABOOT_SITE:=http://yaboot.ozlabs.org/releases
YABOOT_DIR:=$(BUILD_DIR)/yaboot-$(YABOOT_VERSION)

$(DL_DIR)/$(YABOOT_SOURCE):
	 $(WGET) -P $(DL_DIR) $(YABOOT_SITE)/$(YABOOT_SOURCE)

$(YABOOT_DIR)/.unpacked: $(DL_DIR)/$(YABOOT_SOURCE)
	$(ZCAT) $(DL_DIR)/$(YABOOT_SOURCE) | tar -C $(BUILD_DIR) -xf -
	(cd $(@D) && test -f man.patch && patch -p0 < man.patch)
	touch $@

$(YABOOT_DIR)/.configured: $(YABOOT_DIR)/.unpacked $(wildcard $(BR2_DEPENDS_DIR)/br2/yaboot/have/*.h)$(wildcard $(BR2_DEPENDS_DIR)/br2/yaboot/fs/*.h)
	(echo 'CONFIG_COLOR_TEXT  :=$(BR2_YABOOT_HAVE_COLORTEXT)'; \
	 echo 'CONFIG_SET_COLORMAP:=$(BR2_YABOOT_HAVE_COLORMAP)'; \
	 echo 'USE_MD5_PASSWORDS  :=$(BR2_YABOOT_HAVE_MD5)'; \
	 echo 'CONFIG_FS_XFS      :=$(BR2_YABOOT_FS_XFS)'; \
	 echo 'CONFIG_FS_REISERFS :=$(BR2_YABOOT_FS_REISERFS)'; \
	) > $(YABOOT_DIR)/Config
	touch $@

YABOOT_DIRS=\
		PREFIX=usr \
		MANDIR=share \
		ROOT="$(TARGET_DIR)"

$(YABOOT_DIR)/second/yaboot: $(YABOOT_DIR)/.configured e2fsprogs-libs
	$(MAKE) -C $(YABOOT_DIR) CROSS=$(TARGET_CROSS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LD="$(TARGET_LD) $(TARGET_LD_FLAGS) $(TARGET_LDFLAGS)" \
		HOSTCC="$(HOSTCC)" HOSTCFLAGS="$(HOST_CFLAGS)" \
		$(YABOOT_DIRS)
	touch -c $(YABOOT_DIR)/second/yaboot

yaboot: $(YABOOT_DIR)/second/yaboot

yaboot-source: $(DL_DIR)/$(YABOOT_SOURCE)

yaboot-clean:
	$(MAKE) -C $(YABOOT_DIR) $(YABOOT_DIRS) uninstall
	$(MAKE) -C $(YABOOT_DIR) clean

yaboot-dirclean:
	rm -rf $(YABOOT_DIR)

endif

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_TARGET_YABOOT),y)
TARGETS+=yaboot
endif

