#############################################################
#
# nasm
#
#############################################################
NASM_VERSION:=2.04
NASM_SOURCE:=nasm-$(NASM_VERSION).tar.bz2
NASM_SITE:=http://www.nasm.us/pub/nasm/releasebuilds/$(NASM_VERSION)/
NASM_SRCDIR:=$(TOOL_BUILD_DIR)/nasm-$(NASM_VERSION)
NASM_DIR:=$(BUILD_DIR)/nasm-$(NASM_VERSION)
NASM_HOSTDIR:=$(TOOL_BUILD_DIR)/nasm-$(NASM_VERSION)-host
NASM_CAT:=$(BZCAT)
NASM_BINARY:=nasm
NASM_BINARIES:=ldrdf rdf2bin rdf2com rdf2bin rdf2ihx rdfdump rdflib rdx
NASM_TARGET_BINARY:=usr/bin/nasm

$(DL_DIR)/$(NASM_SOURCE):
	 $(WGET) -P $(DL_DIR) $(NASM_SITE)/$(NASM_SOURCE)

$(NASM_SRCDIR)/.unpacked: $(DL_DIR)/$(NASM_SOURCE)
	$(NASM_CAT) $(DL_DIR)/$(NASM_SOURCE) | tar -C $(TOOL_BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(NASM_SRCDIR) package/nasm/ nasm-$(NASM_VERSION)\*.patch
	$(CONFIG_UPDATE) $(NASM_SRCDIR)/
	touch $@

$(NASM_DIR)/.configured: THIS_SRCDIR=$(NASM_SRCDIR)
$(NASM_DIR)/.configured: $(NASM_SRCDIR)/.unpacked
	mkdir -p $(@D)
	(cd $(@D); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
	)
	touch $@

$(NASM_DIR)/$(NASM_BINARY): $(NASM_DIR)/.configured
	$(MAKE) -C $(NASM_DIR)/
	touch -c $@

$(TARGET_DIR)/$(NASM_TARGET_BINARY): $(NASM_DIR)/$(NASM_BINARY)
	# Bloat: rdoff/* should use a common library!
	$(MAKE) INSTALLROOT=$(TARGET_DIR) -C $(NASM_DIR) install install_rdf
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

nasm: $(TARGET_DIR)/$(NASM_TARGET_BINARY)

nasm-source: $(DL_DIR)/$(NASM_SOURCE)

nasm-clean:
	-$(MAKE) -C $(NASM_DIR) clean
	rm -rf $(TARGET_DIR)/$(NASM_TARGET_BINARY) \
	    $(addprefix $(TARGET_DIR)/$(dir $(NASM_TARGET_BINARY)), \
		    ndisasm $(NASM_BINARIES))

nasm-dirclean:
	rm -rf $(NASM_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_NASM),y)
TARGETS+=nasm
endif

#############################################################
#
# nasm for the host
#
#############################################################
HOST_NASM_BINARY=$(shell $(CONFIG_SHELL) package/nasm/nasmcheck.sh)
HOST_NASM_IF_ANY=$(shell $(CONFIG_SHELL) toolchain/dependencies/check-host-nasm.sh)


$(NASM_HOSTDIR)/.configured: THIS_SRCDIR=$(NASM_SRCDIR)
$(NASM_HOSTDIR)/.configured: $(NASM_SRCDIR)/.unpacked
	mkdir -p $(@D)
	(cd $(@D); rm -rf config.cache; \
		$(HOST_CONFIGURE_OPTS) \
		$(THIS_SRCDIR)/configure \
		--prefix=/usr \
	)
	touch $@

$(NASM_HOSTDIR)/$(NASM_BINARY): $(NASM_HOSTDIR)/.configured
	$(MAKE) -C $(NASM_HOSTDIR)/
	touch -c $@

build-nasm-host-binary: $(NASM_HOSTDIR)/$(NASM_BINARY)
	$(Q)if [ -L $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY) ]; then \
		rm -f $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY); \
	fi
	$(Q)if [ ! -f $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY) \
	      -o $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY) \
	      -ot $(NASM_HOST_DIR)/$(NASM_BINARY) ]; then \
		set -x; \
		$(INSTALL) -D -m0755 $(NASM_HOSTDIR)/$(NASM_BINARY) $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY); \
		$(INSTALL) -D -m0755 $(NASM_HOSTDIR)/ndisasm $(TOOL_BUILD_DIR)/bin/ndisasm; \
		$(foreach f,$(NASM_BINARIES),\
		    $(INSTALL) -D -m0755 $(NASM_HOSTDIR)/rdoff/$(f) $(TOOL_BUILD_DIR)/bin/$(f);) \
	fi

use-nasm-host-binary:
	$(Q)if [ ! -e "$(TOOL_BUILD_DIR)/bin/$(NASM_BINARY)" ]; then \
		rm -f $(TOOL_BUILD_DIR)/bin/$(NASM_BINARY); \
		mkdir -p $(TOOL_BUILD_DIR)/bin; \
		ln -sf "$(HOST_NASM_IF_ANY)" \
			$(TOOL_BUILD_DIR)/bin/$(NASM_BINARY); \
	fi

host-nasm: $(HOST_NASM_BINARY)

host-nasm-source: $(DL_DIR)/$(NASM_SOURCE)
ifeq ($(HOST_NASM_BINARY),build-nasm-host-binary)
host-nasm-clean:
	-$(MAKE) -C $(NASM_HOSTDIR) clean
	rm -rf $(addprefix $(TOOL_BUILD_DIR)/bin/,$(NASM_BINARY) ndisasm\
		$(NASM_BINARIES))

host-nasm-dirclean:
	rm -rf $(NASM_HOSTDIR) $(NASM_SRCDIR)
else
host-nasm-clean host-nasm-dirclean:
endif
.PHONY: host-nasm use-nasm-host-binary

