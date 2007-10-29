#############################################################
#
# mini lzo
#
#############################################################
ifeq ($(BR2_PACKAGE_LZO_MINI),y)
LZO_MINI_VERSION:=2.02
LZO_MINI_SOURCE:=minilzo-$(LZO_MINI_VERSION).tar.gz
LZO_MINI_SITE:=http://www.oberhumer.com/opensource/lzo/download/
#LZO_MINI_SOURCE:=lzo_mini-$(LZO_MINI_VERSION).tar.bz2
#LZO_MINI_SITE:=http://www.oberhumer.com/opensource/lzo_mini/download
LZO_MINI_DIR:=$(BUILD_DIR)/minilzo.202
LZO_MINI_CAT:=$(ZCAT)

$(DL_DIR)/$(LZO_MINI_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LZO_MINI_SITE)/$(LZO_MINI_SOURCE)

$(LZO_MINI_DIR)/.unpacked: $(DL_DIR)/$(LZO_MINI_SOURCE)
	$(LZO_MINI_CAT) $(DL_DIR)/$(LZO_MINI_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LZO_MINI_DIR) package/lzo_mini/ lzo_mini\*.patch
	touch $@

ifeq ($(BR2_PACKAGE_LZO_MINI_TARGET),y)
LZO_MINI_CONFIG_SHARED:=--enable-shared
else
LZO_MINI_CONFIG_SHARED:=--disable-shared
endif

$(LZO_MINI_DIR)/.configured: $(LZO_MINI_DIR)/.unpacked
	$(SED) 's|[[:space:]]*GCC_CFLAGS[[:space:]:]*=.*|GCC_CFLAGS=$(TARGET_CFLAGS)|' $(LZO_MINI_DIR)/Makefile
	touch $@

$(LZO_MINI_DIR)/liblzo.so $(LZO_MINI_DIR)/liblzo.a: $(LZO_MINI_DIR)/.configured
	(cd $(LZO_MINI_DIR) && \
	 $(TARGET_CC) $(TARGET_CFLAGS) \
	 	-shared -o liblzo.so minilzo.c && \
	 $(TARGET_CC) $(TARGET_CFLAGS) \
	 	-c -o minilzo.o minilzo.c && \
	 $(TARGET_AR) $(TARGET_AR_FLAGS) cr liblzo.a minilzo.o \
	)
	touch $@

$(STAGING_DIR)/usr/lib/liblzo.a: $(LZO_MINI_DIR)/liblzo.a
	$(INSTALL) -D $< $@
	$(INSTALL) -d $(STAGING_DIR)/usr/include
	$(INSTALL) $(LZO_MINI_DIR)/lzoconf.h $(LZO_MINI_DIR)/lzodefs.h \
		$(STAGING_DIR)/usr/include
	$(INSTALL) $(LZO_MINI_DIR)/minilzo.h $(STAGING_DIR)/usr/include/lzo1x.h
	touch -c $@

$(TARGET_DIR)/usr/lib/liblzo.so: $(LZO_MINI_DIR)/liblzo.so
	$(INSTALL) -D $< $@
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

lzo lzo_mini: uclibc $(STAGING_DIR)/usr/lib/liblzo.a

lzo_mini-source: $(DL_DIR)/$(LZO_MINI_SOURCE)

lzo_mini-clean:
	-$(MAKE) -C $(LZO_MINI_DIR) clean
	rm -f $(STAGING_DIR)/usr/lib/liblzo.a $(STAGING_DIR)/usr/lib/liblzo.la \
		$(STAGING_DIR)/usr/lib/liblzo.so* \
		$(STAGING_DIR)/usr/include/lzo1x.h \
		$(STAGING_DIR)/usr/include/lzoconf.h \
		$(STAGING_DIR)/usr/include/lzodefs.h

lzo_mini-dirclean:
	rm -rf $(LZO_MINI_DIR)

lzo_mini-target: uclibc $(TARGET_DIR)/usr/lib/liblzo.so
lzo_mini-target-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(LZO_MINI_DIR) uninstall
	-$(MAKE) -C $(LZO_MINI_DIR) clean
	rm -f $(TARGET_DIR)/usr/lib/liblzo*so* $(TARGET_DIR)/usr/lib/liblzo.a

lzo_mini-target-dirclean:
	rm -rf $(LZO_MINI_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LZO_MINI_TARGET),y)
TARGETS+=lzo_mini-target
endif

TARGETS+=lzo_mini
endif
