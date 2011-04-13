#############################################################
#
# libwmf (wvware)
#
#############################################################
LIBWMF_VERSION:=0.2.8.4
LIBWMF_SOURCE:=libwmf-$(LIBWMF_VERSION).tar.gz
LIBWMF_SITE:=http://downloads.sourceforge.net/wvware
LIBWMF_DIR:=$(BUILD_DIR)/libwmf-$(LIBWMF_VERSION)
LIBWMF_CAT:=$(ZCAT)

LIBWMF_PREFIX=/opt/usr
LIBWMF_LIB:=src/.libs/libwmf-0.2.so.7.1.0
LIBWMF_TARGET_LIB:=$(GD_PREFIX)/lib/libwmf-0.2.so.7.1.0
LIBWMF_TARGET_LIB_LITE:=$(GD_PREFIX)/lib/libwmflite-0.2.so.7.0.1

$(DL_DIR)/$(LIBWMF_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBWMF_SITE)/$(LIBWMF_SOURCE)

libwmf-source: $(DL_DIR)/$(LIBWMF_SOURCE)

$(LIBWMF_DIR)/.unpacked: $(DL_DIR)/$(LIBWMF_SOURCE)
	$(LIBWMF_CAT) $(DL_DIR)/$(LIBWMF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LIBWMF_DIR) package/libwmf/ \*.patch*
	touch $(LIBWMF_DIR)/.unpacked

$(LIBWMF_DIR)/.configured: $(LIBWMF_DIR)/.unpacked
	(cd $(LIBWMF_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(LIBWMF_PREFIX) \
		--libdir=$(STAGING_DIR)$(LIBWMF_PREFIX)/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--without-x \
		--enable-gd \
		--without-docdir \
		--without-gsfontdir \
		--without-gsfontmap \
		FREETYPE_CONFIG=$(STAGING_DIR)/usr/bin/freetype-config \
	)
	touch $(LIBWMF_DIR)/.configured

$(LIBWMF_DIR)/$(LIBWMF_LIB): $(LIBWMF_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(LIBWMF_DIR)

$(LIBWMF_DIR)/.installed: $(LIBWMF_DIR)/$(LIBWMF_LIB)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) DESTDIR=$(STAGING_DIR) -C $(LIBWMF_DIR) install
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)$(LIBWMF_PREFIX) -C $(LIBWMF_DIR)/src install
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)/usr -C $(LIBWMF_DIR)/include install
	rm -f $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmf*.la 
	touch $(LIBWMF_DIR)/.installed

$(TARGET_DIR)$(LIBWMF_TARGET_LIB): $(LIBWMF_DIR)/.installed
	cp -a $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmf.so $(TARGET_DIR)$(LIBWMF_PREFIX)/lib/
	cp -a $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmf-0.2.so* $(TARGET_DIR)$(LIBWMF_PREFIX)/lib/
	cp -a $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmflite.so $(TARGET_DIR)$(LIBWMF_PREFIX)/lib/
	cp -a $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmflite-0.2.so* $(TARGET_DIR)$(LIBWMF_PREFIX)/lib/
	cp -a $(STAGING_DIR)$(LIBWMF_PREFIX)/share/libwmf $(TARGET_DIR)$(LIBWMF_PREFIX)/share/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)$(LIBWMF_TARGET_LIB)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)$(LIBWMF_TARGET_LIB_LITE)

libwmf: uclibc jpeg zlib expat freetype $(TARGET_DIR)$(LIBWMF_TARGET_LIB)

libwmf-clean:
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LIBWMF_DIR) uninstall
	rm -f $(STAGING_DIR)$(LIBWMF_PREFIX)/lib/libwmf*
	rm -rf $(STAGING_DIR)$(LIBWMF_PREFIX)/share/libwmf
	rm -f $(TARGET_DIR)$(LIBWMF_PREFIX)/lib/libwmf*
	rm -rf $(TARGET_DIR)$(LIBWMF_PREFIX)/share/libwmf
	$(MAKE) -C $(LIBWMF_DIR) clean

libwmf-dirclean:
	rm -rf $(LIBWMF_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBWMF)),y)
TARGETS+=libwmf
endif
