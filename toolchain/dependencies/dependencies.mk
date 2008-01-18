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

# We record the environ of the caller to see if we have to recheck
# via dependencies.sh.
dependencies:=.br.dependencies.host

ENV_DEP_HOST:=$(STAGING_DIR)/bin/env_host
ENV_DEP_HOST_SOURCE:=$(TOPDIR)/toolchain/dependencies/env.c
$(ENV_DEP_HOST): $(ENV_DEP_HOST_SOURCE) | host-sed $(DEPENDENCIES_HOST_PREREQ)
	@$(INSTALL) -d $(@D)
	@$(HOSTCC) $(HOST_CFLAGS) $(ENV_DEP_HOST_SOURCE) -o $@

$(dependencies): $(ENV_DEP_HOST)
	@HOSTCC="$(firstword $(HOSTCC))" MAKE="$(MAKE)" \
		HOST_SED_DIR="$(HOST_SED_DIR)" \
		$(TOPDIR)/toolchain/dependencies/dependencies.sh
	@$(ENV_DEP_HOST) > $@

$(dependencies)-source: $(ENV_DEP_HOST_SOURCE)

$(dependencies)-clean: sstrip_target-clean sstrip_host-clean host-sed-clean
	rm -f $(ENV_DEP_HOST) $(dependencies)

$(dependencies)-dirclean:
	true

#############################################################
#
# Toplevel Makefile options
#
#############################################################
