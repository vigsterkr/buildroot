#############################################################
#
# strace
#
#############################################################
STRACE_VERSION:=4.5.15
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
	toolchain/patch-kernel.sh $(STRACE_DIR) package/strace strace\*.patch
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(STRACE_DIR)/.configured: $(STRACE_DIR)/.unpacked
	(cd $(STRACE_DIR); rm -rf config.cache; \
		$(if $(BR_LARGEFILE),ac_cv_type_stat64=yes,ac_cv_type_stat64=no) \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		CFLAGS="$(TARGET_CFLAGS) $(BR2_STRACE_CFLAGS)" \
		ac_cv_header_linux_icmp_h=yes \
		ac_cv_header_linux_if_packet_h=yes \
		ac_cv_header_linux_netlink_h=yes \
		ac_cv_header_linux_in6_h=yes \
		$(if $(BR2__UCLIBC_UCLIBC_HAS_SYS_ERRLIST),ac_cv_have_decl_sys_errlist=yes,ac_cv_have_decl_sys_errlist=no) \
		$(if $(BR2__UCLIBC_UCLIBC_HAS_SYS_SIGLIST),ac_cv_have_decl_sys_siglist=yes,ac_cv_have_decl_sys_siglist=no) \
		./configure \
		--target=$(REAL_GNU_TARGET_NAME) \
		--host=$(REAL_GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
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
	$(MAKE) CC=$(TARGET_CC) -C $(STRACE_DIR)

$(TARGET_DIR)/usr/bin/strace: $(STRACE_DIR)/strace
	$(INSTALL) -D $(STRACE_DIR)/strace $(TARGET_DIR)/usr/bin/strace
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/bin/strace
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
