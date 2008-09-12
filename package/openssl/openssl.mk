#############################################################
#
# openssl
#
#############################################################

# TARGETS
OPENSSL_VERSION:=0.9.8h
OPENSSL_SITE:=http://www.openssl.org/source
OPENSSL_SOURCE:=openssl-$(OPENSSL_VERSION).tar.gz
OPENSSL_CAT:=$(ZCAT)
OPENSSL_DIR:=$(BUILD_DIR)/openssl-$(OPENSSL_VERSION)

#Usage: Configure [no-<cipher> ...] [enable-<cipher> ...] [-Dxxx] [-lxxx] [-Lxxx] [-fxxx] [-Kxxx] [no-hw-xxx|no-hw] [[no-]threads] [[no-]shared] [[no-]zlib|zlib-dynamic] [enable-montasm] [no-asm] [no-dso] [no-krb5] [386] [--prefix=DIR] [--openssldir=OPENSSLDIR] [--with-xxx[=vvv]] [--test-sanity] os/compiler[:flags]

OPENSSL_TARGET_ARCH:=
ifeq ($(BR2_i386),y)
ifneq ($(ARCH),i386)
OPENSSL_TARGET_ARCH:=i386-$(ARCH)
OPENSSL_TARGET_ARCH:=generic32
endif
ifeq ($(ARCH),i686)
OPENSSL_TARGET_ARCH:=i386-i686/cmov
OPENSSL_TARGET_ARCH:=elf
endif
endif

ifeq ($(BR2_alpha),y)
OPENSSL_TARGET_ARCH:=linux-alpha-gcc
endif

ifeq ($(OPENSSL_TARGET_ARCH),)
OPENSSL_TARGET_ARCH:=$(ARCH)
endif

OPENSSL_CFLAGS:= -DTERMIO
OPENSSL_CFLAGS+=-DOPENSSL_NO_KRB5 -DOPENSSL_NO_IDEA -DOPENSSL_NO_MDC2 -DOPENSSL_NO_RC5 
ifeq ($(BR2_PTHREADS_NONE),y)
OPENSSL_THREADS=no-threads
else
OPENSSL_THREADS=threads
OPENSSL_CFLAGS+=-D_REENTRANT
endif

ifeq ($(BR2_ENDIAN),"BIG")
OPENSSL_CFLAGS+=-DB_ENDIAN
else
OPENSSL_CFLAGS+=-DL_ENDIAN
endif

$(DL_DIR)/$(OPENSSL_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENSSL_SITE)/$(OPENSSL_SOURCE)

openssl-unpack: $(OPENSSL_DIR)/.unpacked
$(OPENSSL_DIR)/.unpacked: $(DL_DIR)/$(OPENSSL_SOURCE)
	$(OPENSSL_CAT) $(DL_DIR)/$(OPENSSL_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(OPENSSL_DIR) package/openssl/ openssl-$(OPENSSL_VERSION)\*.patch
	# sigh... hit perl script with a clue bait
	# grumble.. and of course make sure to escape any '/' in CFLAGS
	$(SED) 's,/CFLAG=,/CFLAG= $(TARGET_SOFT_FLOAT) ,g' \
		$(OPENSSL_DIR)/Configure
	$(SED) '/CFLAG=/s,/;, $(shell echo '$(TARGET_CFLAGS) $(OPENSSL_CFLAGS)' | sed -e 's/\//\\\\\//g')/;,' \
		$(OPENSSL_DIR)/Configure
	$(SED) '/linux-uclibc/s,gcc:,$(TARGET_CC) $(TARGET_CFLAGS):,' \
		-e '/linux-uclibc/s,:ranlib:,:$(TARGET_RANLIB):,' \
		-e '/linux-uclibc/s,:-ldl:,:$(TARGET_LDFLAGS) -ldl -lz:,' \
		$(OPENSSL_DIR)/Configure
	touch $@

$(OPENSSL_DIR)/Makefile: $(OPENSSL_DIR)/.unpacked
	(cd $(OPENSSL_DIR); \
	CFLAGS="$(TARGET_CFLAGS) $(OPENSSL_CFLAGS)" \
	RANLIB="$(TARGET_RANLIB)" \
	PATH=$(TARGET_PATH) \
	./Configure linux-uclibc --prefix=/ --openssldir=/lib/ssl \
		-L$(STAGING_DIR)/usr/lib -ldl \
		-I$(STAGING_DIR)/usr/include \
		$(OPENSSL_OPTS) \
		$(OPENSSL_THREADS) \
		shared no-idea no-mdc2 no-rc5)

$(OPENSSL_DIR)/apps/openssl: $(OPENSSL_DIR)/Makefile
	$(MAKE1) -C $(OPENSSL_DIR) all build-shared
	# Work around openssl build bug to link libssl.so with libcrypto.so.
	-rm $(OPENSSL_DIR)/libssl.so.*.*.*
	$(MAKE1) -C $(OPENSSL_DIR) do_linux-shared

$(STAGING_DIR)/usr/lib/libcrypto.a: $(OPENSSL_DIR)/apps/openssl
	$(MAKE1) INSTALL_PREFIX="$(STAGING_DIR)/usr" \
		INSTALLTOP=/ ENGINESDIR=/lib/ssl/engines \
		-C $(OPENSSL_DIR) install
	cp -dpf $(OPENSSL_DIR)/libcrypto.so* $(STAGING_DIR)/usr/lib/
	chmod a-x $(STAGING_DIR)/usr/lib/libcrypto.so.0.9.8
	(cd $(STAGING_DIR)/usr/lib; \
	 ln -fs libcrypto.so.0.9.8 libcrypto.so; \
	 ln -fs libcrypto.so.0.9.8 libcrypto.so.0; \
	)
	cp -dpf $(OPENSSL_DIR)/libssl.so* $(STAGING_DIR)/usr/lib/
	chmod a-x $(STAGING_DIR)/usr/lib/libssl.so.0.9.8
	(cd $(STAGING_DIR)/usr/lib; \
	 ln -fs libssl.so.0.9.8 libssl.so; \
	 ln -fs libssl.so.0.9.8 libssl.so.0; \
	)
	touch -c $@

$(TARGET_DIR)/usr/lib/libcrypto.so.0.9.8: $(STAGING_DIR)/usr/lib/libcrypto.a
	$(INSTALL) -d $(@D)
	$(INSTALL) -m 0755 -t $(@D) $(STAGING_DIR)/usr/lib/libcrypto.so*
	$(INSTALL) -m 0755 -t $(@D) $(STAGING_DIR)/usr/lib/libssl.so*
	#cp -fa $(STAGING_DIR)/bin/openssl $(TARGET_DIR)/bin/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libssl.so.0.9.8
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libcrypto.so.0.9.8

$(TARGET_DIR)/usr/lib/libssl.a: $(STAGING_DIR)/usr/lib/libcrypto.a
ifneq ($(BR2_HAVE_HEADERS),y)
	$(INSTALL) -d $(TARGET_DIR)/usr/include
	cp -rpfR $(STAGING_DIR)/usr/include/openssl $(TARGET_DIR)/usr/include/
endif
	$(INSTALL) -D -m 0644 $(STAGING_DIR)/usr/lib/libssl.a $@
	$(INSTALL) -m 0644 $(STAGING_DIR)/usr/lib/libcrypto.a $(TARGET_DIR)/usr/lib/libcrypto.a
	touch -c $@

openssl-headers: $(TARGET_DIR)/usr/lib/libssl.a

openssl: uclibc $(TARGET_DIR)/usr/lib/libcrypto.so.0.9.8

openssl-source: $(DL_DIR)/$(OPENSSL_SOURCE)

openssl-clean:
	-$(MAKE) -C $(OPENSSL_DIR) clean
	rm -f $(STAGING_DIR)/usr/bin/openssl $(TARGET_DIR)/usr/bin/openssl
	rm -f $(STAGING_DIR)/usr/lib/libcrypto.* $(TARGET_DIR)/usr/lib/libcrypto.*
	rm -f $(STAGING_DIR)/usr/lib/libssl.* $(TARGET_DIR)/usr/lib/libssl.*
	rm -rf $(STAGING_DIR)/usr/include/openssl $(TARGET_DIR)/usr/include/openssl
	rm -rf $(STAGING_DIR)/usr/lib/ssl $(TARGET_DIR)/usr/lib/ssl
	rm -f $(STAGING_DIR)/usr/lib/pkgconfig/libssl.pc \
		$(STAGING_DIR)/usr/lib/pkgconfig/openssl.pc \
		$(STAGING_DIR)/usr/lib/pkgconfig/libcrypto.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libssl.pc \
		$(TARGET_DIR)/usr/lib/pkgconfig/openssl.pc \
		$(TARGET_DIR)/usr/lib/pkgconfig/libcrypto.pc \
		$(TARGET_DIR)/usr/include/openssl

openssl-dirclean:
	rm -rf $(OPENSSL_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_OPENSSL),y)
TARGETS+=openssl
endif
ifeq ($(BR2_PACKAGE_OPENSSL_TARGET_HEADERS),y)
TARGETS+=openssl-headers
endif
