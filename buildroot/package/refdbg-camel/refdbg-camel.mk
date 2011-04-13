REFDBG_CAMEL_VER:=1.2
REFDBG_CAMEL_DIR:=$(BUILD_DIR)/refdbg-camel-$(REFDBG_CAMEL_VER)
#REFDBG_CAMEL_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/refdbg/$(REFDBG_CAMEL_SOURCE)
REFDBG_CAMEL_SOURCE:=refdbg-camel-$(REFDBG_CAMEL_VER).tar.gz

REFDBG_CAMEL_LIB := librefdbg-camel.so
REFDBG_CAMEL_TARGETS := $(TARGET_DIR)/usr/lib/$(REFDBG_CAMEL_LIB) $(TARGET_DIR)/usr/bin/refdbg-camel
REFDBG_CAMEL_CLEAN_TARGETS := $(foreach REFDBG_CAMEL_TARGET,$(REFDBG_CAMEL_TARGETS),$(REFDBG_CAMEL_TARGET)*)

CWD=$(shell pwd)
USER=$(shell id -u)
GROUP=$(shell id -g)

$(DL_DIR)/$(REFDBG_CAMEL_SOURCE):
	#$(WGET) -P $(DL_DIR) $(REFDBG_CAMEL_SITE)/$(REFDBG_CAMEL_SOURCE)

REFDBG_CAMEL-source: $(DL_DIR)/$(REFDBG_CAMEL_SOURCE)

$(REFDBG_CAMEL_DIR)/.unpacked: $(DL_DIR)/$(REFDBG_CAMEL_SOURCE)
	rm -rf $(REFDBG_CAMEL_DIR)
	tar -C $(BUILD_DIR) -z $(TAR_OPTIONS) $(DL_DIR)/$(REFDBG_CAMEL_SOURCE)
	touch $(REFDBG_CAMEL_DIR)/.unpacked

$(REFDBG_CAMEL_DIR)/.configured: $(REFDBG_CAMEL_DIR)/.unpacked
	( \
	cd $(REFDBG_CAMEL_DIR); \
	$(REFDBG_CAMEL_TARGET_CONFIGURE_OPTS) \
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) \
	LDFLAGS="${TARGET_LDFLAGS}" \
	CFLAGS="$(REFDBG_CAMEL_TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include/camel-lite/ -I$(STAGING_DIR)/usr/include" \
	CPPFLAGS="${TARGET_CPPFLAGS}" \
	ac_cv_path_PKG_CONFIG=/bin/true \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr \
	--enable-shared \
	--disable-static ; \
	)
	touch $(REFDBG_CAMEL_DIR)/.configured

$(REFDBG_CAMEL_DIR)/.build: $(REFDBG_CAMEL_DIR)/.configured
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) CFLAGS="-I$(STAGING_DIR)/include" $(MAKE) -C $(REFDBG_CAMEL_DIR)
	touch $(REFDBG_CAMEL_DIR)/.build

REFDBG_CAMEL_STAGING_LIB=$(STAGING_DIR)/usr/lib/$(firstword $(REFDBG_CAMEL_LIBS))

$(REFDBG_CAMEL_STAGING_LIB): $(REFDBG_CAMEL_DIR)/.build
	$(MAKE) -C $(REFDBG_CAMEL_DIR) install DESTDIR=$(STAGING_DIR)

$(TARGET_DIR)/usr/lib/librefdbg-camel.so: $(REFDBG_CAMEL_STAGING_LIB)
	cp -dpf $(STAGING_DIR)/usr/lib/librefdbg-camel.so* $(TARGET_DIR)/usr/lib
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

$(TARGET_DIR)/usr/bin/refdbg-camel: $(REFDBG_CAMEL_STAGING_LIB)
	cp -dpf $(STAGING_DIR)/usr/bin/refdbg-camel $(TARGET_DIR)/usr/bin
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@


refdbg-camel: uclibc $(REFDBG_CAMEL_TARGETS)

refdbg-camel-clean:
	rm -f $(REFDBG_CAMEL_CLEAN_TARGETS)
	-$(MAKE) -C $(REFDBG_CAMEL_DIR) DESTDIR=$(STAGING_DIR) uninstall
	-$(MAKE) -C $(REFDBG_CAMEL_DIR) clean

refdbg-camel-dirclean:
	rm -rf $(REFDBG_CAMEL_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_REFDBG_CAMEL)),y)
TARGETS+=refdbg-camel
endif
