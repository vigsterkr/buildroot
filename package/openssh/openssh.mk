#############################################################
#
# openssh
#
#############################################################
OPENSSH_VERSION=4.7p1
OPENSSH_SITE=ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable
OPENSSH_DIR=$(BUILD_DIR)/openssh-$(OPENSSH_VERSION)
OPENSSH_SOURCE=openssh-$(OPENSSH_VERSION).tar.gz

$(DL_DIR)/$(OPENSSH_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENSSH_SITE)/$(OPENSSH_SOURCE)

$(OPENSSH_DIR)/.unpacked: $(DL_DIR)/$(OPENSSH_SOURCE)
	$(ZCAT) $(DL_DIR)/$(OPENSSH_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(OPENSSH_DIR) package/openssh/ openssh\*.patch
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(OPENSSH_DIR)/.configured: $(OPENSSH_DIR)/.unpacked
	(cd $(OPENSSH_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		LD=$(TARGET_CROSS)gcc \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/lib \
		--libexecdir=/usr/sbin \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--includedir=$(STAGING_DIR)/usr/include \
		--disable-lastlog --disable-utmp \
		--disable-utmpx --disable-wtmp --disable-wtmpx \
		--without-x \
		--disable-strip \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(OPENSSH_DIR)/ssh: $(OPENSSH_DIR)/.configured
	$(MAKE) -C $(OPENSSH_DIR)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/scp
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/sftp
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/sftp-server
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-add
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-agent
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-keygen
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-keyscan
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-keysign
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/ssh-rand-helper
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(OPENSSH_DIR)/sshd

$(TARGET_DIR)/usr/bin/ssh: $(OPENSSH_DIR)/ssh
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(OPENSSH_DIR) install
	$(INSTALL) -D -m 0755 package/openssh/S50sshd $(TARGET_DIR)/etc/init.d/S50sshd
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
	rm -rf $(TARGET_DIR)/usr/share/doc

openssh: openssl zlib $(TARGET_DIR)/usr/bin/ssh

openssh-source: $(DL_DIR)/$(OPENSSH_SOURCE)

openssh-clean:
	$(MAKE) -C $(OPENSSH_DIR) clean
	$(MAKE) CC=$(TARGET_CC) DESTDIR=$(TARGET_DIR) -C $(OPENSSH_DIR) uninstall

openssh-dirclean:
	rm -rf $(OPENSSH_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_OPENSSH),y)
TARGETS+=openssh
endif
