REFDBG_VER:=1.2
REFDBG_DIR:=$(BUILD_DIR)/refdbg-$(REFDBG_VER)
REFDBG_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/refdbg/$(REFDBG_SOURCE)
REFDBG_SOURCE:=refdbg-$(REFDBG_VER).tar.gz

REFDBG_LIBS := \
	librefdbg.so
REFDBG_TARGETS := $(foreach REFDBG_LIB,$(REFDBG_LIBS),$(TARGET_DIR)/usr/lib/$(REFDBG_LIB)) $(TARGET_DIR)/usr/bin/refdbg
REFDBG_CLEAN_TARGETS := $(foreach REFDBG_TARGET,$(REFDBG_TARGETS),$(REFDBG_TARGET)*)

CWD=$(shell pwd)
USER=$(shell id -u)
GROUP=$(shell id -g)

$(DL_DIR)/$(REFDBG_SOURCE):
	$(WGET) -P $(DL_DIR) $(REFDBG_SITE)/$(REFDBG_SOURCE)

REFDBG-source: $(DL_DIR)/$(REFDBG_SOURCE)

$(REFDBG_DIR)/.unpacked: $(DL_DIR)/$(REFDBG_SOURCE)
	rm -rf $(REFDBG_DIR)
	tar -C $(BUILD_DIR) -z $(TAR_OPTIONS) $(DL_DIR)/$(REFDBG_SOURCE)
	touch $(REFDBG_DIR)/.unpacked

$(REFDBG_DIR)/.configured: $(REFDBG_DIR)/.unpacked
	( \
	cd $(REFDBG_DIR); \
	$(REFDBG_TARGET_CONFIGURE_OPTS) \
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) \
	LDFLAGS="${TARGET_LDFLAGS}" \
	CFLAGS="$(REFDBG_TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
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
	touch $(REFDBG_DIR)/.configured

$(REFDBG_DIR)/.build: $(REFDBG_DIR)/.configured
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) CFLAGS="-I$(STAGING_DIR)/include" $(MAKE) -C $(REFDBG_DIR)
	touch $(REFDBG_DIR)/.build

REFDBG_STAGING_LIB=$(STAGING_DIR)/usr/lib/$(firstword $(REFDBG_LIBS))

$(REFDBG_STAGING_LIB): $(REFDBG_DIR)/.build
	$(MAKE) -C $(REFDBG_DIR) install DESTDIR=$(STAGING_DIR)

$(TARGET_DIR)/usr/lib/librefdbg.so.0.0.0: $(REFDBG_STAGING_LIB)
	cp -dpf $(STAGING_DIR)/usr/lib/librefdbg.so* $(TARGET_DIR)/usr/lib
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

$(TARGET_DIR)/usr/bin/refdbg: $(REFDBG_STAGING_LIB)
	cp -dpf $(STAGING_DIR)/usr/bin/refdbg $(TARGET_DIR)/usr/bin
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@


refdbg: uclibc $(REFDBG_TARGETS)

refdbg-clean:
	rm -f $(REFDBG_CLEAN_TARGETS)
	-$(MAKE) -C $(REFDBG_DIR) DESTDIR=$(STAGING_DIR) uninstall
	-$(MAKE) -C $(REFDBG_DIR) clean

refdbg-dirclean:
	rm -rf $(REFDBG_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_REFDBG)),y)
TARGETS+=refdbg
endif
