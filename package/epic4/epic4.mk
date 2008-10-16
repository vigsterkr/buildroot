#############################################################
#
# epic4
#
#############################################################
EPIC4_VERSION:=2.10
EPIC4_SOURCE:=epic4-$(EPIC4_VERSION).tar.bz2
EPIC4_SITE:=http://ftp.epicsol.org/pub/epic/EPIC4-PRODUCTION/
EPIC4_DIR:=$(BUILD_DIR)/epic4-$(EPIC4_VERSION)
EPIC4_CAT:=$(BZCAT)
EPIC4_BINARY:=source/epic
EPIC4_TARGET_BINARY:=usr/bin/epic4

$(DL_DIR)/$(EPIC4_SOURCE):
	 $(WGET) -P $(DL_DIR) $(EPIC4_SITE)/$(EPIC4_SOURCE)

$(EPIC4_DIR)/.unpacked: $(DL_DIR)/$(EPIC4_SOURCE)
	$(EPIC4_CAT) $(DL_DIR)/$(EPIC4_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(EPIC4_DIR)/
	touch $@

$(EPIC4_DIR)/.configured: $(EPIC4_DIR)/.unpacked
	(cd $(EPIC4_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		$(if $(BR2_INET_IPV6),,--without-ipv6) \
		$(if $(BR2_PACKAGE_OPENSSL),,--without-ssl) \
		$(if $(BR2_PACKAGE_MICROPERL)$(BR2_PACKAGE_PERL),,--without-perl) \
		$(if $(BR2_PACKAGE_NCURSES),--without-termcap,--with-termcap) \
	)
	touch $@

$(EPIC4_DIR)/$(EPIC4_BINARY): $(EPIC4_DIR)/.configured
	#$(MAKE) -C $(EPIC4_DIR)/
	# huh?
	#(cd $(@D) && $(HOSTCC) -static -o my_test test.c)
	$(MAKE) -C $(EPIC4_DIR)/source epic
	touch -c $@

$(TARGET_DIR)/$(EPIC4_TARGET_BINARY): $(EPIC4_DIR)/$(EPIC4_BINARY)
	#$(MAKE) IP=$(TARGET_DIR) -C $(EPIC4_DIR) installepic #installscript
	$(INSTALL) -D -m0755 $< $@
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

epic4: $(if $(BR2_PACKAGE_OPENSSL),openssl) \
	$(if $(BR2_PACKAGE_NCURSES),ncurses) \
	$(TARGET_DIR)/$(EPIC4_TARGET_BINARY)

epic4-source: $(DL_DIR)/$(EPIC4_SOURCE)

epic4-clean:
	-$(MAKE) -C $(EPIC4_DIR) clean
	rm -rf $(addprefix $(TARGET_DIR),$(EPIC4_TARGET_BINARY) usr/share/epic)

epic4-dirclean:
	rm -rf $(EPIC4_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_EPIC4),y)
TARGETS+=epic4
endif
