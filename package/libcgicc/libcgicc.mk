#############################################################
#
# libcgicc
#
#############################################################

LIBCGICC_VERSION=3.2.4
LIBCGICC_DIR=$(BUILD_DIR)/cgicc-$(LIBCGICC_VERSION)
LIBCGICC_SITE=$(BR2_GNU_MIRROR)/gnu/cgicc/
LIBCGICC_SOURCE=cgicc-$(LIBCGICC_VERSION).tar.gz
LIBCGICC_CAT:=$(ZCAT)

$(DL_DIR)/$(LIBCGICC_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBCGICC_SITE)/$(LIBCGICC_SOURCE)

$(LIBCGICC_DIR)/.unpacked: $(DL_DIR)/$(LIBCGICC_SOURCE)
	$(LIBCGICC_CAT) $(DL_DIR)/$(LIBCGICC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	# building the docs didn't work, disable them
	$(SED) 's/^SUBDIRS.*/SUBDIRS=cgicc/' $(LIBCGICC_DIR)/Makefile.in
	touch $@

$(LIBCGICC_DIR)/.configured: $(LIBCGICC_DIR)/.unpacked
	(cd $(LIBCGICC_DIR); rm -f config.cache; \
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
		--includedir=/usr/include \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
	)
	touch $@

$(LIBCGICC_DIR)/.compiled: $(LIBCGICC_DIR)/.configured
	$(MAKE) -C $(LIBCGICC_DIR)
	touch $@

$(STAGING_DIR)/lib/libcgicc.so: $(LIBCGICC_DIR)/.compiled
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LIBCGICC_DIR) install
	touch -c $@

$(TARGET_DIR)/usr/lib/libcgicc.so: $(STAGING_DIR)/lib/libcgicc.so
	mkdir -p $(@D)
	cp -dpf $(STAGING_DIR)/lib/libcgicc.so* $(TARGET_DIR)/usr/lib/
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libcgicc.so*

libcgicc: uclibc $(TARGET_DIR)/usr/lib/libcgicc.so

libcgicc-source: $(DL_DIR)/$(LIBCGICC_SOURCE)

libcgicc-clean:
	-$(MAKE) -C $(LIBCGICC_DIR) clean
	rm -f $(TARGET_DIR)/usr/lib/libcgicc.*

libcgicc-dirclean:
	rm -rf $(LIBCGICC_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBCGICC),y)
TARGETS+=libcgicc
endif
