#############################################################
#
# lm-sensors
#
#############################################################
LM_SENSORS_VERSION:=2.10.4
LM_SENSORS_SOURCE:=lm-sensors_$(LM_SENSORS_VERSION).orig.tar.gz
LM_SENSORS_PATCH:=lm-sensors_$(LM_SENSORS_VERSION)-3.diff.gz
LM_SENSORS_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/l/lm-sensors/
LM_SENSORS_DIR:=$(BUILD_DIR)/lm_sensors-$(LM_SENSORS_VERSION)
LM_SENSORS_CAT:=$(ZCAT)
LM_SENSORS_BINARY:=prog/sensors/sensors
LM_SENSORS_TARGET_BINARY:=usr/bin/sensors

$(DL_DIR)/$(LM_SENSORS_SOURCE):
	$(WGET) -P $(DL_DIR) $(LM_SENSORS_SITE)/$(LM_SENSORS_SOURCE)

ifneq ($(LM_SENSORS_PATCH),)
LM_SENSORS_PATCH_FILE:=$(DL_DIR)/$(LM_SENSORS_PATCH)
$(DL_DIR)/$(LM_SENSORS_PATCH):
	$(WGET) -P $(DL_DIR) $(LM_SENSORS_SITE)/$(LM_SENSORS_PATCH)
endif

lm_sensors-source: $(DL_DIR)/$(LM_SENSORS_SOURCE) $(LM_SENSORS_PATCH_FILE)

$(LM_SENSORS_DIR)/.unpacked: $(DL_DIR)/$(LM_SENSORS_SOURCE) $(DL_DIR)/$(LM_SENSORS_PATCH)
	$(LM_SENSORS_CAT) $(DL_DIR)/$(LM_SENSORS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LM_SENSORS_DIR) package/lm-sensors/ lm-sensors\*.patch
ifneq ($(LM_SENSORS_PATCH),)
	(cd $(LM_SENSORS_DIR) && \
	 $(LM_SENSORS_CAT) $(LM_SENSORS_PATCH_FILE) | patch -p1)
	if [ -d $(LM_SENSORS_DIR)/debian/patches ]; then \
		toolchain/patch-kernel.sh $(LM_SENSORS_DIR) $(LM_SENSORS_DIR)/debian/patches \*.patch; \
	fi
endif
	-$(SED) "s/-O[[:digit:]]//g" $(LM_SENSORS_DIR)/Makefile
	touch $@

$(LM_SENSORS_DIR)/$(LM_SENSORS_BINARY): $(LM_SENSORS_DIR)/.unpacked
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(LM_SENSORS_DIR) \
		LINUX="$(LINUX_DIR)" KERNELVERSION=$(LINUX_HEADERS_VERSION) \
		I2C_HEADERS=$(LINUX_DIR)/include \
		DESTDIR=$(TARGET_DIR) user

$(TARGET_DIR)/$(LM_SENSORS_TARGET_BINARY): $(LM_SENSORS_DIR)/$(LM_SENSORS_BINARY)
	if [ ! -f $(TARGET_DIR)/etc/sensors.conf ]; then \
		$(INSTALL) -D -m 0644 $(LM_SENSORS_DIR)/etc/sensors.conf.eg \
			$(TARGET_DIR)/etc/sensors.conf; \
		$(SED) '/^#/d' -e '/^[[:space:]]*$$/d' \
			$(TARGET_DIR)/etc/sensors.conf; \
	fi
	$(INSTALL) -D $(LM_SENSORS_DIR)/$(LM_SENSORS_BINARY) $@
	mkdir -p $(TARGET_DIR)/usr/lib
	cp -dpf $(LM_SENSORS_DIR)/lib/libsensors.so* \
		$(LM_SENSORS_DIR)/lib/libsensors.a $(TARGET_DIR)/usr/lib/
	-$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/lib/libsensors.so*
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

lm_sensors: uclibc libsysfs $(TARGET_DIR)/$(LM_SENSORS_TARGET_BINARY)

lm_sensors-clean:
	-$(MAKE) -C $(LM_SENSORS_DIR) clean
	rm -f $(TARGET_DIR)/$(LM_SENSORS_TARGET_BINARY) \
		$(TARGET_DIR)/lib/libsensors* \
		$(TARGET_DIR)/etc/sensors.conf

lm_sensors-dirclean:
	rm -rf $(LM_SENSORS_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LM_SENSORS),y)
TARGETS+=lm_sensors
endif
