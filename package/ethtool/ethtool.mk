#############################################################
#
# ethtool
#
#############################################################

ETHTOOL_VERSION:=6
ETHTOOL_SOURCE:=ethtool-$(ETHTOOL_VERSION).tar.gz
ETHTOOL_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/gkernel/
ETHTOOL_DIR:=$(BUILD_DIR)/ethtool-$(ETHTOOL_VERSION)
ETHTOOL_CAT:=$(ZCAT)

$(DL_DIR)/$(ETHTOOL_SOURCE):
	$(WGET) -P $(DL_DIR) $(ETHTOOL_SITE)/$(ETHTOOL_SOURCE)

$(ETHTOOL_DIR)/.unpacked: $(DL_DIR)/$(ETHTOOL_SOURCE)
	$(ETHTOOL_CAT) $(DL_DIR)/$(ETHTOOL_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(ETHTOOL_DIR)/.configured: $(ETHTOOL_DIR)/.unpacked
	(cd $(ETHTOOL_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
	)
	touch $@

$(ETHTOOL_DIR)/ethtool: $(ETHTOOL_DIR)/.configured
	$(MAKE) -C $(ETHTOOL_DIR)

$(TARGET_DIR)/usr/sbin/ethtool: $(ETHTOOL_DIR)/ethtool
	$(INSTALL) -D -m 0755 $(ETHTOOL_DIR)/ethtool $@
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

ethtool: uclibc $(TARGET_DIR)/usr/sbin/ethtool

ethtool-source: $(DL_DIR)/$(ETHTOOL_SOURCE)

ethtool-clean:
	-$(MAKE) -C $(ETHTOOL_DIR) clean

ethtool-dirclean:
	rm -rf $(ETHTOOL_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ETHTOOL)),y)
TARGETS+=ethtool
endif
