#############################################################
#
# hotplug support
#
#############################################################
HOTPLUG_VERSION:=0.5
HOTPLUG_SOURCE=package/hotplug/diethotplug-$(HOTPLUG_VERSION).tar
HOTPLUG_SITE=http://www.kernel.org/pub/linux/utils/kernel/hotplug/
HOTPLUG_DIR=$(BUILD_DIR)/diethotplug-$(HOTPLUG_VERSION)
HOTPLUG_CAT=$(BZCAT)

$(HOTPLUG_DIR): $(HOTPLUG_SOURCE)
	$(HOTPLUG_CAT) $(HOTPLUG_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(HOTPLUG_DIR) package/hotplug/ hotplug\*.patch

$(HOTPLUG_DIR)/hotplug: $(HOTPLUG_DIR)
	$(MAKE) CROSS=$(TARGET_CROSS) DEBUG=false KLIBC=false \
	    KERNEL_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	    TARGET_DIR=$(TARGET_DIR) -C $(HOTPLUG_DIR)
	touch -c $@

$(TARGET_DIR)/sbin/hotplug: $(HOTPLUG_DIR)/hotplug
	$(INSTALL) -D -m 0755 $(HOTPLUG_DIR)/hotplug $(TARGET_DIR)/sbin/hotplug
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

hotplug: uclibc $(TARGET_DIR)/sbin/hotplug

hotplug-source: $(HOTPLUG_SOURCE)

hotplug-clean:
	-$(MAKE) -C $(HOTPLUG_DIR) clean
	rm -f $(TARGET_DIR)/sbin/hotplug

hotplug-dirclean:
	rm -rf $(HOTPLUG_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_HOTPLUG),y)
TARGETS+=hotplug
endif
