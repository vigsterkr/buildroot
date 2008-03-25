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
#default to dynamic lib for better reuse
LIBPCAP_LIBEXT:=so
ifeq ($(LIBPCAP_LIBEXT),so)
LIBPCAP_LIB_VERSION:=.$(LIBPCAP_VERSION)
LIBPCAP_MAKE_TARGET:=shared
else
LIBPCAP_LIB_VERSION:=# empty
endif

$(DL_DIR)/$(LIBPCAP_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBPCAP_SITE)/$(LIBPCAP_SOURCE)

$(LIBPCAP_DIR)/.unpacked: $(DL_DIR)/$(LIBPCAP_SOURCE)
	$(LIBPCAP_CAT) $(DL_DIR)/$(LIBPCAP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	# packaging error..
	rm -f $(LIBPCAP_DIR)/gencode.c.rej $(LIBPCAP_DIR)/libpcap-0.9
	toolchain/patch-kernel.sh $(LIBPCAP_DIR) package/libpcap/ \*.patch
	$(CONFIG_UPDATE) $(@D)
	# alleged autoconf bug
	$(SED) 's/-O2//g' $(@D)/configure
	touch $@

$(LIBPCAP_DIR)/.configured: $(LIBPCAP_DIR)/.unpacked
	(cd $(LIBPCAP_DIR); rm -rf config.cache; \
		$(if $(KERNEL_MAJORVERSION),ac_cv_linux_vers=$(KERNEL_MAJORVERSION)) \
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

$(LIBPCAP_DIR)/libpcap.$(LIBPCAP_LIBEXT)$(LIBPCAP_LIB_VERSION): $(LIBPCAP_DIR)/.configured
	$(MAKE) -C $(LIBPCAP_DIR) shared

$(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT): $(LIBPCAP_DIR)/libpcap.$(LIBPCAP_LIBEXT)$(LIBPCAP_LIB_VERSION)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LIBPCAP_DIR) install install-shared
	test "x$(LIBPCAP_LIBEXT)" = "xso" && \
		rm -f $(STAGING_DIR)/usr/lib/libpcap.a

$(TARGET_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT): $(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT)
	$(INSTALL) -d $(@D)
	$(INSTALL) $(wildcard $(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT)*) \
		$(TARGET_DIR)/usr/lib/
	if test "x$(LIBPCAP_LIBEXT)" != "xso"; then \
	  $(INSTALL) $(STAGING_DIR)/usr/lib/libpcap.a $(TARGET_DIR)/usr/lib/; \
	else \
	for i in $(notdir $(wildcard $(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT).*.*.*)); \
	do \
		rm -f $(TARGET_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT) \
			$(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT); \
		ln -sf $$i \
			$(TARGET_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT) && \
		ln -sf $$i \
			$(STAGING_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT) && \
		break; \
	done; \
	fi
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

libpcap: uclibc zlib $(TARGET_DIR)/usr/lib/libpcap.$(LIBPCAP_LIBEXT)

libpcap-source: $(DL_DIR)/$(LIBPCAP_SOURCE)

libpcap-clean:
	-$(MAKE) -C $(LIBPCAP_DIR) clean
	rm -f $(wildcard $(addprefix $(STAGING_DIR)/usr/,include/pcap*.h lib/libpcap.a lib/libpcap.so share/man/man?/pcap.*)) \
		$(wildcard $(addprefix $(TARGET_DIR)/usr/,include/pcap*.h lib/libpcap.a lib/libpcap.so* share/man/man?/pcap.*)) \

libpcap-dirclean:
	rm -rf $(LIBPCAP_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBPCAP),y)
TARGETS+=libpcap
endif
