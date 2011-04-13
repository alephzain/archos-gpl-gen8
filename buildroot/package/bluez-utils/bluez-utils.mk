#############################################################
#
# blueZ
#
#############################################################
BLUEZ_UTILS_VERSION:=3.36
BLUEZ_UTILS_SOURCE:=bluez-utils-$(BLUEZ_UTILS_VERSION).tar.gz
BLUEZ_UTILS_SITE:=http://bluez.sf.net/download/
BLUEZ_UTILS_DIR:=$(BUILD_DIR)/bluez-utils-$(BLUEZ_UTILS_VERSION)
BLUEZ_UTILS_CAT:=$(ZCAT)
BLUEZ_UTILS_BINARY:= tools/hciattach
BLUEZ_UTILS_TARGET_BINARY:= /usr/sbin/hciattach

$(DL_DIR)/$(BLUEZ_UTILS_SOURCE):
	$(WGET) -P $(DL_DIR) $(BLUEZ_UTILS_SITE)/$(BLUEZ_UTILS_SOURCE)

bluez-utils-source: $(DL_DIR)/$(BLUEZ_UTILS_SOURCE)

bluez-unpacked: $(BLUEZ_UTILS_DIR)/.unpacked
$(BLUEZ_UTILS_DIR)/.unpacked: $(DL_DIR)/$(BLUEZ_UTILS_SOURCE)
	$(BLUEZ_UTILS_CAT) $(DL_DIR)/$(BLUEZ_UTILS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BLUEZ_UTILS_DIR) package/bluez-utils/ \*.patch*
	touch $(BLUEZ_UTILS_DIR)/.unpacked

$(BLUEZ_UTILS_DIR)/.configured: $(BLUEZ_UTILS_DIR)/.unpacked
	(cd $(BLUEZ_UTILS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		DBUS_CFLAGS="-I$(STAGING_DIR)/usr/include/glib-2.0 -I$(STAGING_DIR)/usr/include/dbus-1.0 -I$(STAGING_DIR)/usr/lib/dbus-1.0/include" \
		DBUS_LIBS="$(STAGING_DIR)/usr/lib/libdbus-1.so" \
		BLUEZ_CFLAGS="-I$(STAGING_DIR)/usr/include/bluetooth" \
		BLUEZ_LIBS="$(STAGING_DIR)/usr/lib/libbluetooth.so" \
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
		--disable-gstreamer \
		--enable-audio \
		--disable-alsa \
		--enable-usb \
		--enable-tools \
		--enable-hidd \
		--enable-pand \
		--enable-input \
		--enable-hid2hci \
		--enable-dund \
		--enable-configfiles \
		--enable-initscripts \
		--enable-static \
	)
	touch $(BLUEZ_UTILS_DIR)/.configured

$(BLUEZ_UTILS_DIR)/$(BLUEZ_UTILS_BINARY): $(BLUEZ_UTILS_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(BLUEZ_UTILS_DIR)

$(STAGING_DIR)/$(BLUEZ_UTILS_TARGET_BINARY): $(BLUEZ_UTILS_DIR)/$(BLUEZ_UTILS_BINARY)
	$(MAKE) -C $(BLUEZ_UTILS_DIR) DESTDIR=$(STAGING_DIR) install
	rm -rf $(TARGET_DIR)/usr/man

$(TARGET_DIR)/$(BLUEZ_UTILS_TARGET_BINARY): $(BLUEZ_UTILS_DIR)/$(BLUEZ_UTILS_BINARY)
	$(MAKE) -C $(BLUEZ_UTILS_DIR) DESTDIR=$(TARGET_DIR) install
	rm -rf $(TARGET_DIR)/usr/man
	#cp package/bluez/bluetooth.conf $(TARGET_DIR)/etc/dbus-1/system.d
	#cp package/bluez/input.conf $(TARGET_DIR)/etc/bluetooth/
	#cp package/bluez/network.conf $(TARGET_DIR)/etc/bluetooth/
	#cp package/bluez/main.conf $(TARGET_DIR)/etc/bluetooth/

bluez-utils: uclibc libglib2 libusb dbus bluez-libs $(TARGET_DIR)/$(BLUEZ_UTILS_TARGET_BINARY) $(STAGING_DIR)/$(BLUEZ_UTILS_TARGET_BINARY)

bluez-utils-clean:
	rm -f $(TARGET_DIR)/$(BLUEZ_UTILS_TARGET_BINARY)
	-$(MAKE) -C $(BLUEZ_UTILS_DIR) clean

bluez-utils-dirclean:
	rm -rf $(BLUEZ_UTILS_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BLUEZ_UTILS)),y)
TARGETS+=bluez-utils
endif
