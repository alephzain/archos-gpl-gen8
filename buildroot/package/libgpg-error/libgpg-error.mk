#############################################################
#
# libgpg-error
#
#############################################################
LIBGPG_ERROR_VERSION:=1.7
LIBGPG_ERROR_SOURCE:=libgpg-error-$(LIBGPG_ERROR_VERSION).tar.bz2
LIBGPG_ERROR_SITE:=ftp://gd.tuwien.ac.at/privacy/gnupg/libgpg-error
LIBGPG_ERROR_DIR:=$(BUILD_DIR)/libgpg-error-$(LIBGPG_ERROR_VERSION)

$(DL_DIR)/$(LIBGPG_ERROR_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBGPG_ERROR_SITE)/$(LIBGPG_ERROR_SOURCE)

$(LIBGPG_ERROR_DIR)/.source: $(DL_DIR)/$(LIBGPG_ERROR_SOURCE)
	$(BZCAT) $(DL_DIR)/$(LIBGPG_ERROR_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LIBGPG_ERROR_DIR) package/libgpg-error/ libgpg-error\*.patch
	touch $@

$(LIBGPG_ERROR_DIR)/.configured: $(LIBGPG_ERROR_DIR)/.source
	(cd $(LIBGPG_ERROR_DIR); rm -f config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		$(DISABLE_NLS) \
	)
	touch $@

$(LIBGPG_ERROR_DIR)/.compiled: $(LIBGPG_ERROR_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(LIBGPG_ERROR_DIR)
	touch $@

$(LIBGPG_ERROR_DIR)/.installed: $(LIBGPG_ERROR_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(LIBGPG_ERROR_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libgpg-error.so* $(TARGET_DIR)/usr/lib/
	touch $@


libgpg-error: uclibc $(LIBGPG_ERROR_DIR)/.installed

libgpg-error-source: $(DL_DIR)/$(LIBGPG_ERROR_SOURCE)

libgpg-error-clean:
	rm -f $(TARGET_DIR)/usr/lib/libgpg-error.so*
	rm -f $(STAGING_DIR)/usr/lib/libgpg-error*
	-$(MAKE) -C $(LIBGPG_ERROR_DIR) clean

libgpg-error-dirclean:
	rm -rf $(LIBGPG_ERROR_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBGPG_ERROR)),y)
TARGETS+=libgpg-error
endif
