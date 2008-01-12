#############################################################
#
# udev
#
#############################################################
UDEV_VERSION:=116
UDEV_VOLUME_ID_CURRENT:=0
UDEV_VOLUME_ID_AGE:=80
UDEV_VOLUME_ID_REVISION:=0
UDEV_VOLUME_ID_VERSION:=$(UDEV_VOLUME_ID_CURRENT).$(UDEV_VOLUME_ID_AGE).$(UDEV_VOLUME_ID_REVISION)
UDEV_SOURCE:=udev-$(UDEV_VERSION).tar.bz2
UDEV_SITE:=$(BR2_KERNEL_MIRROR)/linux/utils/kernel/hotplug
UDEV_CAT:=$(BZCAT)
UDEV_DIR:=$(BUILD_DIR)/udev-$(UDEV_VERSION)
UDEV_TARGET_BINARY:=sbin/udevd
UDEV_BINARY:=udevd

BR2_UDEV_CFLAGS:=$(TARGET_CFLAGS) -D_GNU_SOURCE
ifneq ($(BR2_LARGEFILE),y)
BR2_UDEV_CFLAGS+=-U_FILE_OFFSET_BITS
endif

ifeq ($(BR2_PACKAGE_SELINUX),y)
UDEV_USE_SELINUX:=true
else
UDEV_USE_SELINUX:=false
endif

# UDEV_ROOT is /dev so we can replace devfs, not /udev for experiments
UDEV_ROOT:=/dev

$(DL_DIR)/$(UDEV_SOURCE):
	 $(WGET) -P $(DL_DIR) $(UDEV_SITE)/$(UDEV_SOURCE)

$(UDEV_DIR)/.unpacked: $(DL_DIR)/$(UDEV_SOURCE)
	$(UDEV_CAT) $(DL_DIR)/$(UDEV_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(UDEV_DIR) package/udev \*.patch
	-$(SED) '/_FILE_OFFSET_BITS=/s/-D_FILE_OFFSET_BITS=[^[:space:]]*//g' $(UDEV_DIR)/Makefile
	touch $@

$(UDEV_DIR)/$(UDEV_BINARY): $(UDEV_DIR)/.unpacked
	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) CC=$(TARGET_CC) LD=$(TARGET_CC)\
		CFLAGS="$(BR2_UDEV_CFLAGS)" \
		USE_LOG=false USE_SELINUX=$(UDEV_USE_SELINUX) \
		udevdir=$(UDEV_ROOT) -C $(UDEV_DIR)
	touch -c $@

$(TARGET_DIR)/$(UDEV_TARGET_BINARY): $(UDEV_DIR)/$(UDEV_BINARY)
	$(INSTALL) -d $(TARGET_DIR)/sys
	$(MAKE) $(TARGET_CONFIGURE_OPTS) \
		DESTDIR=$(TARGET_DIR) \
		CFLAGS="$(BR2_UDEV_CFLAGS)" \
		LDFLAGS="-warn-common" \
		USE_LOG=false USE_SELINUX=$(UDEV_USE_SELINUX) \
		udevdir=$(UDEV_ROOT) -C $(UDEV_DIR) install

$(UDEV_DIR)/.target_install: $(UDEV_DIR)/$(UDEV_BINARY)
	$(INSTALL) -D -m 0755 package/udev/S10udev $(TARGET_DIR)/etc/init.d/S10udev
	$(INSTALL) -d $(TARGET_DIR)/etc/udev/rules.d
	$(INSTALL) -m 0644 $(UDEV_DIR)/etc/udev/frugalware/* $(TARGET_DIR)/etc/udev/rules.d
	( grep udev_root $(TARGET_DIR)/etc/udev/udev.conf > /dev/null 2>&1 || echo 'udev_root=/dev' >> $(TARGET_DIR)/etc/udev/udev.conf )
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/udevstart $(TARGET_DIR)/sbin/udevstart
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_PACKAGE_UDEV_UTILS),y)
	rm -f $(TARGET_DIR)/usr/sbin/udevmonitor \
		$(TARGET_DIR)/usr/bin/udevinfo \
		$(TARGET_DIR)/usr/bin/udevtest
endif
	touch $@

udev: uclibc $(TARGET_DIR)/$(UDEV_TARGET_BINARY) $(UDEV_DIR)/.target_install

udev-source: $(DL_DIR)/$(UDEV_SOURCE)

udev-clean: $(UDEV_CLEAN_DEPS)
	-$(MAKE) -C $(UDEV_DIR) clean
	rm -f $(TARGET_DIR)/etc/init.d/S10udev $(TARGET_DIR)/sbin/udev* \
		$(TARGET_DIR)/usr/sbin/udevmonitor $(TARGET_DIR)/usr/bin/udev*
	rm -rf $(TARGET_DIR)/sys

udev-dirclean: $(UDEV_DIRCLEAN_DEPS)
	rm -rf $(UDEV_DIR)

#####################################################################
ifeq ($(BR2_PACKAGE_UDEV_VOLUME_ID),y)

$(STAGING_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION):
	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) CC=$(TARGET_CC) LD=$(TARGET_CC)\
		CFLAGS="$(BR2_UDEV_CFLAGS)" \
		USE_LOG=false USE_SELINUX=$(UDEV_USE_SELINUX) \
		udevdir=$(UDEV_ROOT) EXTRAS="extras/volume_id" -C $(UDEV_DIR)
	$(INSTALL) -D -m 0644 $(UDEV_DIR)/extras/volume_id/lib/libvolume_id.h $(STAGING_DIR)/usr/include/libvolume_id.h
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/extras/volume_id/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(STAGING_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	-ln -sf libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(STAGING_DIR)/usr/lib/libvolume_id.so.0
	-ln -sf libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(STAGING_DIR)/usr/lib/libvolume_id.so

$(STAGING_DIR)/usr/lib/libvolume_id.la: $(STAGING_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	$(INSTALL) -D -m 0755 package/udev/libvolume_id.la.tmpl $(STAGING_DIR)/usr/lib/libvolume_id.la
	$(SED) 's/REPLACE_CURRENT/$(UDEV_VOLUME_ID_CURRENT)/g' \
		-e 's/REPLACE_AGE/$(UDEV_VOLUME_ID_AGE)/g' \
		-e 's/REPLACE_REVISION/$(UDEV_VOLUME_ID_REVISION)/g' \
		-e 's,REPLACE_LIB_DIR,$(STAGING_DIR)/usr/lib,g' \
		$(STAGING_DIR)/usr/lib/libvolume_id.la

$(TARGET_DIR)/lib/udev/vol_id: $(STAGING_DIR)/usr/lib/libvolume_id.la
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/extras/volume_id/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(TARGET_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	-ln -sf libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(TARGET_DIR)/usr/lib/libvolume_id.so.0
	-ln -sf libvolume_id.so.$(UDEV_VOLUME_ID_VERSION) $(TARGET_DIR)/usr/lib/libvolume_id.so
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/extras/volume_id/vol_id $(TARGET_DIR)/lib/udev/vol_id
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/lib/udev/vol_id

udev-volume_id: udev $(TARGET_DIR)/lib/udev/vol_id

udev-volume_id-clean:
	rm -f $(STAGING_DIR)/usr/include/libvolume_id.h \
		$(STAGING_DIR)/usr/lib/libvolume_id.so* \
		$(STAGING_DIR)/usr/lib/libvolume_id.la \
		$(TARGET_DIR)/usr/lib/libvolume_id.so.0* \
		$(TARGET_DIR)/lib/udev/vol_id
	rmdir --ignore-fail-on-non-empty $(TARGET_DIR)/lib/udev

udev-volume_id-dirclean:
	-$(MAKE) EXTRAS="extras/volume_id" -C $(UDEV_DIR) clean

UDEV_CLEAN_DEPS+=udev-volume_id-clean
UDEV_DIRCLEAN_DEPS+=udev-volume_id-dirclean
endif

#####################################################################
ifeq ($(BR2_PACKAGE_UDEV_SCSI_ID),y)

$(TARGET_DIR)/lib/udev/scsi_id: $(STAGING_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) CC=$(TARGET_CC) LD=$(TARGET_CC)\
		CFLAGS="$(BR2_UDEV_CFLAGS)" \
		USE_LOG=false USE_SELINUX=$(UDEV_USE_SELINUX) \
		udevdir=$(UDEV_ROOT) EXTRAS="extras/scsi_id" -C $(UDEV_DIR)
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/extras/scsi_id/scsi_id $(TARGET_DIR)/lib/udev/scsi_id
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/lib/udev/scsi_id

$(TARGET_DIR)/lib/udev/usb_id: $(STAGING_DIR)/usr/lib/libvolume_id.so.$(UDEV_VOLUME_ID_VERSION)
	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) CC=$(TARGET_CC) LD=$(TARGET_CC)\
		CFLAGS="$(BR2_UDEV_CFLAGS)" \
		USE_LOG=false USE_SELINUX=$(UDEV_USE_SELINUX) \
		udevdir=$(UDEV_ROOT) EXTRAS="extras/usb_id" -C $(UDEV_DIR)
	$(INSTALL) -D -m 0755 $(UDEV_DIR)/extras/usb_id/usb_id $(TARGET_DIR)/lib/udev/usb_id
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/lib/udev/usb_id

udev-scsi_id: udev $(TARGET_DIR)/lib/udev/scsi_id $(TARGET_DIR)/lib/udev/usb_id

udev-scsi_id-clean:
	rm -f $(TARGET_DIR)/lib/udev/scsi_id \
		$(TARGET_DIR)/lib/udev/usb_id
	rmdir --ignore-fail-on-non-empty $(TARGET_DIR)/lib/udev

udev-scsi_id-dirclean:
	-$(MAKE) EXTRAS="extras/scsi_id" -C $(UDEV_DIR) clean

UDEV_CLEAN_DEPS+=udev-scsi_id-clean
UDEV_DIRCLEAN_DEPS+=udev-scsi_id-dirclean
endif

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_UDEV),y)
TARGETS+=udev
endif

ifeq ($(BR2_PACKAGE_UDEV_VOLUME_ID),y)
TARGETS+=udev-volume_id
endif

ifeq ($(BR2_PACKAGE_UDEV_SCSI_ID),y)
TARGETS+=udev-scsi_id
endif
