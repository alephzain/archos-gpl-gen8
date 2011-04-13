#############################################################
#
# e_dbus
#
#############################################################
E_DBUS_VERSION:=0.5.0svn
E_DBUS_SOURCE:=e_dbus-$(E_DBUS_VERSION).tar.bz2
E_DBUS_SITE:=http://www.enlightenment.org
E_DBUS_REPO:=http://svn.enlightenment.org/svn/e/trunk/e_dbus
E_DBUS_DIR:=$(BUILD_DIR)/e_dbus-$(E_DBUS_VERSION)
E_DBUS_BINARY:=e_dbus.a

$(E_DBUS_DIR)/repo:
	[ `svn co $(E_DBUS_REPO) $(E_DBUS_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(E_DBUS_DIR)/.unpacked
	[ -f $(E_DBUS_DIR)/.unpacked ] || touch $(E_DBUS_DIR)/.unpacked

$(E_DBUS_DIR)/Makefile: $(E_DBUS_DIR)/.unpacked
	toolchain/patch-kernel.sh $(E_DBUS_DIR) package/e_dbus/ e_dbus-\*.patch
	(cd $(E_DBUS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--enable-shared \
		--disable-static \
		--disable-ehal \
		--disable-enm \
	)

$(E_DBUS_DIR)/.compiled: $(E_DBUS_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(E_DBUS_DIR) CFLAGS="-ggdb"
	touch $@

$(E_DBUS_DIR)/.installed: $(E_DBUS_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(E_DBUS_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libedbus.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/lib/libenotify.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/e_dbus* $(TARGET_DIR)/usr/bin/
	cp -av $(STAGING_DIR)/usr/bin/e-notify-send $(TARGET_DIR)/usr/bin/
	touch $@

e_dbus: uclibc dbus eina evas $(E_DBUS_DIR)/repo $(E_DBUS_DIR)/.installed

e_dbus-source: $(DL_DIR)/$(E_DBUS_SOURCE)

e_dbus-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(E_DBUS_DIR) uninstall
	-$(MAKE) -C $(E_DBUS_DIR) clean

e_dbus-dirclean:
	rm -rf $(E_DBUS_DIR)

.PHONY:	$(E_DBUS_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_E_DBUS)),y)
TARGETS+=e_dbus
endif
