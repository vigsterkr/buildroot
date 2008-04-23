# gpm -- General Purpose Mouse
#GPM_VERSION = 1.20.3pre6
GPM_VERSION = 1.99.6
GPM_SOURCE = gpm-$(GPM_VERSION).tar.bz2
GPM_SITE = http://unix.schottelius.org/gpm/archives
GPM_BISON_FLAGS = -y
$(eval $(call AUTOTARGETS,package,gpm))
