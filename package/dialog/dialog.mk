#############################################################
#
# dialog
#
#############################################################
DIALOG_VERSION:=1.1-20080819
DIALOG_SOURCE:=dialog-$(DIALOG_VERSION).tgz
DIALOG_SITE:=ftp://invisible-island.net/dialog
DIALOG_DIR:=$(BUILD_DIR)/dialog-$(DIALOG_VERSION)
DIALOG_BINARY:=dialog
DIALOG_TARGET_BINARY:=usr/bin/dialog

$(DL_DIR)/$(DIALOG_SOURCE):
	$(WGET) -P $(DL_DIR) $(DIALOG_SITE)/$(DIALOG_SOURCE)

$(DIALOG_DIR)/.source: $(DL_DIR)/$(DIALOG_SOURCE)
	$(ZCAT) $(DL_DIR)/$(DIALOG_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(DIALOG_DIR)/.configured: $(DIALOG_DIR)/.source
	(cd $(DIALOG_DIR); rm -f config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	)
	touch $@

$(DIALOG_DIR)/$(DIALOG_BINARY): $(DIALOG_DIR)/.configured
	$(MAKE) -C $(DIALOG_DIR)
	touch -c $@

$(TARGET_DIR)/$(DIALOG_TARGET_BINARY): $(DIALOG_DIR)/$(DIALOG_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(DIALOG_DIR) install
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -f $(wildcard $(TARGET_DIR)/usr/share/man/man?/dialog.*)
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -f $(wildcard $(TARGET_DIR)/usr/share/info/dialog.*)
endif

dialog: uclibc ncurses $(TARGET_DIR)/$(DIALOG_TARGET_BINARY)

dialog-source: $(DL_DIR)/$(DIALOG_SOURCE)

dialog-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(DIALOG_DIR) uninstall
	-$(MAKE) -C $(DIALOG_DIR) clean

dialog-dirclean:
	rm -rf $(DIALOG_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_DIALOG),y)
TARGETS+=dialog
endif
