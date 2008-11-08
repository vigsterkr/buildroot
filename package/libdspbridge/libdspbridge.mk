#############################################################
#
# libdspbridge
#
#############################################################
LIBDSP_VERSION:=git
LIBDSP_SOURCE:=libdspbridge-$(LIBDSP_VERSION).tar.bz2
LIBDSP_SITE:=$(BR2_GNU_MIRROR)/libdspbridge
LIBDSP_CAT:=$(BZCAT)
LIBDSP_SRC_DIR:=$(TOOL_BUILD_DIR)/libdspbridge-$(LIBDSP_VERSION)
LIBDSP_DIR:=$(BUILD_DIR)/libdspbridge-$(LIBDSP_VERSION)
#LIBDSP_BINARY:=libdspbridge
#LIBDSP_TARGET_BINARY:=usr/lib/libdspbridge.so

$(DL_DIR)/$(LIBDSP_SOURCE):
ifeq ($(LIBDSP_VERSION),git)
	$(GIT) clone git://github.com/felipec/libdspbridge.git $(LIBDSP_SRC_DIR)
	(cd $(TOOL_BUILD_DIR)/libdspbridge-$(LIBDSP_VERSION) && \
	 cd $(TOOL_BUILD_DIR) && \
	 tar -cjf $@ libdspbridge-$(LIBDSP_VERSION) && \
	 rm -rf $(LIBDSP_SRC_DIR) \
	)
else
	$(WGET) -P $(DL_DIR) $(LIBDSP_SITE)/$(LIBDSP_SOURCE)
endif

$(LIBDSP_DIR)/.unpacked: $(DL_DIR)/$(LIBDSP_SOURCE)
	$(LIBDSP_CAT) $(DL_DIR)/$(LIBDSP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

#############################################################
#
# libdspbridge for the target
#
#############################################################

$(LIBDSP_DIR)/.patched: $(LIBDSP_DIR)/.unpacked
	toolchain/patch-kernel.sh $(LIBDSP_DIR) package/libdspbridge/ libdspbridge-$(LIBDSPBRIDGE_VERSION)\*.patch
	# not an autoconf package: $(CONFIG_UPDATE) $(@D)
	touch $@

$(LIBDSP_DIR)/libbridge.so.$(LIBDSP_VERSION): $(LIBDSP_DIR)/.patched
	$(MAKE) -C $(LIBDSP_DIR) CC=$(TARGET_CC) AR=$(TARGET_AR) all
	touch -c $(LIBDSP_DIR)/libbridge.so.$(LIBDS_VERSION)

$(STAGING_DIR)/usr/lib/libbridge.so.$(LIBDSP_VERSION): $(LIBDSP_DIR)/libbridge.so.$(LIBDSP_VERSION)
	$(INSTALL) -D $(LIBDSP_DIR)/libbridge.a $(STAGING_DIR)/usr/lib/libbridge.a
	$(INSTALL) -m0755 $(LIBDSP_DIR)/libbridge.so* $(STAGING_DIR)/usr/lib
	ln -sf libbridge.so $(STAGING_DIR)/usr/lib/libbridge.so.2
	touch -c $@

$(TARGET_DIR)/usr/lib/libbridge.so.$(LIBDSP_VERSION): $(STAGING_DIR)/usr/lib/libbridge.so.$(LIBDSP_VERSION)
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	$(INSTALL) -m0755 $(STAGING_DIR)/usr/lib/libbridge.so* $(TARGET_DIR)/usr/lib
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libbridge.so*
	touch -c $@

$(TARGET_DIR)/usr/lib/libbridge.a: $(STAGING_DIR)/usr/lib/libbridge.so.$(LIBDSP_VERSION)
	$(INSTALL) $(STAGING_DIR)/usr/lib/libbridge.a $(TARGET_DIR)/usr/lib/
	rm -f $(TARGET_DIR)/lib/libbridge.so* $(TARGET_DIR)/usr/lib/libbridge.so
	ln -sf libbridge.so.$(LIBDSP_VERSION) $(TARGET_DIR)/usr/lib/libbridge.so
	touch -c $@

libdspbridge: uclibc $(TARGET_DIR)/usr/lib/libbridge.so.$(LIBDSP_VERSION)

libdspbridge-source: $(DL_DIR)/$(LIBDSP_SOURCE)

libdspbridge-clean:
	rm -f $(TARGET_DIR)/usr/lib/libbridge.* \
	      $(STAGING_DIR)/usr/lib/libbridge.*
	-$(MAKE) -C $(LIBDSP_DIR) clean

libdspbridge-dirclean:
	rm -rf $(LIBDSP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBDSPBRIDGE),y)
TARGETS+=libdspbridge
endif
