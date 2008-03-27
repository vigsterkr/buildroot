#############################################################
#
# links (text based web browser)
#
#############################################################
LINKS_VERSION:=0.99pre9-no-ssl
LINKS_SITE:=http://artax.karlin.mff.cuni.cz/~mikulas/vyplody/links/download/no-ssl
LINKS_SOURCE:=links-$(LINKS_VERSION).tar.gz
LINKS_DIR:=$(BUILD_DIR)/links-$(LINKS_VERSION)

$(DL_DIR)/$(LINKS_SOURCE):
	$(WGET) -P $(DL_DIR) $(LINKS_SITE)/$(LINKS_SOURCE)

$(LINKS_DIR)/.unpacked: $(DL_DIR)/$(LINKS_SOURCE)
	$(ZCAT) $(DL_DIR)/$(LINKS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(LINKS_DIR)/.configured: $(LINKS_DIR)/.unpacked
	(cd $(LINKS_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		$(DISABLE_NLS) \
	)
	touch $@

$(LINKS_DIR)/links: $(LINKS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(LINKS_DIR)

$(TARGET_DIR)/usr/bin/links: $(LINKS_DIR)/links
	$(INSTALL) -D $(LINKS_DIR)/links $(TARGET_DIR)/usr/bin/links
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

links: uclibc $(TARGET_DIR)/usr/bin/links

links-source: $(DL_DIR)/$(LINKS_SOURCE)

links-clean:
	-$(MAKE) -C $(LINKS_DIR) clean
	rm -f $(TARGET_DIR)/usr/bin/links

links-dirclean:
	rm -rf $(LINKS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LINKS),y)
TARGETS+=links
endif
