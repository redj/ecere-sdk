# TOOLCHAIN
export CC      = $(CCACHE_COMPILE) $(DISTCC_COMPILE) $(GCC_PREFIX)gcc$(_SYSROOT)
export CPP     = $(CCACHE_COMPILE) $(DISTCC_COMPILE) $(GCC_PREFIX)cpp$(_SYSROOT)
export ECP     = ecp
export ECC     = ecc
ifeq "$(TARGET_PLATFORM)" "$(HOST_PLATFORM)"
export ECS     = ecs
else
export ECS     = ecs -t $(PLATFORM)
endif
export EAR     = ear
export AS      = $(GCC_PREFIX)as
export LD      = $(GCC_PREFIX)ld
export AR      = $(GCC_PREFIX)ar
export STRIP   = $(GCC_PREFIX)strip
UPX := upx

# DEBIAN
ifdef DEBIAN_PACKAGE
CFLAGS += $(CPPFLAGS)
OFLAGS += $(LDFLAGS)
endif
