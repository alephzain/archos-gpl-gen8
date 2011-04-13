#############################################################
#
# libusb1
#
#############################################################
LIBUSB1_VERSION:=1.0.8
LIBUSB1_SOURCE:=libusb-$(LIBUSB1_VERSION).tar.bz2
LIBUSB1_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/project/libusb/libusb-1.0/
LIBUSB1_DIR:=$(BUILD_DIR)/libusb-$(LIBUSB1_VERSION)
LIBUSB1_CAT:=$(BZCAT)
LIBUSB1_BINARY:=usr/lib/libusb-1.0.so

$(DL_DIR)/$(LIBUSB1_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBUSB1_SITE)/libusb-$(LIBUSB1_VERSION)/$(LIBUSB1_SOURCE)
	touch -c $@

$(LIBUSB1_DIR)/.unpacked: $(DL_DIR)/$(LIBUSB1_SOURCE)
	$(LIBUSB1_CAT) $(DL_DIR)/$(LIBUSB1_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

libusb1-unpacked: $(LIBUSB1_DIR)/.unpacked

$(LIBUSB1_DIR)/.configured: $(LIBUSB1_DIR)/.unpacked
	(cd $(LIBUSB1_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		ac_cv_header_regex_h=no \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--disable-debug \
		--disable-build-docs \
	)
	touch $@

$(STAGING_DIR)/$(LIBUSB1_BINARY): $(LIBUSB1_DIR)/.configured
	$(MAKE) -C $(LIBUSB1_DIR)
	$(MAKE) prefix=$(STAGING_DIR)/usr -C $(LIBUSB1_DIR) install
	$(INSTALL) -D $(LIBUSB1_DIR)/libusb/.libs/libusb-1.0.so $(STAGING_DIR)/$(LIBUSB1_BINARY)

$(TARGET_DIR)/$(LIBUSB1_BINARY): $(STAGING_DIR)/$(LIBUSB1_BINARY)
	$(INSTALL) -D $(STAGING_DIR)/$(LIBUSB1_BINARY) $(TARGET_DIR)/$(LIBUSB1_BINARY)
	ln -sf libusb-1.0.so $(TARGET_DIR)/$(LIBUSB1_BINARY).0
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(LIBUSB1_BINARY)

libusb1: uclibc $(TARGET_DIR)/$(LIBUSB1_BINARY)

libusb1-clean:
	rm -f $(TARGET_DIR)/$(LIBUSB1_BINARY)
	rm -f $(TARGET_DIR)/$(LIBUSB1_BINARY).0
	$(MAKE) prefix=$(STAGING_DIR)/usr -C $(LIBUSB1_DIR) uninstall
	-$(MAKE) -C $(LIBUSB1_DIR) clean

libusb1-dirclean:
	rm -rf $(LIBUSB1_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBUSB1)),y)
TARGETS+=libusb1
endif
