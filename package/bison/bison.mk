#############################################################
#
# bison
#
#############################################################
BISON_VERSION:=2.3
BISON_SOURCE:=bison-$(BISON_VERSION).tar.bz2
BISON_SITE:=$(BR2_GNU_MIRROR)/bison
BISON_DIR:=$(BUILD_DIR)/bison-$(BISON_VERSION)
BISON_CAT:=$(BZCAT)
BISON_BINARY:=src/bison
BISON_TARGET_BINARY:=usr/bin/bison
ifeq ($(BR2_PACKAGE_BISON_YACC),y)
YACC_TARGET_BINARY:=$(TARGET_DIR)/usr/bin/yacc
endif

$(DL_DIR)/$(BISON_SOURCE):
	 $(WGET) -P $(DL_DIR) $(BISON_SITE)/$(BISON_SOURCE)

$(BISON_DIR)/.unpacked: $(DL_DIR)/$(BISON_SOURCE)
	$(BISON_CAT) $(DL_DIR)/$(BISON_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(BISON_DIR)/build-aux
	touch $@

$(BISON_DIR)/.configured: $(BISON_DIR)/.unpacked
	(cd $(BISON_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		$(if $(YACC_TARGET_BINARY),--enable-yacc,--disable-yacc) \
		$(DISABLE_NLS) \
	)
	echo 'all install install-exec install-info install-man install-data uninstall clean:' \
		> $(BISON_DIR)/examples/Makefile
	touch $@

$(BISON_DIR)/$(BISON_BINARY): $(BISON_DIR)/.configured
	$(MAKE) -C $(BISON_DIR)
	touch -c $@

$(TARGET_DIR)/$(BISON_TARGET_BINARY): $(BISON_DIR)/$(BISON_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(BISON_DIR) install-exec \
		$(MAKE_INSTALL_MAN) $(MAKE_INSTALL_INFO)
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

ifeq ($(BR2_PACKAGE_BISON_YACC),y)
$(TARGET_DIR)/$(YACC_TARGET_BINARY): $(BISON_DIR)/$(BISON_BINARY)
	$(INSTALL) -D -m0755 package/bison/yacc $(TARGET_DIR)/usr/bin/yacc
endif

bison: uclibc $(TARGET_DIR)/$(BISON_TARGET_BINARY) \
      $(YACC_TARGET_BINARY)

bison-source: $(DL_DIR)/$(BISON_SOURCE)

bison-clean:
	-$(MAKE) DESTDIR=$(TARGET_DIR) -C $(BISON_DIR) uninstall
	rm -f $(TARGET_DIR)/$(BISON_TARGET_BINARY) $(YACC_TARGET_BINARY)
	-$(MAKE) -C $(BISON_DIR) clean

bison-dirclean:
	rm -rf $(BISON_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_BISON),y)
TARGETS+=bison
endif
