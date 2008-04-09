#############################################################
#
# bind
#
#############################################################
BIND_VERSION:=9.4.2
BIND_SOURCE:=bind-$(BIND_VERSION).tar.gz
BIND_SITE:=ftp://ftp.isc.org/isc/bind9/$(BIND_VERSION)
BIND_DIR1:=$(TOOL_BUILD_DIR)/bind-$(BIND_VERSION)
BIND_DIR2:=$(BUILD_DIR)/bind-$(BIND_VERSION)
BIND_CAT:=$(ZCAT)
BIND_BINARY:=bin/named/named
BIND_TARGET_BINARY:=usr/sbin/named

$(DL_DIR)/$(BIND_SOURCE):
	 $(WGET) -P $(DL_DIR) $(BIND_SITE)/$(BIND_SOURCE)

#############################################################
#
# build bind for use on the target system
#
#############################################################
$(BIND_DIR2)/.unpacked: $(DL_DIR)/$(BIND_SOURCE)
	$(BIND_CAT) $(DL_DIR)/$(BIND_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BIND_DIR2) package/bind/ bind\*$(BIND_VERSION)\*.patch
	$(CONFIG_UPDATE) $(@D)
	$(CONFIG_UPDATE) $(@D)/lib/bind
	touch $@

$(BIND_DIR2)/Makefile: $(BIND_DIR2)/.unpacked
	(cd $(BIND_DIR2); rm -rf config.cache; \
		BUILD_CC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST__CFLAGS)" \
		BUILD_CPPFLAGS="$(HOST_CPPFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		BUILD_LIBS="$(HOST_LIBS)" \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_IPV6) \
		$(DISABLE_LARGEFILE) \
		$(THREADS) \
		--with-randomdev=/dev/random \
		--without-openssl \
		--disable-atomic \
		--with-libtool \
		--with-pic \
	)

$(BIND_DIR2)/$(BIND_BINARY): $(BIND_DIR2)/Makefile
	$(MAKE) -C $(BIND_DIR2)
	touch -c $@

#############################################################
#
# install bind binaries
#
#############################################################
$(TARGET_DIR)/$(BIND_TARGET_BINARY): $(BIND_DIR2)/$(BIND_BINARY)
	$(MAKE1) MAKEDEFS="INSTALL_DATA=true" \
		DESTDIR=$(TARGET_DIR) -C $(BIND_DIR2)/bin install
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_HEADERS),y)
	rm -rf $(TARGET_DIR)/usr/include/isc
	rm -rf $(TARGET_DIR)/usr/include/isccc
	rm -rf $(TARGET_DIR)/usr/include/dns
	rm -rf $(TARGET_DIR)/usr/include/dst
	rm -rf $(TARGET_DIR)/usr/include/isccfg
	rm -rf $(TARGET_DIR)/usr/include/bind[0-9][0-9]*
	rm -rf $(TARGET_DIR)/usr/include/lwres
endif
	$(INSTALL) -m 0755 -D package/bind/bind.sysvinit $(TARGET_DIR)/etc/init.d/S81named
	$(STRIPCMD) $(STRIP_STRIP_ALL) \
		$(addprefix $(TARGET_DIR)/usr/sbin/,named rndc rndc-confgen dnssec-keygen dnssec-signzone named-checkconf named-checkzone) \
		$(addprefix $(TARGET_DIR)/usr/bin/,dig host nslookup)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

bind-bin: $(TARGET_DIR)/$(BIND_TARGET_BINARY) bind-lib

#############################################################
#
# install bind libraries
#
#############################################################
$(STAGING_DIR)/usr/lib/libdns.so: $(BIND_DIR2)/$(BIND_BINARY)
	$(MAKE1) DESTDIR=$(STAGING_DIR) -C $(BIND_DIR2)/lib install

$(TARGET_DIR)/usr/lib/libdns.so: $(STAGING_DIR)/usr/lib/libdns.so
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	cp -dpf $(wildcard $(addprefix $(STAGING_DIR)/usr/lib/,libdns*so* libisc*so* libbind9*so* liblwres*so*)) $(TARGET_DIR)/usr/lib/
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) \
		$(TARGET_DIR)/usr/lib/libdns*so* \
		$(TARGET_DIR)/usr/lib/libisc*so* \
		$(TARGET_DIR)/usr/lib/libbind9*so* \
		$(TARGET_DIR)/usr/lib/liblwres*so*

bind-lib: $(STAGING_DIR)/usr/lib/libdns.so $(TARGET_DIR)/usr/lib/libdns.so

bind: uclibc bind-bin bind-lib

bind-source: $(DL_DIR)/$(BIND_SOURCE)

bind-clean:
	-$(MAKE) -C $(BIND_DIR2) clean
	rm -rf $(TARGET_DIR)/usr/lib/libdns*so* \
		$(TARGET_DIR)/usr/lib/libisc*so* \
		$(TARGET_DIR)/usr/lib/libbind9*so* \
		$(TARGET_DIR)/usr/lib/liblwres*so* \
		$(TARGET_DIR)/etc/init.d/S81named \
		$(addprefix $(TARGET_DIR)/usr/sbin/,named rndc rndc-confgen dnssec-keygen dnssec-signzone named-checkconf named-checkzone) \
		$(addprefix $(TARGET_DIR)/usr/bin/,dig host nslookup)

bind-dirclean:
	rm -rf $(BIND_DIR2)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_BIND),y)
TARGETS+=bind
endif

