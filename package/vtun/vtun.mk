#############################################################
#
# vtun
#
# NOTE: Uses start-stop-daemon in init script, so be sure
# to enable that within busybox
#
#############################################################
VTUN_VERSION:=3.0.1
VTUN_SOURCE:=vtun_$(VTUN_VERSION).orig.tar.gz
VTUN_PATCH:=vtun_$(VTUN_VERSION)-1.diff.gz
VTUN_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/v/vtun
VTUN_DIR:=$(BUILD_DIR)/vtun-$(VTUN_VERSION)
VTUN_CAT:=$(ZCAT)
VTUN_BINARY:=vtund
VTUN_TARGET_BINARY:=usr/sbin/vtund

vtun-patched: $(VTUN_DIR)/.patched

$(DL_DIR)/$(VTUN_SOURCE):
	 $(WGET) -P $(DL_DIR) $(VTUN_SITE)/$(VTUN_SOURCE)
ifneq ($(VTUN_PATCH),)
VTUN_PATCH_FILE:=$(DL_DIR)/$(VTUN_PATCH)
$(VTUN_PATCH_FILE):
	 $(WGET) -P $(DL_DIR) $(VTUN_SITE)/$(VTUN_PATCH)
endif

$(VTUN_DIR)/.patched: $(DL_DIR)/$(VTUN_SOURCE) $(VTUN_PATCH_FILE)
	$(VTUN_CAT) $(DL_DIR)/$(VTUN_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(VTUN_PATCH_FILE),)
	(cd $(VTUN_DIR) && $(VTUN_CAT) $(VTUN_PATCH_FILE) | patch -p1)
	if [ -d $(VTUN_DIR)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(VTUN_DIR) $(VTUN_DIR)/debian/patches \*-\*; \
	fi
endif
	toolchain/patch-kernel.sh $(VTUN_DIR) package/vtun/ vtun\*$(VTUN_VERSION)\*.patch
	# fakeroot does this for us
	$(SED) '/^INSTALL_OWNER/d' $(VTUN_DIR)/Makefile.in
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(VTUN_DIR)/.configured: $(VTUN_DIR)/.patched
	(cd $(VTUN_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--with-ssl-headers=$(STAGING_DIR)/usr/include/openssl \
		--with-lzo-headers=$(STAGING_DIR)/usr/include \
		--with-lzo-lib=$(STAGING_DIR)/usr/lib \
		--disable-socks \
		--disable-shaper \
	)
	touch $@

$(VTUN_DIR)/$(VTUN_BINARY): $(VTUN_DIR)/.configured
	$(MAKE) -C $(VTUN_DIR)

$(TARGET_DIR)/$(VTUN_TARGET_BINARY): $(VTUN_DIR)/$(VTUN_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(VTUN_DIR) install
	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/share/doc
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/info
endif

vtun: uclibc zlib lzo openssl $(TARGET_DIR)/$(VTUN_TARGET_BINARY)

vtun-source: $(DL_DIR)/$(VTUN_SOURCE) $(VTUN_PATCH_FILE)

vtun-clean:
	-$(MAKE) DESTDIR=$(TARGET_DIR) -C $(VTUN_DIR) uninstall
	-$(MAKE) -C $(VTUN_DIR) clean

vtun-dirclean:
	rm -rf $(VTUN_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_VTUN),y)
TARGETS+=vtun
endif
