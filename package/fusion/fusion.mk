#############################################################
#
# linux-fusion
#
#############################################################
LINUX_FUSION_VERSION:=3.2.3
LINUX_FUSION_SOURCE:=linux-fusion-$(LINUX_FUSION_VERSION).tar.gz
LINUX_FUSION_SITE:=http://www.directfb.org/downloads/Core
LINUX_FUSION_CAT:=$(ZCAT)
LINUX_FUSION_DIR:=$(TARGET_DIR)/etc/udev/rules.d
LINUX_FUSION:=40-fusion.rules
LINUX_FUSION_HEADER=$(STAGING_DIR)/usr/include/linux/fusion.h

#############################################################
#
# build linux-fusion
#
#############################################################

$(LINUX_FUSION_HEADER):
	$(INSTALL) -D package/fusion/fusion.h $(LINUX_FUSION_HEADER)/fusion.h

$(LINUX_FUSION_DIR)/$(LINUX_FUSION):
	$(INSTALL) -D package/fusion/40-fusion.rules $(LINUX_FUSION_DIR)/40-fusion.rules
	touch -c $@

linux-fusion: $(LINUX_FUSION_DIR)/$(LINUX_FUSION) $(LINUX_FUSION_HEADER)

linux-fusion-clean:
	rm -f $(LINUX_FUSION_DIR)/$(LINUX_FUSION)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LINUX_FUSION),y)
TARGETS+=linux-fusion
endif

