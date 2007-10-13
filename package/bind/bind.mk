#############################################################
#
# bind
#
#############################################################
BIND_VERSION:=9.4.1
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
	touch $@

$(BIND_DIR2)/Makefile: $(BIND_DIR2)/.unpacked
	(cd $(BIND_DIR2); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		BUILD_CC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--libdir=/lib \
		--libexecdir=/usr/lib \
		--libdir=/lib \
		--includedir=/include \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--without-openssl \
		--with-randomdev=/dev/random \
		$(DISABLE_IPV6) \
		$(DISABLE_LARGEFILE) \
		$(THREADS) \
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
	cd $(TARGET_DIR)/usr/man; rmdir --ignore-fail-on-non-empty man8 man5 `pwd`
endif
	$(INSTALL) -m 0755 -D package/bind/bind.sysvinit $(TARGET_DIR)/etc/init.d/S81named

bind-bin: $(TARGET_DIR)/$(BIND_TARGET_BINARY) bind-lib

#############################################################
#
# install bind libraries
#
#############################################################
$(STAGING_DIR)/lib/libdns.so: $(BIND_DIR2)/$(BIND_BINARY)
	$(MAKE1) DESTDIR=$(STAGING_DIR) -C $(BIND_DIR2)/lib install

$(TARGET_DIR)/lib/libdns.so: $(STAGING_DIR)/lib/libdns.so
	mkdir -p $(TARGET_DIR)/lib
	cd $(STAGING_DIR)/lib && \
	    $(INSTALL) libdns*so* libisc*so* libbind9*so* \
	    liblwres*so* $(TARGET_DIR)/lib/
	$(STRIPCMD) $(TARGET_DIR)/lib/libdns*so* $(TARGET_DIR)/lib/libisc*so* \
		$(TARGET_DIR)/lib/libbind9*so* $(TARGET_DIR)/lib/liblwres*so*

bind-lib: $(STAGING_DIR)/lib/libdns.so $(TARGET_DIR)/lib/libdns.so

bind: uclibc bind-bin bind-lib

bind-source: $(DL_DIR)/$(BIND_SOURCE)

bind-clean:
	-$(MAKE) -C $(BIND_DIR2) clean
	rm -rf $(TARGET_DIR)/lib/libdns*so* $(TARGET_DIR)/lib/libisc*so* \
		$(TARGET_DIR)/lib/libbind9*so* $(TARGET_DIR)/lib/liblwres*so*

bind-dirclean:
	rm -rf $(BIND_DIR2)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BIND)),y)
TARGETS+=bind
endif

