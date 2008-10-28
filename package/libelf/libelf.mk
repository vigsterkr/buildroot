#############################################################
#
# libelf
#
#############################################################
LIBELF_VERSION=0.8.10
LIBELF_SOURCE=libelf-$(LIBELF_VERSION).tar.gz
LIBELF_SITE=http://www.mr511.de/software/
LIBELF_DIR=$(BUILD_DIR)/libelf-$(LIBELF_VERSION)

ifeq ($(BR2_LARGEFILE),y)
LIBELF_CONFIG:=--enable-elf64
endif

LIBELF_LIBMAJ  :=$(word 1,$(subst ., ,$(LIBELF_VERSION)))
LIBELF_LIBMIN  :=$(word 2,$(subst ., ,$(LIBELF_VERSION)))
LIBELF_LIBPATCH:=$(word 3,$(subst ., ,$(LIBELF_VERSION)))

$(DL_DIR)/$(LIBELF_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBELF_SITE)/$(LIBELF_SOURCE)

$(LIBELF_DIR)/.unpacked: $(DL_DIR)/$(LIBELF_SOURCE)
	$(ZCAT) $(DL_DIR)/$(LIBELF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LIBELF_DIR) package/libelf libelf\*.patch
	$(CONFIG_UPDATE) $(LIBELF_DIR)
	touch $@

$(LIBELF_DIR)/.configured: $(LIBELF_DIR)/.unpacked
	(cd $(LIBELF_DIR); rm -f config.cache; \
		libelf_cv_working_memmove=yes \
		mr_cv_target_elf=yes \
		libelf_64bit=yes \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-shared \
		--disable-debug \
		--disable-sanity-checks \
		$(LIBELF_CONFIG) \
		$(DISABLE_NLS) \
	)
	touch $@

$(LIBELF_DIR)/lib/libelf.so.$(LIBELF_VERSION): $(LIBELF_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(LIBELF_DIR)

$(STAGING_DIR)/usr/lib/libelf.a $(STAGING_DIR)/usr/lib/libelf.so.$(LIBELF_VERSION): $(LIBELF_DIR)/lib/libelf.so.$(LIBELF_VERSION)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) \
		instroot=$(STAGING_DIR) -C $(LIBELF_DIR) install

ifeq ($(BR2_PACKAGE_LIBELF_HEADERS),y)
libelf_headers: $(TARGET_DIR)/usr/lib/libelf.so.$(LIBELF_VERSION)
$(TARGET_DIR)/usr/lib/libelf.so.$(LIBELF_VERSION): $(STAGING_DIR)/usr/lib/libelf.a
	$(INSTALL) -d $(@D)
	$(INSTALL) -m0755 $(STAGING_DIR)/usr/lib/$(@F) $@
	(cd $(@D); \
	 ln -sf $(@F) $(@F:.$(LIBELF_LIBMIN).$(LIBELF_LIBPATCH)=); \
	 ln -sf $(@F) $(@F:.$(LIBELF_VERSION)=); \
	)
	$(INSTALL) -d $(TARGET_DIR)/usr/include
	cp -dpRf $(wildcard $(addprefix $(STAGING_DIR)/usr/include/,gelf.h libelf*)) \
		$(TARGET_DIR)/usr/include/
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

libelf: uclibc $(TARGET_DIR)/usr/lib/libelf.so.$(LIBELF_VERSION)
else
libelf: uclibc $(STAGING_DIR)/usr/lib/libelf.so.$(LIBELF_VERSION)
endif
libelf-source: $(DL_DIR)/$(LIBELF_SOURCE)

libelf-clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(LIBELF_DIR) uninstall
	$(MAKE) instroot=$(STAGING_DIR) -C $(LIBELF_DIR) uninstall
	-$(MAKE) -C $(LIBELF_DIR) clean

libelf-dirclean:
	rm -rf $(LIBELF_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBELF),y)
TARGETS+=libelf
endif
