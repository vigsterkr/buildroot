#############################################################
#
# libtool
#
#############################################################
LIBTOOL_VERSION:=2.2.4
LIBTOOL_VERSION:=git
LIBTOOL_SOURCE:=libtool-$(LIBTOOL_VERSION).tar.bz2
LIBTOOL_SITE:=$(BR2_GNU_MIRROR)/libtool
LIBTOOL_CAT:=$(BZCAT)
LIBTOOL_SRC_DIR:=$(TOOL_BUILD_DIR)/libtool-$(LIBTOOL_VERSION)
LIBTOOL_DIR:=$(BUILD_DIR)/libtool-$(LIBTOOL_VERSION)
LIBTOOL_HOST_DIR:=$(TOOL_BUILD_DIR)/libtool-$(LIBTOOL_VERSION)-host
LIBTOOL_BINARY:=libtool
LIBTOOL_TARGET_BINARY:=usr/bin/libtool

$(DL_DIR)/$(LIBTOOL_SOURCE):
ifeq ($(LIBTOOL_VERSION),git)
	$(GIT) clone git://git.savannah.gnu.org/libtool.git $(LIBTOOL_SRC_DIR)
	(cd $(TOOL_BUILD_DIR)/libtool-$(LIBTOOL_VERSION) && \
	 ./bootstrap && \
	 cd $(TOOL_BUILD_DIR) && \
	 tar -cjf $@ libtool-$(LIBTOOL_VERSION) && \
	 rm -rf $(LIBTOOL_SRC_DIR) \
	)
else
	$(WGET) -P $(DL_DIR) $(LIBTOOL_SITE)/$(LIBTOOL_SOURCE)
endif

$(LIBTOOL_SRC_DIR)/.unpacked: $(DL_DIR)/$(LIBTOOL_SOURCE)
	$(LIBTOOL_CAT) $(DL_DIR)/$(LIBTOOL_SOURCE) | tar -C $(TOOL_BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	$(CONFIG_UPDATE) $(@D)/libltdl
	touch $@

#############################################################
#
# libtool for the target
#
#############################################################

$(LIBTOOL_DIR)/.configured: THIS_SRCDIR = $(LIBTOOL_SRC_DIR)
$(LIBTOOL_DIR)/.configured: $(LIBTOOL_SRC_DIR)/.unpacked
ifeq ($(BR2_USE_UPDATES),y)
	(test -d $(LIBTOOL_SRC_DIR)/.git && cd $(LIBTOOL_SRC_DIR) && $(GIT) pull)
endif
	rm -rf $(LIBTOOL_DIR)
	mkdir -p $(LIBTOOL_DIR)
	(cd $(LIBTOOL_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_NLS) \
	)
	touch $@

$(LIBTOOL_DIR)/$(LIBTOOL_BINARY): $(LIBTOOL_DIR)/.configured
	$(MAKE) -C $(LIBTOOL_DIR)
	touch -c $@

$(TARGET_DIR)/$(LIBTOOL_TARGET_BINARY): $(LIBTOOL_DIR)/$(LIBTOOL_BINARY)
	$(MAKE)  DESTDIR=$(TARGET_DIR) -C $(LIBTOOL_DIR) install
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) \
		$(TARGET_DIR)/usr/lib/libltdl.so.*.*.* > /dev/null 2>&1
	$(SED) "s,^CC.*,CC=\"/usr/bin/gcc\"," $(TARGET_DIR)/usr/bin/libtool
	$(SED) "s,^LD.*,LD=\"/usr/bin/ld\"," $(TARGET_DIR)/usr/bin/libtool
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	touch -c $@

libtool: uclibc $(TARGET_DIR)/$(LIBTOOL_TARGET_BINARY)

libtool-source: $(DL_DIR)/$(LIBTOOL_SOURCE)

libtool-clean:
	-$(MAKE) -C $(LIBTOOL_DIR) clean
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(LIBTOOL_DIR) uninstall

libtool-cross: uclibc $(LIBTOOL_DIR)/$(LIBTOOL_BINARY)

libtool-cross-clean:
	-$(MAKE) -C $(LIBTOOL_DIR) clean

libtool-dirclean:
	rm -rf $(LIBTOOL_DIR)

#############################################################
#
# libtool for the host
#
#############################################################

$(LIBTOOL_HOST_DIR)/.configured: $(LIBTOOL_SRC_DIR)/.unpacked
ifeq ($(BR2_USE_UPDATES),y)
	(test -d $(LIBTOOL_SRC_DIR)/.git && cd $(LIBTOOL_SRC_DIR) && $(GIT) pull)
endif
	mkdir -p $(LIBTOOL_HOST_DIR)
	(cd $(LIBTOOL_HOST_DIR); rm -rf config.cache; \
		$(HOST_CONFIGURE_OPTS) \
		CFLAGS="$(HOST_CFLAGS)" \
		LDFLAGS="$(HOST_LDFLAGS)" \
		$(LIBTOOL_SRC_DIR)/configure \
		--prefix=$(STAGING_DIR)/usr \
		$(DISABLE_NLS) \
	)
	touch $@

$(LIBTOOL_HOST_DIR)/$(LIBTOOL_BINARY): $(LIBTOOL_HOST_DIR)/.configured
	$(MAKE) -C $(LIBTOOL_HOST_DIR)
	touch -c $@

$(TOOL_BUILD_DIR)/bin/$(LIBTOOL_BINARY): $(LIBTOOL_HOST_DIR)/$(LIBTOOL_BINARY)
	$(MAKE) -C $(LIBTOOL_HOST_DIR) install
	rm -rf $(STAGING_DIR)/share/locale
	rm -rf $(STAGING_DIR)/usr/share/doc
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(STAGING_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(STAGING_DIR)/usr/share/man
endif
	$(INSTALL) -D -m0755 $^ $@
	$(INSTALL) -D -m0755 $(^)ize $(@)ize
	touch -c $@

host-libtool: $(TOOL_BUILD_DIR)/bin/$(LIBTOOL_BINARY)

host-libtool-clean:
	-$(MAKE) -C $(LIBTOOL_HOST_DIR) clean
	$(MAKE) -C $(LIBTOOL_HOST_DIR) uninstall
	rm -f $(TOOL_BUILD_DIR)/bin/$(LIBTOOL_BINARY) \
		  $(TOOL_BUILD_DIR)/bin/$(LIBTOOL_BINARY)ize

host-libtool-dirclean:
	rm -rf $(LIBTOOL_HOST_DIR) $(LIBTOOL_SRC_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBTOOL),y)
TARGETS+=libtool
endif
