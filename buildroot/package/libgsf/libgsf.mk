#############################################################
#
# libgsf
#
#############################################################
LIBGSF_VERSION:=1.13.99
LIBGSF_SOURCE:=libgsf-$(LIBGSF_VERSION).tar.gz
LIBGSF_SITE:=ftp://ftp.gnome.org/pub/GNOME/sources/libgsf/1.13
LIBGSF_DIR:=$(BUILD_DIR)/libgsf-$(LIBGSF_VERSION)
LIBGSF_CAT:=$(ZCAT)

LIBGSF_PREFIX=/opt/usr
LIBGSF_LIB:=gsf/.libs/libgsf-1.so.113.0.99
LIBGSF_TARGET_LIB:=$(LIBGSF_PREFIX)/lib/libgsf-1.so.113.0.99

$(DL_DIR)/$(LIBGSF_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBGSF_SITE)/$(LIBGSF_SOURCE)

libgsf-source: $(DL_DIR)/$(LIBGSF_SOURCE)

$(LIBGSF_DIR)/.unpacked: $(DL_DIR)/$(LIBGSF_SOURCE)
	$(LIBGSF_CAT) $(DL_DIR)/$(LIBGSF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBGSF_DIR)/.unpacked

$(LIBGSF_DIR)/.configured: $(LIBGSF_DIR)/.unpacked
	(cd $(LIBGSF_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(LIBGSF_PREFIX) \
		--libdir=$(STAGING_DIR)$(LIBGSF_PREFIX)/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--without-gnome \
		--without-python \
		--without-bz2 \
		--without-bonobo \
		--without-x \
		--disable-schemas-install \
	)
	touch $(LIBGSF_DIR)/.configured

$(LIBGSF_DIR)/$(LIBGSF_LIB): $(LIBGSF_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(LIBGSF_DIR)

$(STAGING_DIR)$(LIBGSF_TARGET_LIB): $(LIBGSF_DIR)/$(LIBGSF_LIB)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)$(LIBGSF_PREFIX) -C $(LIBGSF_DIR) install
	cp -a $(STAGING_DIR)$(LIBGSF_PREFIX)/lib/pkgconfig/libgsf-1.pc $(STAGING_DIR)/usr/lib/pkgconfig
	rm -f $(STAGING_DIR)$(LIBGSF_PREFIX)/lib/libgsf-1.la 
	
$(TARGET_DIR)$(LIBGSF_TARGET_LIB): $(STAGING_DIR)$(LIBGSF_TARGET_LIB)
	cp -av $(STAGING_DIR)$(LIBGSF_PREFIX)/lib/libgsf-1.so* $(TARGET_DIR)$(LIBGSF_PREFIX)/lib/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

libgsf: uclibc libglib2 libxml2 zlib $(TARGET_DIR)$(LIBGSF_TARGET_LIB)

libgsf-clean:
	$(MAKE) prefix=$(STAGING_DIR)$(LIBGSF_PREFIX) -C $(LIBGSF_DIR) uninstall
	rm -f $(TARGET_DIR)$(LIBGSF_PREFIX)/lib/libgsf-1.so*
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libgsf-1.pc
	$(MAKE) -C $(LIBGSF_DIR) clean

libgsf-dirclean:
	rm -rf $(LIBGSF_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBGSF)),y)
TARGETS+=libgsf
endif
