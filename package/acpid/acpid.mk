#############################################################
#
# acpid
#
#############################################################
ACPID_VERSION:=1.0.6
ACPID_DIR=$(BUILD_DIR)/acpid-$(ACPID_VERSION)
ACPID_SOURCE=acpid_$(ACPID_VERSION).orig.tar.gz
ACPID_PATCH=acpid_$(ACPID_VERSION)-10.diff.gz
ACPID_SITE=$(BR2_DEBIAN_MIRROR)/debian/pool/main/a/acpid
ACPID_CAT=$(ZCAT)

$(DL_DIR)/$(ACPID_SOURCE):
	$(WGET) -P $(DL_DIR) $(ACPID_SITE)/$(ACPID_SOURCE)

ifneq ($(ACPID_PATCH),)
ACPID_PATCH_FILE=$(DL_DIR)/$(ACPID_PATCH)
$(ACPID_PATCH_FILE):
	$(WGET) -P $(DL_DIR) $(ACPID_SITE)/$(ACPID_PATCH)
endif

$(ACPID_DIR)/.unpacked: $(DL_DIR)/$(ACPID_SOURCE) $(ACPID_PATCH_FILE)
	$(ACPID_CAT) $(DL_DIR)/$(ACPID_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(ACPID_PATCH),)
	(cd $(ACPID_DIR) && $(ACPID_CAT) $(ACPID_PATCH_FILE) | patch -p1)
endif
	toolchain/patch-kernel.sh $(ACPID_DIR) package/acpid/ acpid\*.patch
	touch $@

$(ACPID_DIR)/acpid: $(ACPID_DIR)/.unpacked
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(ACPID_DIR)
	touch -c $(ACPID_DIR)/acpid $(ACPID_DIR)/acpi_listen

$(TARGET_DIR)/usr/sbin/acpid: $(ACPID_DIR)/acpid
	$(INSTALL) -D -m 0755 $(ACPID_DIR)/acpid $(TARGET_DIR)/usr/sbin/acpid
	$(INSTALL) -d $(TARGET_DIR)/etc/acpi/events
	/bin/echo -e "event=button[ /]power\naction=/sbin/poweroff" > $(TARGET_DIR)/etc/acpi/events/powerbtn
	$(INSTALL) -D -m 0755 package/acpid/S20acpid $(TARGET_DIR)/etc/init.d/S20acpid
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

acpid: $(TARGET_DIR)/usr/sbin/acpid

acpid-source: $(DL_DIR)/$(ACPID_SOURCE) $(ACPID_PATCH_FILE)

acpid-clean:
	-make -C $(ACPID_DIR) clean
	rm -rf $(TARGET_DIR)/usr/sbin/acpid \
		$(TARGET_DIR)/etc/acpi

acpid-dirclean:
	rm -rf $(ACPID_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_ACPID),y)
TARGETS+=acpid
endif
