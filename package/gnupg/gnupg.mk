#############################################################
#
# gnupg
#
#############################################################
GNUPG_VERSION:=1.4.6
GNUPG_SOURCE:=gnupg_$(GNUPG_VERSION).orig.tar.gz
GNUPG_PATCH:=gnupg_$(GNUPG_VERSION)-2.1.diff.gz
GNUPG_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/g/gnupg
GNUPG_DIR:=$(BUILD_DIR)/gnupg-$(GNUPG_VERSION)
GNUPG_CAT:=$(ZCAT)
GNUPG_BINARY:=g10/gpg
GNUPG_TARGET_BINARY:=usr/bin/gpg

$(DL_DIR)/$(GNUPG_SOURCE):
	$(WGET) -P $(DL_DIR) $(GNUPG_SITE)/$(GNUPG_SOURCE)

$(DL_DIR)/$(GNUPG_PATCH):
	$(WGET) -P $(DL_DIR) $(GNUPG_SITE)/$(GNUPG_PATCH)

$(GNUPG_DIR)/.unpacked: $(DL_DIR)/$(GNUPG_SOURCE) $(DL_DIR)/$(GNUPG_PATCH)
	$(GNUPG_CAT) $(DL_DIR)/$(GNUPG_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(GNUPG_DIR) package/gnupg/ gnupg\*.patch
ifneq ($(GNUPG_PATCH),)
	(cd $(GNUPG_DIR) && $(GNUPG_CAT) $(DL_DIR)/$(GNUPG_PATCH) | patch -p1)
	if [ -d $(GNUPG_DIR)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(GNUPG_DIR) $(GNUPG_DIR)/debian/patches \*.dpatch; \
	fi
endif
	$(CONFIG_UPDATE) $(@D)
	$(SED) 's/-O2//g' $(@D)/configure
	touch $@

$(GNUPG_DIR)/.configured: $(GNUPG_DIR)/.unpacked
	(cd $(GNUPG_DIR); rm -rf config.cache; \
		ac_cv_sys_symbol_underscore=no \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		$(DISABLE_LARGEFILE) \
		$(DISABLE_NLS) \
		--disable-regex \
		--disable-dns-srv \
		--disable-dns-pka \
		--disable-dns-cert \
		--enable-minimal \
	)
	touch $@

$(GNUPG_DIR)/$(GNUPG_BINARY): $(GNUPG_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(GNUPG_DIR)

$(TARGET_DIR)/$(GNUPG_TARGET_BINARY): $(GNUPG_DIR)/$(GNUPG_BINARY)
	$(INSTALL) -D -m0755 $(GNUPG_DIR)/$(GNUPG_BINARY) $@
	$(INSTALL) -D -m0755 $(GNUPG_DIR)/$(GNUPG_BINARY)v $(@D)/
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@ $@v

gnupg: uclibc $(TARGET_DIR)/$(GNUPG_TARGET_BINARY)

gnupg-source: $(DL_DIR)/$(GNUPG_SOURCE) $(DL_DIR)/$(GNUPG_PATCH)

gnupg-clean:
	-$(MAKE) -C $(GNUPG_DIR) clean
	rm -f $(TARGET_DIR)/$(GNUPG_TARGET_BINARY)*

gnupg-dirclean:
	rm -rf $(GNUPG_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_GNUPG),y)
TARGETS+=gnupg
endif
