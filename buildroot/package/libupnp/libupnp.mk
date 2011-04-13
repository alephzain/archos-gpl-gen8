#############################################################
#
# libupnp
#
#############################################################

LIBUPNP_VER:=1.6.6
LIBUPNP_DIR:=$(BUILD_DIR)/libupnp-$(LIBUPNP_VER)
LIBUPNP_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/pupnp
LIBUPNP_SOURCE:=libupnp-$(LIBUPNP_VER).tar.bz2
LIBUPNP_CAT:=bzcat

$(DL_DIR)/$(LIBUPNP_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBUPNP_SITE)/$(LIBUPNP_SOURCE)

libupnp-source: $(DL_DIR)/$(LIBUPNP_SOURCE)

$(LIBUPNP_DIR)/.unpacked: $(DL_DIR)/$(LIBUPNP_SOURCE)
	$(LIBUPNP_CAT) $(DL_DIR)/$(LIBUPNP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBUPNP_DIR)/.unpacked

$(LIBUPNP_DIR)/.patched: $(LIBUPNP_DIR)/.unpacked
	toolchain/patch-kernel.sh $(LIBUPNP_DIR) package/libupnp/ \*.patch
	touch $(LIBUPNP_DIR)/.patched


$(LIBUPNP_DIR)/.configured: $(LIBUPNP_DIR)/.patched
	(cd $(LIBUPNP_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CHOST=$(GNU_TARGET_NAME) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--prefix=$(STAGING_DIR)/usr \
	);
	touch $(LIBUPNP_DIR)/.configured

$(LIBUPNP_DIR)/.compiled: $(LIBUPNP_DIR)/.configured
	$(MAKE) -C $(LIBUPNP_DIR)
	touch $(LIBUPNP_DIR)/.compiled

$(STAGING_DIR)/usr/lib/libupnp.so: $(LIBUPNP_DIR)/.compiled
	$(MAKE) -C $(LIBUPNP_DIR) install

$(TARGET_DIR)/usr/lib/libupnp.so: $(STAGING_DIR)/usr/lib/libupnp.so
	cp -dpf $(STAGING_DIR)/usr/lib/libupnp.so* $(TARGET_DIR)/usr/lib/
	cp -dpf $(STAGING_DIR)/usr/lib/libixml.so* $(TARGET_DIR)/usr/lib/
	cp -dpf $(STAGING_DIR)/usr/lib/libthreadutil.so* $(TARGET_DIR)/usr/lib/
	-$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/lib/libupnp.so
	-$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/lib/libixml.so
	-$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/lib/libthreadutil.so

libupnp: uclibc zlib $(TARGET_DIR)/usr/lib/libupnp.so $(LIBUPNP_DIR)/.compiled

libupnp-clean:
	-$(MAKE) -C $(LIBUPNP_DIR) clean
	rm -f $(LIBUPNP_DIR)/.compiled

libupnp-dirclean:
	rm -rf $(LIBUPNP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBUPNP)),y)
TARGETS+=libupnp
endif
