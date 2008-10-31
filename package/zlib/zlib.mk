#############################################################
#
# zlib
#
#############################################################
ZLIB_VERSION:=1.2.3
ZLIB_SOURCE:=zlib-$(ZLIB_VERSION).tar.bz2
ZLIB_CAT:=$(BZCAT)
ZLIB_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/libpng
ZLIB_DIR:=$(BUILD_DIR)/zlib-$(ZLIB_VERSION)

ZLIB_CFLAGS=$(TARGET_CFLAGS) -UDEBUG -DNDEBUG
#ifeq ($(BR2_USE_MMU),y)
#ZLIB_CFLAGS+= -DUSE_MMAP
#endif
ifeq ($(BR2_ENABLE_SHARED),y)
ZLIB_CFLAGS+=-fPIC -DPIC
endif
ifeq ($(BR2_LARGEFILE),y)
ZLIB_CFLAGS+=-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64
endif

ifeq ($(BR2_x86_i586),y)
ZLIB_ASM_FILE=cp -dpf $(ZLIB_DIR)/contrib/asm586/match.S $(ZLIB_DIR)/
endif
# pentium pro capabable:
ifeq ($(BR2_i386),y)
ifneq ($(findstring y,$(BR2_x86_i386)$(BR2_x86_i486)$(BR2_x86_i586)$(BR2_x86_geode)$(BR2_x86_c3)$(BR2_x86_winchip_c6)$(BR2_x86_winchip2)),y)
ZLIB_ASM_FILE=cp -dpf $(ZLIB_DIR)/contrib/asm686/match.S $(ZLIB_DIR)/
endif
endif
ifneq ($(ZLIB_ASM_FILE),)
ZLIB_CFLAGS+=-DASMV -DNO_UNDERLINE
ZLIB_OBJA:=match.o
endif

$(DL_DIR)/$(ZLIB_SOURCE):
	$(WGET) -P $(DL_DIR) $(ZLIB_SITE)/$(ZLIB_SOURCE)

$(ZLIB_DIR)/.patched: $(DL_DIR)/$(ZLIB_SOURCE)
	$(ZLIB_CAT) $(DL_DIR)/$(ZLIB_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(ZLIB_DIR) package/zlib/ zlib-$(ZLIB_VERSION)\*.patch
	# not an autoconf package: $(CONFIG_UPDATE) $(@D)
	touch $@

$(ZLIB_DIR)/.configured: $(ZLIB_DIR)/.patched
	# not an autoconf package:
	(cd $(ZLIB_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_ARGS) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) $(ZLIB_CFLAGS)" \
		./configure \
		$(if $(BR2_ENABLE_SHARED),--shared) \
		--prefix=/usr \
		--exec-prefix=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
	)
	touch $@

$(ZLIB_DIR)/libz.so.$(ZLIB_VERSION): $(ZLIB_DIR)/.configured
	$(ZLIB_ASM_FILE)
	$(MAKE) $(if $(ZLIB_OBJA),OBJA=$(ZLIB_OBJA)) -C $(ZLIB_DIR) $(ZLIB_OBJA) all libz.a
	touch -c $(ZLIB_DIR)/libz.so.$(ZLIB_VERSION)

$(STAGING_DIR)/usr/lib/libz.so.$(ZLIB_VERSION): $(ZLIB_DIR)/libz.so.$(ZLIB_VERSION)
	$(INSTALL) -D $(ZLIB_DIR)/libz.a $(STAGING_DIR)/usr/lib/libz.a
	$(INSTALL) -D $(ZLIB_DIR)/zlib.h $(STAGING_DIR)/usr/include/zlib.h
	$(INSTALL) $(ZLIB_DIR)/zconf.h $(STAGING_DIR)/usr/include/zconf.h
	$(INSTALL) -m0755 $(ZLIB_DIR)/libz.so* $(STAGING_DIR)/usr/lib
	ln -sf libz.so.$(ZLIB_VERSION) $(STAGING_DIR)/usr/lib/libz.so.1
	touch -c $@

$(TARGET_DIR)/usr/lib/libz.so.$(ZLIB_VERSION): $(STAGING_DIR)/usr/lib/libz.so.$(ZLIB_VERSION)
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	$(INSTALL) -m0755 $(STAGING_DIR)/usr/lib/libz.so* $(TARGET_DIR)/usr/lib
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libz.so*
	touch -c $@

$(TARGET_DIR)/usr/lib/libz.a: $(STAGING_DIR)/usr/lib/libz.so.$(ZLIB_VERSION)
	$(INSTALL) -d $(TARGET_DIR)/usr/include $(TARGET_DIR)/usr/lib
	$(INSTALL) $(STAGING_DIR)/usr/include/zlib.h \
		  $(STAGING_DIR)/usr/include/zconf.h $(TARGET_DIR)/usr/include/
	$(INSTALL) $(STAGING_DIR)/usr/lib/libz.a $(TARGET_DIR)/usr/lib/
	rm -f $(TARGET_DIR)/lib/libz.so* $(TARGET_DIR)/usr/lib/libz.so
	ln -sf libz.so.$(ZLIB_VERSION) $(TARGET_DIR)/usr/lib/libz.so
	touch -c $@

zlib-headers: $(TARGET_DIR)/usr/lib/libz.a

zlib: uclibc $(TARGET_DIR)/usr/lib/libz.so.$(ZLIB_VERSION)

zlib-source: $(DL_DIR)/$(ZLIB_SOURCE)

zlib-clean:
	rm -f $(TARGET_DIR)/usr/lib/libz.* \
		$(TARGET_DIR)/usr/include/zlib.h \
		$(TARGET_DIR)/usr/include/zconf.h \
		$(STAGING_DIR)/usr/include/zlib.h \
		$(STAGING_DIR)/usr/include/zconf.h \
		$(STAGING_DIR)/usr/lib/libz.*
	-$(MAKE) -C $(ZLIB_DIR) clean

zlib-dirclean:
	rm -rf $(ZLIB_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_ZLIB),y)
TARGETS+=zlib
endif
ifeq ($(findstring y,$(BR2_PACKAGE_ZLIB_TARGET_HEADERS)$(BR2_HAVE_INCLUDES)),y)
TARGETS+=zlib-headers
endif
