#############################################################
#
# argus
#
#############################################################
ARGUS_VERSION:=3.0.0.rc.34
ARGUS_VERSION:=2.0.6.fixes.1
ARGUS_SOURCE:=argus_$(ARGUS_VERSION).orig.tar.gz
ARGUS_PATCH:=argus_$(ARGUS_VERSION)-1.diff.gz
ARGUS_PATCH:=argus_$(ARGUS_VERSION)-13.diff.gz
ARGUS_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/a/argus/
ARGUS_DIR:=$(BUILD_DIR)/argus-$(ARGUS_VERSION)
ARGUS_CAT:=$(ZCAT)
ARGUS_BINARY:=bin/argus
ARGUS_TARGET_BINARY:=usr/sbin/argus

$(DL_DIR)/$(ARGUS_SOURCE):
	$(WGET) -P $(DL_DIR) $(ARGUS_SITE)/$(ARGUS_SOURCE)

$(DL_DIR)/$(ARGUS_PATCH):
	$(WGET) -P $(DL_DIR) $(ARGUS_SITE)/$(ARGUS_PATCH)

$(ARGUS_DIR)/.unpacked: $(DL_DIR)/$(ARGUS_SOURCE) $(DL_DIR)/$(ARGUS_PATCH)
	$(ARGUS_CAT) $(DL_DIR)/$(ARGUS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(ARGUS_DIR) package/argus/ argus-$(ARGUS_VERSION)\*.patch
ifneq ($(ARGUS_PATCH),)
	(cd $(ARGUS_DIR) && $(ARGUS_CAT) $(DL_DIR)/$(ARGUS_PATCH) | patch -p1)
	if [ -d $(ARGUS_DIR)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(ARGUS_DIR) $(ARGUS_DIR)/debian/patches \*.patch; \
	fi
endif
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(ARGUS_DIR)/.configured: $(ARGUS_DIR)/.unpacked
	(cd $(ARGUS_DIR); rm -rf config.cache; \
		ac_cv_prog_V_LEX=flex \
		ac_cv_lbl_flex_v24=yes \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		$(DISABLE_LARGEFILE) \
		--with-pcap=linux \
	)
	touch $@

$(ARGUS_DIR)/$(ARGUS_BINARY): $(ARGUS_DIR)/.configured
	$(MAKE) -C $(ARGUS_DIR)

$(TARGET_DIR)/$(ARGUS_TARGET_BINARY): $(ARGUS_DIR)/$(ARGUS_BINARY)
	$(INSTALL) -D $(ARGUS_DIR)/$(ARGUS_BINARY) $@
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

argus: uclibc libpcap $(TARGET_DIR)/$(ARGUS_TARGET_BINARY)

argus-source: $(DL_DIR)/$(ARGUS_SOURCE) $(DL_DIR)/$(ARGUS_PATCH)

argus-clean:
	-$(MAKE) -C $(ARGUS_DIR) clean
	rm -f $(TARGET_DIR)/$(ARGUS_TARGET_BINARY)

argus-dirclean:
	rm -rf $(ARGUS_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_ARGUS),y)
TARGETS+=argus
endif
