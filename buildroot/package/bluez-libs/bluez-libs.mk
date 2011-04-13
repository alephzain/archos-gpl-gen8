#############################################################
#
# blueZ
#
#############################################################
BLUEZ_LIBS_VERSION:=3.36
BLUEZ_LIBS_SOURCE:=bluez-libs-$(BLUEZ_LIBS_VERSION).tar.gz
BLUEZ_LIBS_SITE:=http://bluez.sf.net/download/
BLUEZ_LIBS_DIR:=$(BUILD_DIR)/bluez-libs-$(BLUEZ_LIBS_VERSION)
BLUEZ_LIBS_CAT:=$(ZCAT)
BLUEZ_LIBS_BINARY:= src/libbluetooth.la
BLUEZ_LIBS_TARGET_BINARY:= /usr/lib/libbluetooth.so

$(DL_DIR)/$(BLUEZ_LIBS_SOURCE):
	$(WGET) -P $(DL_DIR) $(BLUEZ_LIBS_SITE)/$(BLUEZ_LIBS_SOURCE)

bluez-libs-source: $(DL_DIR)/$(BLUEZ_LIBS_SOURCE)

bluez-unpacked: $(BLUEZ_LIBS_DIR)/.unpacked
$(BLUEZ_LIBS_DIR)/.unpacked: $(DL_DIR)/$(BLUEZ_LIBS_SOURCE)
	$(BLUEZ_LIBS_CAT) $(DL_DIR)/$(BLUEZ_LIBS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BLUEZ_LIBS_DIR) package/bluez-libs/ \*.patch*
	touch $(BLUEZ_LIBS_DIR)/.unpacked

$(BLUEZ_LIBS_DIR)/.configured: $(BLUEZ_LIBS_DIR)/.unpacked
	(cd $(BLUEZ_LIBS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		DBUS_CFLAGS="-I$(STAGING_DIR)/usr/include/glib-2.0 -I$(STAGING_DIR)/usr/include/dbus-1.0 -I$(STAGING_DIR)/usr/lib/dbus-1.0/include" \
		DBUS_LIBS="$(STAGING_DIR)/usr/lib/libdbus-1.so" \
		ac_cv_func_malloc_0_nonnull=yes \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--localstatedir=/var \
		--program-prefix="" \
		--sysconfdir=/etc \
		--enable-static \
	)
	touch $(BLUEZ_LIBS_DIR)/.configured

$(BLUEZ_LIBS_DIR)/$(BLUEZ_LIBS_BINARY): $(BLUEZ_LIBS_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(BLUEZ_LIBS_DIR)

$(STAGING_DIR)/$(BLUEZ_LIBS_TARGET_BINARY): $(BLUEZ_LIBS_DIR)/$(BLUEZ_LIBS_BINARY)
	$(MAKE) -C $(BLUEZ_LIBS_DIR) DESTDIR=$(STAGING_DIR) install
	rm -rf $(TARGET_DIR)/usr/man

$(TARGET_DIR)/$(BLUEZ_LIBS_TARGET_BINARY): $(BLUEZ_LIBS_DIR)/$(BLUEZ_LIBS_BINARY)
	$(MAKE) -C $(BLUEZ_LIBS_DIR) DESTDIR=$(TARGET_DIR) install
	rm -rf $(TARGET_DIR)/usr/man

bluez-libs: uclibc libglib2 libusb dbus $(TARGET_DIR)/$(BLUEZ_LIBS_TARGET_BINARY) $(STAGING_DIR)/$(BLUEZ_LIBS_TARGET_BINARY)

bluez-libs-clean:
	rm -f $(TARGET_DIR)/$(BLUEZ_LIBS_TARGET_BINARY)
	-$(MAKE) -C $(BLUEZ_LIBS_DIR) clean

bluez-libs-dirclean:
	rm -rf $(BLUEZ_LIBS_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BLUEZ_LIBS)),y)
TARGETS+=bluez-libs
endif
