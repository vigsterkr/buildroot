#############################################################
#
# ltrace
#
#############################################################
LTRACE_VERSION=0.5
LTRACE_SOURCE=ltrace_$(LTRACE_VERSION).orig.tar.gz
LTRACE_PATCH=ltrace_$(LTRACE_VERSION)-3.1.diff.gz
LTRACE_SITE=$(BR2_DEBIAN_MIRROR)/debian/pool/main/l/ltrace
LTRACE_DIR=$(BUILD_DIR)/ltrace-$(LTRACE_VERSION)
LTRACE_BINARY=ltrace
LTRACE_TARGET_BINARY=usr/bin/ltrace

LTRACE_ARCH:=$(KERNEL_ARCH)
ifeq ("$(strip $(LTRACE_ARCH))","powerpc")
LTRACE_ARCH:=ppc
endif

$(DL_DIR)/$(LTRACE_SOURCE):
	$(WGET) -P $(DL_DIR) $(LTRACE_SITE)/$(LTRACE_SOURCE)

ifneq ($(LTRACE_PATCH),)
LTRACE_PATCH_FILE:=$(DL_DIR)/$(LTRACE_PATCH)
$(LTRACE_PATCH_FILE):
	$(WGET) -P $(DL_DIR) $(LTRACE_SITE)/$(LTRACE_PATCH)

else
LTRACE_PATCH_FILE:=
endif

$(LTRACE_DIR)/.patched: $(DL_DIR)/$(LTRACE_SOURCE) $(LTRACE_PATCH_FILE)
	$(ZCAT) $(DL_DIR)/$(LTRACE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(LTRACE_PATCH),)
	$(ZCAT) $(LTRACE_PATCH_FILE) | patch -p1 -d $(LTRACE_DIR)
endif
	toolchain/patch-kernel.sh $(LTRACE_DIR) package/ltrace ltrace\*.patch
	$(CONFIG_UPDATE) $(@D)
	chmod +x $(LTRACE_DIR)/configure
	ln -sf linux-gnu $(LTRACE_DIR)/sysdeps/linux-uclibc
	$(SED) 's/@\(DEFS\)@/@\1@ $$(\1)/' $(LTRACE_DIR)/Makefile.in
	touch $@

$(LTRACE_DIR)/.configured: $(LTRACE_DIR)/.patched
	(cd $(LTRACE_DIR); rm -rf config.cache; \
		ac_cv_header_gelf_h=yes \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(LTRACE_DIR)/$(LTRACE_BINARY): $(LTRACE_DIR)/.configured
	$(MAKE) ARCH=$(LTRACE_ARCH) \
		DEFS="-DUSE_DEMANGLE" \
		-C $(LTRACE_DIR)

$(TARGET_DIR)/$(LTRACE_TARGET_BINARY): $(LTRACE_DIR)/$(LTRACE_BINARY)
	#$(MAKE) DESTDIR=$(TARGET_DIR) ARCH=$(LTRACE_ARCH)  -C $(LTRACE_DIR) install
	$(INSTALL) -D $(LTRACE_DIR)/$(LTRACE_BINARY) $@
ifeq ($(BR2_HAVE_MANPAGES),y)
	$(INSTALL) -D $(LTRACE_DIR)/ltrace.1 \
		$(TARGET_DIR)/usr/share/man/man1/ltrace.1
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

ltrace: uclibc libelf $(TARGET_DIR)/$(LTRACE_TARGET_BINARY)

ltrace-source: $(DL_DIR)/$(LTRACE_SOURCE) $(LTRACE_PATCH_FILE)

ltrace-clean:
	-$(MAKE) -C $(LTRACE_DIR) clean
	rm -f $(LTRACE_DIR)/$(LTRACE_BINARY) \
		$(TARGET_DIR)/usr/share/man/man1/ltrace.1*

ltrace-dirclean:
	rm -rf $(LTRACE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LTRACE),y)
TARGETS+=ltrace
endif
