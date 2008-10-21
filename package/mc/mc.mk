#############################################################
#
# mc
#
#############################################################
MC_VERSION:=4.6.2~git20080311
MC_PATCH:=-4
MC_SOURCE:=mc_$(MC_VERSION).orig.tar.gz
MC_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/m/mc
MC_CAT:=$(ZCAT)
MC_DIR:=$(BUILD_DIR)/mc-$(MC_VERSION)
MC_BINARY:=src/mc
MC_TARGET_BINARY:=usr/bin/mc


ifneq ($(strip $(MC_PATCH)),)
MC_PATCH_FILE:=$(DL_DIR)/mc_$(MC_VERSION)$(MC_PATCH).diff.gz
$(MC_PATCH_FILE):
	$(WGET) -P $(DL_DIR) $(MC_SITE)/$(notdir $@)
	touch -c $@
endif
$(DL_DIR)/$(MC_SOURCE):
	$(WGET) -P $(DL_DIR) $(MC_SITE)/$(MC_SOURCE)
	touch -c $@

$(MC_DIR)/.unpacked: $(DL_DIR)/$(MC_SOURCE) $(MC_PATCH_FILE)
	$(MC_CAT) $(DL_DIR)/$(MC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(MC_PATCH_FILE),)
	(cd $(@D) && $(MC_CAT) $(MC_PATCH_FILE) | patch -p1)
	if [ -d $(@D)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(@D) $(@D)/debian/patches \*-\*; \
	fi
endif
	#toolchain/patch-kernel.sh $(MC_DIR) package/mc \*.patch
	$(CONFIG_UPDATE) $(@D)
	-chmod +x $(@D)/configure
	touch $@

MC_EXTRA_CONFIG=--with-included-gettext \
		$(if $(BR2_PACKAGE_SLANG),,--with-included-slang) \
		--with-subshell=no \
		--with-terminfo \

$(MC_DIR)/.configured: $(MC_DIR)/.unpacked
	(cd $(MC_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
		--with-mmap \
		--with-vfs \
		--disable-glibtest \
		$(if $(BR2_PACKAGE_GPM),--with-gpm-mouse,--without-gpm-mouse) \
		$(if $(BR2_PACKAGE_MC_EDIT),--with-edit,--without-edit) \
		$(if $(BR2_PACKAGE_XSERVER_none),--without-x,--with-x) \
		$(if $(BR2_PACKAGE_SLANG),--with-screen=slang,$(if $(BR2_PACKAGE_NCURSES),--with-screen=ncurses)) \
	)
	touch $@

$(MC_DIR)/$(MC_BINARY): $(MC_DIR)/.configured
	$(MAKE) -C $(MC_DIR)

$(TARGET_DIR)/$(MC_TARGET_BINARY): $(MC_DIR)/$(MC_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(MC_DIR) install
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

mc: uclibc pkgconfig $(if $(BR2_PACKAGE_GPM),gpm) $(TARGET_DIR)/$(MC_TARGET_BINARY)

mc-source: $(DL_DIR)/$(MC_SOURCE)

mc-clean:
	-$(MAKE) -C $(MC_DIR) clean
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(MC_DIR) uninstall

mc-dirclean:
	rm -rf $(MC_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_MC),y)
TARGETS+=mc
endif
