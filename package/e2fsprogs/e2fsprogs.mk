#############################################################
#
# e2fsprogs
#
#############################################################
#E2FSPROGS_VERSION:=1.39
E2FSPROGS_VERSION:=1.41.3
E2FSPROGS_SOURCE=e2fsprogs-$(E2FSPROGS_VERSION).tar.gz
E2FSPROGS_SITE=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/e2fsprogs
E2FSPROGS_DIR=$(BUILD_DIR)/e2fsprogs-$(E2FSPROGS_VERSION)
E2FSPROGS_CAT:=$(ZCAT)
E2FSPROGS_BINARY:=misc/mke2fs
E2FSPROGS_TARGET_BINARY:=sbin/mke2fs

E2FSPROGS_MISC_STRIP:= \
	badblocks blkid chattr dumpe2fs filefrag fsck logsave \
	lsattr mke2fs mklost+found tune2fs uuidgen

$(DL_DIR)/$(E2FSPROGS_SOURCE):
	 $(WGET) -P $(DL_DIR) $(E2FSPROGS_SITE)/$(E2FSPROGS_SOURCE)

e2fsprogs-source: $(DL_DIR)/$(E2FSPROGS_SOURCE)

$(E2FSPROGS_DIR)/.unpacked: $(DL_DIR)/$(E2FSPROGS_SOURCE)
	$(E2FSPROGS_CAT) $(DL_DIR)/$(E2FSPROGS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(E2FSPROGS_DIR) package/e2fsprogs/ e2fsprogs\*.patch
	$(CONFIG_UPDATE) $(E2FSPROGS_DIR)/config
	touch $@

$(E2FSPROGS_DIR)/.configured: $(E2FSPROGS_DIR)/.unpacked
	(cd $(E2FSPROGS_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--with-cc=$(TARGET_CC) \
		--with-linker=$(TARGET_LD) \
		--with-gnu-ld \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/bin \
		--sbindir=/sbin \
		--libdir=/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--enable-elf-shlibs \
		--enable-dynamic-e2fsck \
		--disable-swapfs \
		--disable-debugfs \
		--disable-profile \
		--disable-jbd-debug \
		--disable-blkid-debug \
		--disable-testio-debug \
		--disable-imager \
		--disable-resizer \
		--disable-e2initrd-helper \
		--enable-fsck \
		--without-catgets \
		$(if $(BR2__UCLIBC_HAVE_TLS),--enable-tls,--disable-tls) \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	# do away with unconditionally hiding the commands
	#find $(E2FSPROGS_DIR) -name "Makefile*" \
	#	| xargs $(SED) '/^	@/s/@/$$\(Q\)/'
	touch $@

$(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY): $(E2FSPROGS_DIR)/.configured
	$(MAKE) -C $(E2FSPROGS_DIR)
	(cd $(E2FSPROGS_DIR)/misc; \
		$(STRIPCMD) $(E2FSPROGS_MISC_STRIP); \
	)
	#$(STRIPCMD) $(E2FSPROGS_DIR)/lib/lib*.so.*.*
	touch -c $@

$(STAGING_DIR)/lib/libext2fs.a: $(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(STAGING_DIR) LDCONFIG=true \
		-C $(E2FSPROGS_DIR) install
	$(INSTALL) -m0644 $(E2FSPROGS_DIR)/lib/*.a $(STAGING_DIR)/lib/
	#$(INSTALL) -D -m0755 $(STAGING_DIR)/lib/libext2fs.so $@
	#$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

$(TARGET_DIR)/$(E2FSPROGS_TARGET_BINARY): $(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(TARGET_DIR) LDCONFIG=true \
		-C $(E2FSPROGS_DIR) install
	rm -rf ${TARGET_DIR}/sbin/mkfs.ext[23] \
		${TARGET_DIR}/sbin/fsck.ext[23] \
		${TARGET_DIR}/sbin/findfs \
		${TARGET_DIR}/sbin/tune2fs
	ln -sf mke2fs ${TARGET_DIR}/sbin/mkfs.ext2
	ln -sf mke2fs ${TARGET_DIR}/sbin/mkfs.ext3
	ln -sf e2fsck ${TARGET_DIR}/sbin/fsck.ext2
	ln -sf e2fsck ${TARGET_DIR}/sbin/fsck.ext3
	ln -sf e2label ${TARGET_DIR}/sbin/tune2fs
	ln -sf e2label ${TARGET_DIR}/sbin/findfs
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	touch -c $@

e2fsprogs-libs: $(STAGING_DIR)/lib/libext2fs.a
e2fsprogs: uclibc $(TARGET_DIR)/$(E2FSPROGS_TARGET_BINARY)

e2fsprogs-clean e2fsprogs-libs-clean:
	$(MAKE1) DESTDIR=$(STAGING_DIR) -C $(E2FSPROGS_DIR) uninstall
	$(MAKE1) DESTDIR=$(TARGET_DIR) -C $(E2FSPROGS_DIR) uninstall
	-$(MAKE1) -C $(E2FSPROGS_DIR) clean
	rm -f $(addprefix $(STAGING_DIR)/lib/lib,ext2fs.a e2p.a uuid.a blkid.a)

e2fsprogs-dirclean e2fsprogs-libs-dirclean:
	rm -rf $(E2FSPROGS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_E2FSPROGS),y)
TARGETS+=e2fsprogs
else
ifeq ($(BR2_PACKAGE_E2FSPROGS_LIBS),y)
TARGETS+=e2fsprogs-libs
endif
endif
