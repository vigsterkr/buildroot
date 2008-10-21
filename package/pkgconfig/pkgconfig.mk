#############################################################
#
# pkgconfig
#
#############################################################
PKGCONFIG_VERSION:=0.23
PKGCONFIG_SOURCE:=pkg-config-$(PKGCONFIG_VERSION).tar.gz
PKGCONFIG_SITE:=http://pkgconfig.freedesktop.org/releases/
PKGCONFIG_SRCDIR:=$(TOOL_BUILD_DIR)/pkg-config-$(PKGCONFIG_VERSION)
PKGCONFIG_HOSTDIR:=$(TOOL_BUILD_DIR)/pkg-config-$(PKGCONFIG_VERSION)-host
PKGCONFIG_DIR:=$(BUILD_DIR)/pkg-config-$(PKGCONFIG_VERSION)
PKGCONFIG_CAT:=$(ZCAT)
PKGCONFIG_BINARY:=pkg-config
PKGCONFIG_TARGET_BINARY:=usr/bin/pkg-config

$(DL_DIR)/$(PKGCONFIG_SOURCE):
	 $(WGET) -P $(DL_DIR) $(PKGCONFIG_SITE)/$(PKGCONFIG_SOURCE)

$(PKGCONFIG_SRCDIR)/.unpacked: $(DL_DIR)/$(PKGCONFIG_SOURCE)
	$(PKGCONFIG_CAT) $(DL_DIR)/$(PKGCONFIG_SOURCE) | tar -C $(TOOL_BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(@D) package/pkgconfig/ \*.patch
	touch $@

#############################################################
#
# pkgconfig for the staging dir
#
#############################################################
$(PKGCONFIG_HOSTDIR)/.configured: THIS_SRCDIR:=$(PKGCONFIG_SRCDIR)
$(PKGCONFIG_HOSTDIR)/.configured: $(PKGCONFIG_SRCDIR)/.unpacked
	mkdir -p $(@D)
	(cd $(PKGCONFIG_HOSTDIR); rm -rf config.cache; \
		$(HOST_CONFIGURE_OPTS) \
		CFLAGS="$(HOST_CFLAGS)" \
		LDFLAGS="$(HOST_LDFLAGS)" \
		$(PKGCONFIG_SRCDIR)/configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--with-pc-path="$(STAGING_DIR)/usr/lib/pkgconfig" \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(PKGCONFIG_HOSTDIR)/$(PKGCONFIG_BINARY): $(PKGCONFIG_HOSTDIR)/.configured
	$(MAKE) -C $(PKGCONFIG_HOSTDIR)

$(STAGING_DIR)/$(PKGCONFIG_TARGET_BINARY): $(PKGCONFIG_HOSTDIR)/$(PKGCONFIG_BINARY)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(PKGCONFIG_HOSTDIR) install

pkgconfig: uclibc $(STAGING_DIR)/$(PKGCONFIG_TARGET_BINARY)

pkgconfig-source: $(DL_DIR)/$(PKGCONFIG_SOURCE)

pkgconfig-clean:
	-$(MAKE) DESTDIR=$(STAGING_DIR) -C $(PKGCONFIG_HOSTDIR) uninstall
	-$(MAKE) -C $(PKGCONFIG_HOSTDIR) clean

pkgconfig-dirclean:
	rm -rf $(PKGCONFIG_HOSTDIR)

#############################################################
#
# pkgconfig for the target
#
#############################################################

$(PKGCONFIG_DIR)/.configured: THIS_SRCDIR:=$(PKGCONFIG_SRCDIR)
$(PKGCONFIG_DIR)/.configured: $(PKGCONFIG_SRCDIR)/.unpacked
	mkdir -p $(@D)
	(cd $(PKGCONFIG_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(PKGCONFIG_DIR)/$(PKGCONFIG_BINARY): $(PKGCONFIG_DIR)/.configured
	$(MAKE) -C $(PKGCONFIG_DIR)

$(TARGET_DIR)/$(PKGCONFIG_TARGET_BINARY): $(PKGCONFIG_DIR)/$(PKGCONFIG_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(PKGCONFIG_DIR) install
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@


pkgconfig-target: uclibc_target $(STAGING_DIR)/$(PKGCONFIG_TARGET_BINARY)

pkgconfig-target-source: $(DL_DIR)/$(PKGCONFIG_SOURCE)

pkgconfig-target-clean:
	-$(MAKE) DESTDIR=$(STAGING_DIR) -C $(PKGCONFIG_DIR) uninstall
	-$(MAKE) -C $(PKGCONFIG_DIR) clean

pkgconfig-target-dirclean:
	rm -rf $(PKGCONFIG_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_PKGCONFIG),y)
TARGETS+=pkgconfig-target
endif
