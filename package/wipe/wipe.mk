#############################################################
#
# wipe
#
#############################################################
WIPE_VERSION:=0.20
WIPE_SOURCE:=wipe-$(WIPE_VERSION).tar.gz
#WIPE_PATCH:=wipe_0.2-19.diff.gz
WIPE_SITE:=http://abaababa.ouvaton.org/wipe
WIPE_CAT:=$(ZCAT)
WIPE_DIR:=$(BUILD_DIR)/wipe-$(WIPE_VERSION)
WIPE_BINARY:=wipe
WIPE_TARGET_BINARY:=bin/wipe

WIPE_CFLAGS:=$(TARGET_CFLAGS)
ifeq ($(BR2_LARGEFILE),y)
WIPE_CFLAGS+=-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
endif

$(DL_DIR)/$(WIPE_SOURCE):
	 $(WGET) -P $(DL_DIR) $(WIPE_SITE)/$(WIPE_SOURCE)

ifneq ($(WIPE_PATCH),)
$(DL_DIR)/$(WIPE_PATCH):
	 $(WGET) -P $(DL_DIR) $(WIPE_SITE)/$(WIPE_PATCH)
endif

$(WIPE_DIR)/.unpacked: $(DL_DIR)/$(WIPE_SOURCE) $(DL_DIR)/$(WIPE_PATCH)
	$(WIPE_CAT) $(DL_DIR)/$(WIPE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	#toolchain/patch-kernel.sh $(WIPE_DIR) $(DL_DIR) $(WIPE_PATCH)
	touch $@

$(WIPE_DIR)/$(WIPE_BINARY): $(WIPE_DIR)/.unpacked
	rm -f $(WIPE_DIR)/$(WIPE_BINARY)
	$(MAKE) CC_GENERIC="$(TARGET_CC) $(WIPE_CFLAGS)" \
		CCO_GENERIC="$(WIPE_FLAGS)" \
		CCOC_GENERIC=-c -C $(WIPE_DIR) generic
	touch -c $@

$(TARGET_DIR)/$(WIPE_TARGET_BINARY): $(WIPE_DIR)/$(WIPE_BINARY)
	$(INSTALL) -D $(WIPE_DIR)/$(WIPE_BINARY) $(TARGET_DIR)/$(WIPE_TARGET_BINARY)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

wipe: uclibc $(TARGET_DIR)/$(WIPE_TARGET_BINARY)

wipe-source: $(DL_DIR)/$(WIPE_SOURCE) $(DL_DIR)/$(WIPE_PATCH)

wipe-clean:
	#$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(WIPE_DIR) uninstall
	-$(MAKE) -C $(WIPE_DIR) clean
	rm -f $(TARGET_DIR)/$(WIPE_TARGET_BINARY)

wipe-dirclean:
	rm -rf $(WIPE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_WIPE),y)
TARGETS+=wipe
endif
