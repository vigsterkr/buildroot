#############################################################
#
# libpcap
#
#############################################################
# Copyright (C) 2001-2003 by Erik Andersen <andersen@codepoet.org>
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

LIBPCAP_VERSION:=0.9.8
LIBPCAP_DIR:=$(BUILD_DIR)/libpcap-$(LIBPCAP_VERSION)
LIBPCAP_SITE:=http://www.tcpdump.org/release
LIBPCAP_SOURCE:=libpcap-$(LIBPCAP_VERSION).tar.gz
LIBPCAP_CAT:=$(ZCAT)

$(DL_DIR)/$(LIBPCAP_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBPCAP_SITE)/$(LIBPCAP_SOURCE)

$(LIBPCAP_DIR)/.unpacked: $(DL_DIR)/$(LIBPCAP_SOURCE)
	$(LIBPCAP_CAT) $(DL_DIR)/$(LIBPCAP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	# packaging error..
	rm -f $(LIBPCAP_DIR)/gencode.c.rej
	toolchain/patch-kernel.sh $(LIBPCAP_DIR) package/libpcap/ \*.patch
	$(CONFIG_UPDATE) $(@D)
	# alleged autoconf bug
	$(SED) 's/-O2//g' $(@D)/configure
	touch $@

$(LIBPCAP_DIR)/.configured: $(LIBPCAP_DIR)/.unpacked
	(cd $(LIBPCAP_DIR); rm -rf config.cache; \
		$(if $(KERNEL_MAJORVERSION),ac_cv_linux_vers=$(KERNEL_MAJORVERSION)) \
		BUILD_CC=$(TARGET_CC) \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--disable-yydebug \
		--with-pcap=linux \
		$(DISABLE_IPV6) \
	)
	touch $@

$(LIBPCAP_DIR)/libpcap.a: $(LIBPCAP_DIR)/.configured
	$(MAKE) -C $(LIBPCAP_DIR)

$(STAGING_DIR)/usr/lib/libpcap.a: $(LIBPCAP_DIR)/libpcap.a
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LIBPCAP_DIR) install

libpcap: uclibc zlib $(STAGING_DIR)/usr/lib/libpcap.a

libpcap-source: $(DL_DIR)/$(LIBPCAP_SOURCE)

libpcap-clean:
	-$(MAKE) -C $(LIBPCAP_DIR) clean
	rm -f $(wildcard $(addprefix $(STAGING_DIR)/usr/,include/pcap*.h lib/libpcap.a share/man/man?/pcap.*))

libpcap-dirclean:
	rm -rf $(LIBPCAP_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBPCAP)),y)
TARGETS+=libpcap
endif
