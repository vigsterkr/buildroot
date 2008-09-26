#############################################################
#
# strace
#
#############################################################
STRACE_VERSION:=4.5.18
STRACE_SOURCE:=strace-$(STRACE_VERSION).tar.bz2
STRACE_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/strace
STRACE_CAT:=$(BZCAT)
STRACE_DIR:=$(BUILD_DIR)/strace-$(STRACE_VERSION)

BR2_STRACE_CFLAGS:=
ifeq ($(BR2_LARGEFILE),)
BR2_STRACE_CFLAGS+=-U_LARGEFILE64_SOURCE -U__USE_LARGEFILE64 -U__USE_FILE_OFFSET64
endif

$(DL_DIR)/$(STRACE_SOURCE):
	 $(WGET) -P $(DL_DIR) $(STRACE_SITE)/$(STRACE_SOURCE)

strace-source: $(DL_DIR)/$(STRACE_SOURCE)

$(STRACE_DIR)/.unpacked: $(DL_DIR)/$(STRACE_SOURCE)
	$(STRACE_CAT) $(DL_DIR)/$(STRACE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(STRACE_DIR) package/strace strace-$(STRACE_VERSION)\*.patch
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(STRACE_DIR)/.configured: $(STRACE_DIR)/.unpacked
	(cd $(STRACE_DIR); rm -rf config.cache; \
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
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(STRACE_DIR)/strace: $(STRACE_DIR)/.configured
	$(MAKE) -C $(STRACE_DIR)
	touch -c $@

$(TARGET_DIR)/usr/bin/strace: $(STRACE_DIR)/strace
	$(INSTALL) -D $< $@
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@
ifeq ($(BR2_CROSS_TOOLCHAIN_TARGET_UTILS),y)
	$(INSTALL) -D $(TARGET_DIR)/usr/bin/strace \
		$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/target_utils/strace
endif

strace: uclibc $(TARGET_DIR)/usr/bin/strace

strace-clean:
	-$(MAKE) -C $(STRACE_DIR) clean
	rm -f $(TARGET_DIR)/usr/bin/strace

strace-dirclean:
	rm -rf $(STRACE_DIR)


#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_STRACE),y)
TARGETS+=strace
endif
