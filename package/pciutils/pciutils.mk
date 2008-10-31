#############################################################
#
# pciutils
#
#############################################################
PCIUTILS_VERSION:=2.2.10
PCIUTILS_VERSION:=3.0.1
PCIUTILS_SOURCE:=pciutils-$(PCIUTILS_VERSION).tar.gz
PCIUTILS_CAT:=$(ZCAT)
PCIUTILS_SITE:=ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci
PCIUTILS_DIR:=$(BUILD_DIR)/pciutils-$(PCIUTILS_VERSION)

# Yet more targets...
PCIIDS_SITE:=http://pciids.sourceforge.net/
PCIIDS_SOURCE:=pci.ids.bz2
PCIIDS_CAT:=$(BZCAT)

ifeq ($(BR2_PACKAGE_ZLIB),y)
PCIUTILS_HAVE_ZLIB=yes
PCIIDS_FILE=pci.ids.gz
else
PCIUTILS_HAVE_ZLIB=no
PCIIDS_FILE=pci.ids
endif

ifeq ($(BR2_ENABLE_SHARED),y)
PCIUTILS_HAVE_SO=yes
LIB_PCI=libpci.so
LIB_PCI_ABIVERSION=.$(word 1,$(subst ., ,$(PCIUTILS_VERSION)))
else
PCIUTILS_HAVE_SO=no
endif

$(DL_DIR)/$(PCIUTILS_SOURCE):
	 $(WGET) -P $(DL_DIR) $(PCIUTILS_SITE)/$(PCIUTILS_SOURCE)

$(DL_DIR)/$(PCIIDS_SOURCE):
	$(WGET) -P $(DL_DIR) $(PCIIDS_SITE)/$(PCIIDS_SOURCE)

$(PCIUTILS_DIR)/.unpacked: $(DL_DIR)/$(PCIUTILS_SOURCE) $(DL_DIR)/$(PCIIDS_SOURCE)
	$(PCIUTILS_CAT) $(DL_DIR)/$(PCIUTILS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PCIIDS_CAT) $(DL_DIR)/$(PCIIDS_SOURCE) > $(PCIUTILS_DIR)/$(PCIIDS_FILE)
	toolchain/patch-kernel.sh $(PCIUTILS_DIR) package/pciutils pciutils-$(PCIUTILS_VERSION)\*.patch
	#$(CONFIG_UPDATE) $(@D)
	$(SED) 's/uname -s/echo Linux/' \
		-e 's/uname -r/echo $(LINUX_HEADERS_VERSION)/' \
		$(PCIUTILS_DIR)/lib/configure
	touch $@

$(PCIUTILS_DIR)/.compiled: $(PCIUTILS_DIR)/.unpacked $(if $(BR2_PACKAGE_ZLIB),zlib)
	$(MAKE) -C $(PCIUTILS_DIR) clean
	$(MAKE) CC="$(TARGET_CC)" OPT="$(TARGET_CFLAGS)" -C $(PCIUTILS_DIR) \
		SHAREDIR="/usr/share/misc" \
		ZLIB=$(PCIUTILS_HAVE_ZLIB) \
		SHARED=$(PCIUTILS_HAVE_SO) \
		PREFIX=/usr
	touch $@

$(PCIUTILS_DIR)/lib/libpci.a: $(PCIUTILS_DIR)/.unpacked $(if $(BR2_PACKAGE_ZLIB),zlib)
	$(MAKE) -C $(PCIUTILS_DIR) clean
	$(MAKE) CC="$(TARGET_CC)" OPT="$(TARGET_CFLAGS)" -C $(PCIUTILS_DIR) \
		SHAREDIR="/usr/share/misc" \
		ZLIB=$(PCIUTILS_HAVE_ZLIB) \
		SHARED=no \
		PREFIX=/usr
	touch -c $@

$(TARGET_DIR)/usr/lib/libpci.a: $(PCIUTILS_DIR)/lib/libpci.a
	$(INSTALL) -D -m0644 $< $@
	$(INSTALL) -d $(TARGET_DIR)/usr/include/pci
	$(INSTALL) -m0644 $(addprefix $(PCIUTILS_DIR)/lib/,config.h header.h pci.h types.h ) $(TARGET_DIR)/usr/include/pci/
	touch -c $@

$(TARGET_DIR)/sbin/lspci: $(PCIUTILS_DIR)/.compiled
	$(INSTALL) -D -m0755 $(PCIUTILS_DIR)/lspci $(TARGET_DIR)/sbin/lspci
ifeq ($(BR2_ENABLE_SHARED),y)
	$(INSTALL) -D -m0755 $(PCIUTILS_DIR)/lib/$(LIB_PCI).$(PCIUTILS_VERSION) $(TARGET_DIR)/usr/lib/$(LIB_PCI).$(PCIUTILS_VERSION)
	ln -sf $(LIB_PCI).$(PCIUTILS_VERSION) $(TARGET_DIR)/usr/lib/$(LIB_PCI)$(LIB_PCI_ABIVERSION)
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/$(LIB_PCI).$(PCIUTILS_VERSION)
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

$(TARGET_DIR)/sbin/setpci: $(PCIUTILS_DIR)/.compiled
	$(INSTALL) -D -m0755 $(PCIUTILS_DIR)/setpci $(TARGET_DIR)/sbin/setpci
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

$(TARGET_DIR)/usr/share/misc/$(PCIIDS_FILE): $(PCIUTILS_DIR)/.unpacked
	$(INSTALL) -D $(PCIUTILS_DIR)/$(PCIIDS_FILE) $(@D)

pciutils: uclibc $(TARGET_DIR)/sbin/setpci $(TARGET_DIR)/sbin/lspci $(TARGET_DIR)/usr/share/misc/$(PCIIDS_FILE)
pciutils-headers: $(TARGET_DIR)/usr/lib/libpci.a

pciutils-source: $(DL_DIR)/$(PCIUTILS_SOURCE) $(DL_DIR)/$(PCIIDS_SOURCE)

pciutils-clean:
	-$(MAKE) -C $(PCIUTILS_DIR) clean
	rm -f $(TARGET_DIR)/sbin/lspci $(TARGET_DIR)/sbin/setpci \
	    $(TARGET_DIR)/usr/share/misc/pci.ids* \
	    $(TARGET_DIR)/usr/lib/$(LIB_PCI)*

pciutils-dirclean:
	rm -rf $(PCIUTILS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_PCIUTILS)$(BR2_HAVE_INCLUDES),yy)
TARGETS+=pciutils-headers
endif
ifeq ($(BR2_PACKAGE_PCIUTILS),y)
TARGETS+=pciutils
endif
