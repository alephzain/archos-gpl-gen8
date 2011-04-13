BR2_QTE_C_QTE_VERSION:=$(shell echo $(BR2_QTE_VERSION)| sed -e 's/"//g')
BR2_QTE_C_TMAKE_VERSION:=$(shell echo $(BR2_QTE_TMAKE_VERSION)| sed -e 's/"//g')

# Can be either debug or release
BUILD_TYPE=debug

# Can be either SIM or REAL
ifeq ($(ARCH),i586)
TARGET:=SIM
_tmakearch:=x86
else
TARGET:=REAL
_tmakearch:=arm
endif

# Where to find tmake and which template set to use
_tmakedir=$(BUILD_DIR)/tmake-$(BR2_QTE_C_TMAKE_VERSION)
TMAKEPATH=$(_tmakedir)/lib/qws/linux-$(_tmakearch)-g++
TMAKE=$(_tmakedir)/bin/tmake

# Where has Qt2 been built
QTDIR=$(BUILD_DIR)/qt-$(BR2_QTE_C_QTE_VERSION)

# Make sure we can find the compiler
PATH:=$(STAGING_DIR)/usr/bin/:$(PATH)
