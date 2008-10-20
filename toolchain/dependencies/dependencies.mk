######################################################################
#
# Check buildroot dependencies and bail out if the user's
# system is judged to be lacking....
#
######################################################################

DEPENDENCIES_HOST_PREREQ:=
ifeq ($(BR2_STRIP_sstrip),y)
DEPENDENCIES_HOST_PREREQ+=sstrip_host
endif
ifneq ($(findstring y,$(BR2_KERNEL_HEADERS_LZMA)),)
DEPENDENCIES_HOST_PREREQ+=host-lzma
endif

# grub2 needs ruby to generate its Makefiles. brrr
ifeq ($(BR2_TARGET_GRUB2),y)
NEED_RUBY:=y
endif
ifeq ($(findstring y,$(BR2_TARGET_SYSLINUX)$(BR2_TARGET_PXELINUX)),y)
NEED_NASM:=y
DEPENDENCIES_HOST_PREREQ+=host-nasm
endif

# We record the environ of the caller to see if we have to recheck
# via dependencies.sh.
dependencies:=.br.dependencies.host

ENV_DEP_HOST:=$(TOOL_BUILD_DIR)/bin/env.host
ENV_DEP_HOST_SOURCE:=$(TOPDIR)/toolchain/dependencies/env.c
$(ENV_DEP_HOST): $(ENV_DEP_HOST_SOURCE)
	@$(INSTALL) -d $(@D)
	@$(HOSTCC) $(HOST_CFLAGS) $(ENV_DEP_HOST_SOURCE) -o $@

$(dependencies): $(ENV_DEP_HOST) .config
	@$(ENV_DEP_HOST) > $@.new
	$(Q)if cmp $@ $@.new > /dev/null 2>&1; then \
		rm -f $@.new; \
	else \
		[ "x$(V)" != "x" ] && diff -u $@ $@.new; \
		mv $@.new $@; \
		set -e; \
		HOSTCC="$(firstword $(HOSTCC))" MAKE="$(MAKE)" \
			HOST_SED_DIR="$(HOST_SED_DIR)" \
			NEED_RUBY="$(NEED_RUBY)" \
			NEED_NASM="$(NEED_NASM)" \
			$(TOPDIR)/toolchain/dependencies/dependencies.sh; \
		$(MAKE1) host-sed $(DEPENDENCIES_HOST_PREREQ); \
		touch -c $@; \
	fi

do-dependencies: $(dependencies)
	@HOSTCC="$(firstword $(HOSTCC))" MAKE="$(MAKE)" \
		HOST_SED_DIR="$(HOST_SED_DIR)" \
		NEED_RUBY="$(NEED_RUBY)" \
		NEED_NASM="$(NEED_NASM)" \
		$(TOPDIR)/toolchain/dependencies/dependencies.sh
	$(MAKE1) host-sed $(DEPENDENCIES_HOST_PREREQ)

dependencies-source: $(ENV_DEP_HOST_SOURCE)

dependencies-clean: sstrip_target-clean sstrip_host-clean host-sed-clean \
    host-nasm-clean
	rm -f $(ENV_DEP_HOST) $(dependencies)

dependencies-dirclean:
	@true

#############################################################
#
# Toplevel Makefile options
#
#############################################################
