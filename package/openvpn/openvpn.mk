#############################################################
#
# openvpn
#
# NOTE: Uses start-stop-daemon in init script, so be sure
# to enable that within busybox
#
#############################################################
OPENVPN_VERSION:=2.0.9
OPENVPN_SOURCE:=openvpn-$(OPENVPN_VERSION).tar.gz
OPENVPN_SITE:=http://openvpn.net/release/
OPENVPN_DIR:=$(BUILD_DIR)/openvpn-$(OPENVPN_VERSION)
OPENVPN_CAT:=$(ZCAT)
OPENVPN_BINARY:=openvpn
OPENVPN_TARGET_BINARY:=usr/sbin/openvpn

#
# Select thread model.
#
ifeq ($(BR2_PTHREADS_NATIVE),y)
THREAD_MODEL="--enable-threads=posix"
else
THREAD_MODEL=--enable-pthread
endif

$(DL_DIR)/$(OPENVPN_SOURCE):
	 $(WGET) -P $(DL_DIR) $(OPENVPN_SITE)/$(OPENVPN_SOURCE)

$(OPENVPN_DIR)/.unpacked: $(DL_DIR)/$(OPENVPN_SOURCE)
	$(OPENVPN_CAT) $(DL_DIR)/$(OPENVPN_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(OPENVPN_DIR)/.configured: $(OPENVPN_DIR)/.unpacked
	(cd $(OPENVPN_DIR); rm -rf config.cache; \
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
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--program-prefix="" \
		--enable-small \
		$(THREAD_MODEL) \
	)
	touch $@

$(OPENVPN_DIR)/$(OPENVPN_BINARY): $(OPENVPN_DIR)/.configured
	$(MAKE) -C $(OPENVPN_DIR)

$(TARGET_DIR)/$(OPENVPN_TARGET_BINARY): $(OPENVPN_DIR)/$(OPENVPN_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(OPENVPN_DIR) install
	mkdir -p $(TARGET_DIR)/etc/openvpn
	$(INSTALL) -D -m 0755 package/openvpn/openvpn.init $(TARGET_DIR)/etc/init.d/openvpn
ifneq ($(BR2_ENABLE_LOCALE),y)
	rm -rf $(TARGET_DIR)/usr/share/locale
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/info
endif
	rm -rf $(TARGET_DIR)/usr/share/doc

openvpn: uclibc lzo openssl $(TARGET_DIR)/$(OPENVPN_TARGET_BINARY)

openvpn-source: $(DL_DIR)/$(OPENVPN_SOURCE)

openvpn-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(OPENVPN_DIR) uninstall
	-$(MAKE) -C $(OPENVPN_DIR) clean

openvpn-dirclean:
	rm -rf $(OPENVPN_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_OPENVPN),y)
TARGETS+=openvpn
endif
