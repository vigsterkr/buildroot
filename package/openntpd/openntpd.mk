#############################################################
#
# OpenNTPD
#
#############################################################
OPENNTPD_VERSION:=4.0
OPENNTPD_SOURCE:=openntpd-$(OPENNTPD_VERSION).tgz
OPENNTPD_SITE:=ftp://ftp.openbsd.org/pub/OpenBSD/OpenNTPD
OPENNTPD_DIR:=$(BUILD_DIR)/openntpd-$(OPENNTPD_VERSION)
OPENNTPD_CAT:=$(ZCAT)
OPENNTPD_BINARY:=ntpd
OPENNTPD_TARGET_BINARY:=usr/sbin/ntpd

$(DL_DIR)/$(OPENNTPD_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENNTPD_SITE)/$(OPENNTPD_SOURCE)

$(OPENNTPD_DIR)/.unpacked: $(DL_DIR)/$(OPENNTPD_SOURCE)
	$(ZCAT) $(DL_DIR)/$(OPENNTPD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	#mv $(BUILD_DIR)/ntpd $(OPENNTPD_DIR)
	touch $@

$(OPENNTPD_DIR)/.configured: $(OPENNTPD_DIR)/.unpacked
	(cd $(OPENNTPD_DIR); rm -f config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--with-builtin-arc4random \
	)
	touch $@

$(OPENNTPD_DIR)/$(OPENNTPD_BINARY): $(OPENNTPD_DIR)/.configured
	$(MAKE) -C $(OPENNTPD_DIR)
	#(cd $(OPENNTPD_DIR); \
	# $(YACC) parse.y; \
	# $(TARGET_CC) $(TARGET_CFLAGS) $(CFLAGS_COMBINE) \
	# $(CFLAGS_WHOLE_PROGRAM) -I$(OPENNTPD_DIR) \
	# -D__dead="__attribute((__noreturn__))" -DHAVE_INTXX_T=1 \
	# -include defines.h \
	# -o $@ \
	# ntpd.c buffer.c log.c imsg.c ntp.c ntp_msg.c y.tab.c config.c \
	# server.c client.c sensors.c util.c; \
	#)
	touch -c $@

$(TARGET_DIR)/$(OPENNTPD_TARGET_BINARY): $(OPENNTPD_DIR)/$(OPENNTPD_BINARY)
	rm -f $(TARGET_DIR)/etc/ntpd.conf
	$(MAKE) DESTDIR=$(TARGET_DIR) STRIP_OPT="" -C $(OPENNTPD_DIR) install
	$(INSTALL) -D -m 0644 $(OPENNTPD_DIR)/ntpd.conf $(TARGET_DIR)/etc/ntpd.conf
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/$(OPENNTPD_TARGET_BINARY)

ntpd: uclibc $(TARGET_DIR)/$(OPENNTPD_TARGET_BINARY)

ntpd-source: $(DL_DIR)/$(OPENNTPD_SOURCE)

ntpd-clean:
	-$(MAKE) -C $(OPENNTPD_DIR) clean
	rm -f $(TARGET_DIR)/etc/ntpd.conf \
		$(wildcard $(TARGET_DIR)/usr/share/man*/ntpd*) \
		$(OPENNTPD_TARGET_BINARY)

ntpd-dirclean:
	rm -rf $(OPENNTPD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_OPENNTPD),y)
TARGETS+=ntpd
endif
