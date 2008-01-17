#############################################################
#
# flex
#
#############################################################
FLEX_VERSION:=2.5.33
FLEX_PATCH_VERSION:=12
FLEX_SOURCE:=flex_$(FLEX_VERSION).orig.tar.gz
FLEX_PATCH:=flex_$(FLEX_VERSION)-$(FLEX_PATCH_VERSION).diff.gz
FLEX_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/f/flex
FLEX_DIR:=$(BUILD_DIR)/flex-$(FLEX_VERSION)
FLEX_CAT:=$(ZCAT)
FLEX_BINARY:=flex
FLEX_TARGET_BINARY:=usr/bin/flex

$(DL_DIR)/$(FLEX_SOURCE):
	 $(WGET) -P $(DL_DIR) $(FLEX_SITE)/$(FLEX_SOURCE)

$(DL_DIR)/$(FLEX_PATCH):
	 $(WGET) -P $(DL_DIR) $(FLEX_SITE)/$(FLEX_PATCH)

$(FLEX_DIR)/.unpacked: $(DL_DIR)/$(FLEX_SOURCE) $(DL_DIR)/$(FLEX_PATCH)
	$(FLEX_CAT) $(DL_DIR)/$(FLEX_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(FLEX_PATCH),)
	toolchain/patch-kernel.sh $(FLEX_DIR) $(DL_DIR) $(FLEX_PATCH)
	if [ -d $(FLEX_DIR)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(FLEX_DIR) $(FLEX_DIR)/debian/patches \*.patch; \
	fi
endif
	$(CONFIG_UPDATE) $(FLEX_DIR)
	touch $@

$(FLEX_DIR)/.configured: $(FLEX_DIR)/.unpacked
	(cd $(FLEX_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--includedir=$(STAGING_DIR)/usr/include \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(FLEX_DIR)/$(FLEX_BINARY): $(FLEX_DIR)/.configured
	$(MAKE) -C $(FLEX_DIR)

$(TARGET_DIR)/$(FLEX_TARGET_BINARY): $(FLEX_DIR)/$(FLEX_BINARY)
	$(MAKE1) -C $(FLEX_DIR) \
		DESTDIR=$(STAGING_DIR) includedir=/usr/include install
	$(INSTALL) -D -m 0755 $(STAGING_DIR)/$(FLEX_TARGET_BINARY) \
		$(TARGET_DIR)/$(FLEX_TARGET_BINARY)
ifeq ($(BR2_PACKAGE_FLEX_LIBFL),y)
	$(INSTALL) -D $(STAGING_DIR)/usr/lib/libfl.a \
		$(TARGET_DIR)/usr/lib/libfl.a
	$(INSTALL) -D $(STAGING_DIR)/usr/lib/libfl_pic.a \
		$(TARGET_DIR)/usr/lib/libfl_pic.a
endif
ifeq ($(BR2_HAVE_INFOPAGES),y)
	$(MAKE1) -C $(FLEX_DIR) \
		DESTDIR=$(TARGET_DIR) includedir=/usr/include install-info
else
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifeq ($(BR2_HAVE_MANPAGES),y)
	$(MAKE1) -C $(FLEX_DIR) \
		DESTDIR=$(TARGET_DIR) includedir=/usr/include install-man
else
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	ln -snf flex $(TARGET_DIR)/usr/bin/lex
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

flex: uclibc $(TARGET_DIR)/$(FLEX_TARGET_BINARY)

flex-source: $(DL_DIR)/$(FLEX_SOURCE) $(DL_DIR)/$(FLEX_PATCH)

flex-clean:
	-$(MAKE) -C $(FLEX_DIR) clean
	$(MAKE) -C $(FLEX_DIR) \
		DESTDIR=$(STAGING_DIR) includedir=/usr/include uninstall
	$(MAKE) -C $(FLEX_DIR) \
		DESTDIR=$(TARGET_DIR) includedir=/usr/include uninstall
	rm -f $(TARGET_DIR)/usr/bin/lex $(TARGET_DIR)/usr/bin/flex
ifeq ($(BR2_PACKAGE_FLEX_LIBFL),y)
	-rm $(TARGET_DIR)/usr/lib/libfl.a $(TARGET_DIR)/usr/lib/libfl_pic.a \
		$(TARGET_DIR)/usr/include/FlexLexer.h
endif

flex-dirclean:
	rm -rf $(FLEX_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_FLEX),y)
TARGETS+=flex
endif
