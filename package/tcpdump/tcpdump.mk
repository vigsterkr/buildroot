#############################################################
#
# tcpdump
#
#############################################################
# Copyright (C) 2001-2003 by Erik Andersen <andersen@codepoet.org>
# Copyright (C) 2002 by Tim Riker <Tim@Rikers.org>

TCPDUMP_VERSION:=3.9.8
TCPDUMP_DIR:=$(BUILD_DIR)/tcpdump-$(TCPDUMP_VERSION)
TCPDUMP_SITE:=http://www.tcpdump.org/release
TCPDUMP_SOURCE:=tcpdump-$(TCPDUMP_VERSION).tar.gz
TCPDUMP_CAT:=$(ZCAT)

ifneq ($(BR2_PACKAGE_TCPDUMP_SMB),y)
TCPDUMP_ENABLE_SMB:=--disable-smb
else
TCPDUMP_ENABLE_SMB:=--enable-smb
endif

$(DL_DIR)/$(TCPDUMP_SOURCE):
	 $(WGET) -P $(DL_DIR) $(TCPDUMP_SITE)/$(TCPDUMP_SOURCE)

$(TCPDUMP_DIR)/.unpacked: $(DL_DIR)/$(TCPDUMP_SOURCE)
	$(TCPDUMP_CAT) $(DL_DIR)/$(TCPDUMP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(TCPDUMP_DIR) package/tcpdump tcpdump\*.patch
	$(CONFIG_UPDATE) $(@D)
	# alleged autoconf bug
	$(SED) 's/-O2//g' $(@D)/configure
	touch $@

$(TCPDUMP_DIR)/.configured: $(TCPDUMP_DIR)/.unpacked
	(cd $(TCPDUMP_DIR); rm -f config.cache; \
		$(if $(KERNEL_MAJORVERSION),ac_cv_linux_vers=$(KERNEL_MAJORVERSION)) \
		BUILD_CC=$(TARGET_CC) \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--without-crypto \
		$(TCPDUMP_ENABLE_SMB) \
		$(DISABLE_IPV6) \
	)
	$(SED) '/HAVE_PCAP_DEBUG/d' $(TCPDUMP_DIR)/config.h
	touch $@

$(TCPDUMP_DIR)/tcpdump: $(TCPDUMP_DIR)/.configured
	$(MAKE) CC="$(TARGET_CC)" \
		LDFLAGS="-L$(STAGING_DIR)/usr/lib" \
		LIBS="-lpcap" \
		INCLS="-I. -I$(STAGING_DIR)/usr/include" \
		-C $(TCPDUMP_DIR)

$(TARGET_DIR)/usr/sbin/tcpdump: $(TCPDUMP_DIR)/tcpdump
	cp -f $< $@
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

tcpdump: uclibc zlib libpcap $(TARGET_DIR)/usr/sbin/tcpdump

tcpdump-source: $(DL_DIR)/$(TCPDUMP_SOURCE)

tcpdump-clean:
	-$(MAKE) -C $(TCPDUMP_DIR) clean
	rm -f $(TARGET_DIR)/usr/sbin/tcpdump

tcpdump-dirclean:
	rm -rf $(TCPDUMP_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_TCPDUMP)),y)
TARGETS+=tcpdump
endif
