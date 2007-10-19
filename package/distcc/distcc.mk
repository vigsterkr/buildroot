#############################################################
#
# distcc
#
#############################################################
DISTCC_VERSION:=2.18.3
DISTCC_SOURCE:=distcc-$(DISTCC_VERSION).tar.bz2
DISTCC_CAT:=$(BZCAT)
DISTCC_SITE:=http://distcc.samba.org/ftp/distcc/
DISTCC_BUILDDIR:=$(BUILD_DIR)/distcc-$(DISTCC_VERSION)
DISTCC_BINARY:=distcc
DISTCC_TARGET_BINARY:=usr/bin/distcc

$(DL_DIR)/$(DISTCC_SOURCE):
	$(WGET) -P $(DL_DIR) $(DISTCC_SITE)/$(DISTCC_SOURCE)

$(DISTCC_BUILDDIR)/.unpacked: $(DL_DIR)/$(DISTCC_SOURCE)
	$(DISTCC_CAT) $(DL_DIR)/$(DISTCC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(DISTCC_BUILDDIR)/.configured: $(DISTCC_BUILDDIR)/.unpacked
	(cd $(DISTCC_BUILDDIR); rm -rf config.cache; \
		$(AUTO_TARGET_CONFIGURE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--with-included-popt \
		--without-gtk \
		--without-gnome \
	)
	touch $@

$(DISTCC_BUILDDIR)/$(DISTCC_BINARY): $(DISTCC_BUILDDIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(DISTCC_BUILDDIR)

$(TARGET_DIR)/$(DISTCC_TARGET_BINARY): $(DISTCC_BUILDDIR)/$(DISTCC_BINARY)
	$(INSTALL) -D $(DISTCC_BUILDDIR)/$(DISTCC_BINARY)d $(TARGET_DIR)/$(DISTCC_TARGET_BINARY)d
	$(INSTALL) -D $(DISTCC_BUILDDIR)/$(DISTCC_BINARY) $(TARGET_DIR)/$(DISTCC_TARGET_BINARY)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/$(DISTCC_TARGET_BINARY) \
		$(TARGET_DIR)/$(DISTCC_TARGET_BINARY)d

distcc: uclibc $(TARGET_DIR)/$(DISTCC_TARGET_BINARY)

distcc-source: $(DL_DIR)/$(CVS_SOURCE)

distcc-clean:
	-$(MAKE) -C $(DISTCC_BUILDDIR) clean
	rm -f $(TARGET_DIR)/$(DISTCC_TARGET_BINARY) \
		$(TARGET_DIR)/$(DISTCC_TARGET_BINARY)d

distcc-dirclean:
	rm -rf $(DISTCC_BUILDDIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_DISTCC),y)
TARGETS+=distcc
endif
