#############################################################
#
# device-mapper
#
#############################################################
# Copyright (C) 2005 by Richard Downer <rdowner@gmail.com>
# Derived from work
# Copyright (C) 2001-2005 by Erik Andersen <andersen@codepoet.org>
# Copyright (C) 2002 by Tim Riker <Tim@Rikers.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

DM_BASEVER=1.02
DM_PATCH=28
DM_VERSION=$(DM_BASEVER).$(DM_PATCH)
DM_SOURCE:=device-mapper.$(DM_VERSION).tgz
DM_SITE:=ftp://sources.redhat.com/pub/dm
DM_SITE_OLD:=ftp://sources.redhat.com/pub/dm/old
DM_CAT:=$(ZCAT)
DM_DIR:=$(BUILD_DIR)/device-mapper.$(DM_VERSION)
DM_STAGING_BINARY:=$(STAGING_DIR)/usr/sbin/dmsetup
DM_TARGET_BINARY:=$(TARGET_DIR)/usr/sbin/dmsetup
DM_STAGING_LIBRARY:=$(STAGING_DIR)/lib/libdevmapper.so
DM_TARGET_LIBRARY:=$(TARGET_DIR)/usr/lib/libdevmapper.so
DM_TARGET_HEADER:=$(TARGET_DIR)/usr/include/libdevmapper.h

$(DL_DIR)/$(DM_SOURCE):
	$(WGET) -P $(DL_DIR) $(DM_SITE)/$(DM_SOURCE) || \
		$(WGET) -P $(DL_DIR) $(DM_SITE_OLD)/$(DM_SOURCE)

$(DM_DIR)/.unpacked: $(DL_DIR)/$(DM_SOURCE)
	$(DM_CAT) $(DL_DIR)/$(DM_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(DM_DIR) package/dm/ \*.patch
	$(CONFIG_UPDATE) $(@D)/autoconf
	touch $@
dm-unp: $(DM_DIR)/.unpacked
$(DM_DIR)/.configured: $(DM_DIR)/.unpacked
	(cd $(DM_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--libdir=/lib \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
		$(DISABLE_SELINUX) \
		--with-kernel-dir=$(LINUX_HEADERS_DIR) \
		--with-kernel-version=$(LINUX_HEADERS_VERSION) \
		--with-user=$(shell $(CONFIG_SHELL) -c 'id -un') \
		--with-group=$(shell $(CONFIG_SHELL) -c 'id -gn') \
		--with-optimisation="$(TARGET_CFLAGS)" \
		--disable-debug \
		--disable-compat \
	)
	touch $@

$(DM_STAGING_BINARY) $(DM_STAGING_LIBRARY): $(DM_DIR)/.configured
	$(MAKE) -C $(DM_DIR)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(DM_DIR) install

# Install dmsetup from staging to target
$(DM_TARGET_BINARY): $(DM_STAGING_BINARY)
	$(INSTALL) -D -m 0755 $? $@
	-$(STRIPCMD) $(STRIP_STRIP_ALL) $@
	touch -c $@

# Install libdevmapper.so.1.00 from staging to target
$(DM_TARGET_LIBRARY).$(DM_BASEVER): $(DM_STAGING_LIBRARY)
	$(INSTALL) -D -m 0644 $? $@
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@
	touch -c $@

# Makes libdevmapper.so a symlink to libdevmapper.so.1.00
$(DM_TARGET_LIBRARY): $(DM_TARGET_LIBRARY).$(DM_BASEVER)
	rm -f $@
	ln -s $(<F) $@
	touch -c $@

# Install header file
$(DM_TARGET_HEADER): $(DM_TARGET_LIBRARY)
	rm -f $@
	$(INSTALL) -D -m 0644 $(STAGING_DIR)/usr/include/libdevmapper.h $@

dm: uclibc $(DM_TARGET_BINARY) $(DM_TARGET_LIBRARY) \
	$(if $(BR2_HAVE_INCLUDES),$(DM_TARGET_HEADER))

dm-source: $(DL_DIR)/$(DM_SOURCE)

dm-clean:
	-$(MAKE) -C $(DM_DIR) clean
	rm -f $(DM_TARGET_BINARY) $(DM_TARGET_LIBRARY) \
		$(DM_TARGET_LIBRARY).$(DM_BASEVER) $(DM_TARGET_HEADER)

dm-dirclean:
	rm -rf $(DM_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_DM),y)
TARGETS+=dm
endif
