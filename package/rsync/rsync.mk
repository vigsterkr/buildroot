#############################################################
#
# rsync
#
#############################################################
RSYNC_VERSION:=2.6.9
RSYNC_SOURCE:=rsync-$(RSYNC_VERSION).tar.gz
RSYNC_SITE:=http://rsync.samba.org/ftp/rsync/
RSYNC_DIR:=$(BUILD_DIR)/rsync-$(RSYNC_VERSION)
RSYNC_CAT:=$(ZCAT)
RSYNC_BINARY:=rsync
RSYNC_TARGET_BINARY:=usr/bin/rsync

$(DL_DIR)/$(RSYNC_SOURCE):
	$(WGET) -P $(DL_DIR) $(RSYNC_SITE)/$(RSYNC_SOURCE)

$(RSYNC_DIR)/.unpacked: $(DL_DIR)/$(RSYNC_SOURCE)
	$(RSYNC_CAT) $(DL_DIR)/$(RSYNC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(RSYNC_DIR) package/rsync/ rsync\*.patch
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(RSYNC_DIR)/.configured: $(RSYNC_DIR)/.unpacked
	(cd $(RSYNC_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--with-included-popt \
	)
	touch $@

$(RSYNC_DIR)/$(RSYNC_BINARY): $(RSYNC_DIR)/.configured
	$(MAKE) -C $(RSYNC_DIR)

$(TARGET_DIR)/$(RSYNC_TARGET_BINARY): $(RSYNC_DIR)/$(RSYNC_BINARY)
	$(INSTALL) -D -m 0755 $(RSYNC_DIR)/$(RSYNC_BINARY) \
		$(TARGET_DIR)/$(RSYNC_TARGET_BINARY)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

rsync: uclibc $(TARGET_DIR)/$(RSYNC_TARGET_BINARY)

rsync-source: $(DL_DIR)/$(RSYNC_SOURCE)

rsync-clean:
	-$(MAKE) -C $(RSYNC_DIR) clean
	rm -f $(TARGET_DIR)/$(RSYNC_TARGET_BINARY)

rsync-dirclean:
	rm -rf $(RSYNC_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_RSYNC),y)
TARGETS+=rsync
endif
