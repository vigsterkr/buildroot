#############################################################
#
# xerces
#
#############################################################
XERCES_VERSION:=2.8.0
XERCES_VER:=$(subst .,_,$(XERCES_VERSION))
XERCES_SOVER:=.28.0
XERCES_SOURCE:=xerces-c-src_$(XERCES_VER).tar.gz
XERCES_SITE:=http://www.apache.org/dist/xml/xerces-c/sources/
XERCES_CAT:=$(ZCAT)
XERCES_DIR:=$(BUILD_DIR)/xerces-c-src_$(XERCES_VER)
XERCES_BINARY:=lib/libxerces-c.so$(XERCES_SOVER)

$(DL_DIR)/$(XERCES_SOURCE):
	 $(WGET) -P $(DL_DIR) $(XERCES_SITE)/$(XERCES_SOURCE)

$(XERCES_DIR)/.unpacked: $(DL_DIR)/$(XERCES_SOURCE)
	$(XERCES_CAT) $(DL_DIR)/$(XERCES_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	#toolchain/patch-kernel.sh $(XERCES_DIR) package/xerces/ \*.patch*
	touch $@

$(XERCES_DIR)/.configured: $(XERCES_DIR)/.unpacked
	(cd $(XERCES_DIR)/src/xercesc; rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		XERCESCROOT=$(XERCES_DIR) \
		./runConfigure -plinux -minmem \
		-nsocket -tnative -rpthread \
		-x$(TARGET_CXX) \
		-c$(TARGET_CC) \
		-C$(TARGET_CONFIGURE_ARGS) \
	)
	touch $@

$(XERCES_DIR)/$(XERCES_BINARY): $(XERCES_DIR)/.configured
	$(MAKE) XERCESCROOT=$(XERCES_DIR) -C $(XERCES_DIR)/src/xercesc
	touch -c $@

$(STAGING_DIR)/$(XERCES_BINARY): $(XERCES_DIR)/$(XERCES_BINARY)
	$(MAKE) XERCESCROOT=$(XERCES_DIR) PREFIX=$(STAGING_DIR) \
		-C $(XERCES_DIR)/src/xercesc install
	touch -c $@

$(TARGET_DIR)/usr/$(XERCES_BINARY): $(STAGING_DIR)/$(XERCES_BINARY)
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	$(INSTALL) -m 0755 $(STAGING_DIR)/lib/libxerces-c.so* \
		$(STAGING_DIR)/lib/libxerces-depdom.so* $(TARGET_DIR)/usr/lib/
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libxerces-c.so$(XERCES_SOVER)
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libxerces-depdom.so$(XERCES_SOVER)

xerces: uclibc $(TARGET_DIR)/usr/$(XERCES_BINARY)

xerces-source: $(DL_DIR)/$(XERCES_SOURCE)

xerces-clean:
	-$(MAKE) -C $(XERCES_DIR) clean
	rm -rf $(STAGING_DIR)/usr/include/xercesc
	rm -f $(STAGING_DIR)/lib/libxerces* \
		$(TARGET_DIR)/usr/lib/libxerces*

xerces-dirclean:
	rm -rf $(XERCES_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_XERCES),y)
TARGETS+=xerces
endif
