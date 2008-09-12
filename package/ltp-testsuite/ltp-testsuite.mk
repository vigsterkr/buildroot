#############################################################
#
# ltp-testsuite
#
#############################################################
LTP_TESTSUITE_VERSION:=20080831
LTP_TESTSUITE_SOURCE:=ltp-full-$(LTP_TESTSUITE_VERSION).tgz
LTP_TESTSUITE_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/ltp
LTP_TESTSUITE_CAT:=$(ZCAT)
LTP_TESTSUITE_ROOT:=$(TARGET_DIR)/root
LTP_TESTSUITE_DIR:=$(LTP_TESTSUITE_ROOT)/ltp-full-$(LTP_TESTSUITE_VERSION)

#
# Enable patches based upon different toolchain configuration options.
#
LTP_PATCHES:=ltp-testsuite-generate-needs-bash.patch \
	     ltp-testsuite-sh-is-not-C-code.patch \
	     ltp-testsuite.patch \
	     ltp-testsuite.asm-page-include.patch \
	     ltp-testsuite.obsolete-bsd-signal.patch \
	     ltp-testsuite.susv3-legacy.patch

ifeq ($(BR2_PTHREADS_NATIVE),y)
LTP_PATCHES+=ltp-testsuite-enable-openposix-for-nptl.patch
endif
ifeq ($(BR2_EXT_PTHREADS_NATIVE),y)
LTP_PATCHES+=ltp-testsuite-enable-openposix-for-nptl.patch
endif
ifneq ($(BR2_INET_IPV6),y)
LTP_PATCHES+=ltp-testsuite-disable-ipv6-tests.patch
endif

LTP_TESTSUITE_ENV:= \
	UCLIBC_HAS_OBSOLETE_BSD_SIGNAL=$(BR2__UCLIBC_HAS_OBSOLETE_BSD_SIGNAL) \
	UCLIBC_SUSV3_LEGACY=$(BR2__UCLIBC_SUSV3_LEGACY)

$(DL_DIR)/$(LTP_TESTSUITE_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LTP_TESTSUITE_SITE)/$(LTP_TESTSUITE_SOURCE)

$(LTP_TESTSUITE_DIR)/Makefile: $(DL_DIR)/$(LTP_TESTSUITE_SOURCE)
	mkdir -p $(LTP_TESTSUITE_ROOT)
	$(LTP_TESTSUITE_CAT) $(DL_DIR)/$(LTP_TESTSUITE_SOURCE) | tar -C $(LTP_TESTSUITE_ROOT) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LTP_TESTSUITE_DIR) package/ltp-testsuite/ $(LTP_PATCHES)
	touch -c $@

$(LTP_TESTSUITE_DIR)/.compiled: $(LTP_TESTSUITE_DIR)/Makefile
	$(MAKE1) $(TARGET_CONFIGURE_OPTS) CROSS_COMPILER=$(TARGET_CROSS) \
		$(LTP_TESTSUITE_ENV) \
		-C $(LTP_TESTSUITE_DIR) all
	touch $@

$(LTP_TESTSUITE_DIR)/.installed: $(LTP_TESTSUITE_DIR)/.compiled
	# Use fakeroot to pretend to do 'make install' as root
	echo '$(MAKE1) $(TARGET_CONFIGURE_OPTS) CROSS_COMPILER=$(TARGET_CROSS) ' \
			'-C $(LTP_TESTSUITE_DIR) install' \
			> $(PROJECT_BUILD_DIR)/.fakeroot.ltp
	touch $@

ltp-testsuite: uclibc host-fakeroot $(LTP_TESTSUITE_DIR)/.installed

ltp-testsuite-source: $(DL_DIR)/$(LTP_TESTSUITE_SOURCE)

ltp-testsuite-clean:
	-$(MAKE) -C $(LTP_TESTSUITE_DIR) clean

ltp-testsuite-dirclean:
	rm -rf $(LTP_TESTSUITE_DIR)


#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LTP-TESTSUITE),y)
TARGETS+=ltp-testsuite
endif
