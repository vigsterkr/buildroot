#############################################################
#
# elf2flt
#
#############################################################

# we keep a local checkout of uClinux CVS

ELF2FLT_DIR:=$(TOOL_BUILD_DIR)/elf2flt
ELF2FLT_SOURCE:=$(ELF2FLT_DIR)/elf2flt
ELF2FLT_BINARY:=elf2flt

$(ELF2FLT_DIR)/.unpacked:
	cp -r toolchain/elf2flt/elf2flt $(@D)
	touch $@

$(ELF2FLT_DIR)/.patched: $(ELF2FLT_DIR)/.unpacked
ifeq ($(ARCH),nios2)
	$(SED) "s,STAGING_DIR,$(STAGING_DIR),g;" toolchain/elf2flt/elf2flt.nios2.conditional
	$(SED) "s,CROSS_COMPILE_PREFIX,$(REAL_GNU_TARGET_NAME),g;" toolchain/elf2flt/elf2flt.nios2.conditional
	toolchain/patch-kernel.sh $(ELF2FLT_DIR) toolchain/elf2flt elf2flt.nios2.conditional
endif
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(ELF2FLT_DIR)/.configured: $(ELF2FLT_DIR)/.patched
	(cd $(ELF2FLT_DIR); rm -rf config.cache; \
		$(ELF2FLT_DIR)/configure \
		--target=$(REAL_GNU_TARGET_NAME) \
		--prefix=$(STAGING_DIR) \
		--with-binutils-build-dir=$(BINUTILS_DIR1)/ \
		--with-binutils-include-dir=$(BINUTILS_DIR)/include/ \
		--with-bfd-include-dir=$(BINUTILS_DIR1)/bfd/ \
		$(if $(BR2_ELF2FLT_ZLIB)--with-zlib-prefix=$(STAGING_DIR)/usr,--without-zlib-prefix) \
		--with-libbfd=$(BINUTILS_DIR1)/bfd/libbfd.a \
		--with-libiberty=$(BINUTILS_DIR1)/libiberty/libiberty.a \
	)
	touch $@

$(ELF2FLT_DIR)/$(ELF2FLT_BINARY): $(ELF2FLT_DIR)/.configured
	$(MAKE) -C $(ELF2FLT_DIR) all
	$(MAKE) -C $(ELF2FLT_DIR) install

elf2flt: uclibc $(if $(BR2_ELF2FLT_ZLIB),zlib) $(ELF2FLT_DIR)/$(ELF2FLT_BINARY)

elf2flt-clean:
	$(MAKE) -C $(ELF2FLT_DIR) clean
	-$(MAKE) -C $(ELF2FLT_DIR) uninstall
	rm -f $(ELF2FLT_DIR)/$(ELF2FLT_BINARY)

elf2flt-dirclean:
	rm -rf $(ELF2FLT_SOURCE)

ifeq ($(BR2_ELF2FLT),y)
TARGETS+=elf2flt
endif
