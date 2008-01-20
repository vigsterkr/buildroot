#############################################################
#
# make
#
#############################################################
GNUMAKE_VERSION:=3.81
GNUMAKE_SOURCE:=make-$(GNUMAKE_VERSION).tar.bz2
GNUMAKE_SITE:=$(BR2_GNU_MIRROR)/make
GNUMAKE_DIR:=$(BUILD_DIR)/make-$(GNUMAKE_VERSION)
GNUMAKE_CAT:=$(BZCAT)
GNUMAKE_BINARY:=make
GNUMAKE_TARGET_BINARY:=usr/bin/make

$(DL_DIR)/$(GNUMAKE_SOURCE):
	 $(WGET) -P $(DL_DIR) $(GNUMAKE_SITE)/$(GNUMAKE_SOURCE)

$(GNUMAKE_DIR)/.unpacked: $(DL_DIR)/$(GNUMAKE_SOURCE)
	$(GNUMAKE_CAT) $(DL_DIR)/$(GNUMAKE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(GNUMAKE_DIR)/config
	touch $@

$(GNUMAKE_DIR)/.configured: $(GNUMAKE_DIR)/.unpacked
	(cd $(GNUMAKE_DIR); rm -rf config.cache; \
		make_cv_sys_gnu_glob=no \
		GLOBINC='-I$(GNUMAKE_DIR)/glob' \
		GLOBLIB=glob/libglob.a \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(GNUMAKE_DIR)/$(GNUMAKE_BINARY): $(GNUMAKE_DIR)/.configured
	$(MAKE) MAKE=$(HOSTMAKE) -C $(GNUMAKE_DIR)

$(TARGET_DIR)/$(GNUMAKE_TARGET_BINARY): $(GNUMAKE_DIR)/$(GNUMAKE_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(GNUMAKE_DIR) install
	rm -rf $(TARGET_DIR)/share/locale \
		$(TARGET_DIR)/usr/share/doc
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif

make: uclibc $(TARGET_DIR)/$(GNUMAKE_TARGET_BINARY)

make-source: $(DL_DIR)/$(GNUMAKE_SOURCE)

make-clean:
	-$(MAKE) -C $(GNUMAKE_DIR) clean
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(GNUMAKE_DIR) uninstall

make-dirclean:
	rm -rf $(GNUMAKE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_MAKE),y)
TARGETS+=make
endif
