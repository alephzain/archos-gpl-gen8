#############################################################
#
# blueZ
#
#############################################################
BLUEZ_VERSION:=4.18
BLUEZ_SOURCE:=bluez-$(BLUEZ_VERSION).tar.gz
BLUEZ_SITE:=http://www.kernel.org/pub/linux/bluetooth/
BLUEZ_DIR:=$(BUILD_DIR)/bluez-$(BLUEZ_VERSION)
BLUEZ_CAT:=$(ZCAT)
BLUEZ_BINARY:= tools/hcitool
BLUEZ_TARGET_BINARY:= /usr/bin/hcitool

$(DL_DIR)/$(BLUEZ_SOURCE):
	$(WGET) -P $(DL_DIR) $(BLUEZ_SITE)/$(BLUEZ_SOURCE)

bluez-source: $(DL_DIR)/$(BLUEZ_SOURCE)

bluez-unpacked: $(BLUEZ_DIR)/.unpacked
$(BLUEZ_DIR)/.unpacked: $(DL_DIR)/$(BLUEZ_SOURCE)
	$(BLUEZ_CAT) $(DL_DIR)/$(BLUEZ_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BLUEZ_DIR) package/bluez/ \*.patch*
	touch $(BLUEZ_DIR)/.unpacked

$(BLUEZ_DIR)/.configured: $(BLUEZ_DIR)/.unpacked
	(cd $(BLUEZ_DIR); rm -rf config.cache; \
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
	)
	touch $(BLUEZ_DIR)/.configured

$(BLUEZ_DIR)/$(BLUEZ_BINARY): $(BLUEZ_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(BLUEZ_DIR)

$(STAGING_DIR)/$(BLUEZ_TARGET_BINARY): $(BLUEZ_DIR)/$(BLUEZ_BINARY)
	$(MAKE) -C $(BLUEZ_DIR) DESTDIR=$(STAGING_DIR) install
	rm -rf $(TARGET_DIR)/usr/man

$(TARGET_DIR)/$(BLUEZ_TARGET_BINARY): $(BLUEZ_DIR)/$(BLUEZ_BINARY)
	$(MAKE) -C $(BLUEZ_DIR) DESTDIR=$(TARGET_DIR) install
	rm -rf $(TARGET_DIR)/usr/man
	#cp package/bluez/bluetooth.conf $(TARGET_DIR)/etc/dbus-1/system.d
	#cp package/bluez/input.conf $(TARGET_DIR)/etc/bluetooth/
	#cp package/bluez/network.conf $(TARGET_DIR)/etc/bluetooth/
	#cp package/bluez/main.conf $(TARGET_DIR)/etc/bluetooth/

bluez: uclibc libglib2 libusb dbus $(TARGET_DIR)/$(BLUEZ_TARGET_BINARY) $(STAGING_DIR)/$(BLUEZ_TARGET_BINARY)

bluez-clean:
	rm -f $(TARGET_DIR)/$(BLUEZ_TARGET_BINARY)
	-$(MAKE) -C $(BLUEZ_DIR) clean

bluez-dirclean:
	rm -rf $(BLUEZ_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BLUEZ)),y)
TARGETS+=bluez
endif
