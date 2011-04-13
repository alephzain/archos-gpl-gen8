#############################################################
#
# libgcrypt
#
#############################################################
LIBGCRYPT_VERSION:=1.4.3
LIBGCRYPT_SOURCE:=libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2
LIBGCRYPT_SITE:=ftp://gd.tuwien.ac.at/privacy/gnupg/libgcrypt/
LIBGCRYPT_DIR:=$(BUILD_DIR)/libgcrypt-$(LIBGCRYPT_VERSION)

$(DL_DIR)/$(LIBGCRYPT_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBGCRYPT_SITE)/$(LIBGCRYPT_SOURCE)

$(LIBGCRYPT_DIR)/.source: $(DL_DIR)/$(LIBGCRYPT_SOURCE)
	$(BZCAT) $(DL_DIR)/$(LIBGCRYPT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LIBGCRYPT_DIR) package/libgcrypt/ libgcrypt\*.patch
	# This is incorrectly hardwired to yes for cross-compiles with no
	# sane way to pass pre-existing knowledge so fix it with the chainsaw..
	#$(SED) '/GNUPG_SYS_SYMBOL_UNDERSCORE/d' $(LIBGCRYPT_DIR)/configure
	touch $@

$(LIBGCRYPT_DIR)/.configured: $(LIBGCRYPT_DIR)/.source
	(cd $(LIBGCRYPT_DIR); rm -f config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		ac_cv_sys_symbol_underscore=no \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--disable-optimization \
		--with-gpg-error-prefix=$(STAGING_DIR)/usr \
	)
	touch $@

$(LIBGCRYPT_DIR)/.compiled: $(LIBGCRYPT_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(LIBGCRYPT_DIR)
	touch $@

$(LIBGCRYPT_DIR)/.installed: $(LIBGCRYPT_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(LIBGCRYPT_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libgcrypt.so* $(TARGET_DIR)/usr/lib/
	touch $@


libgcrypt: uclibc libgpg-error $(LIBGCRYPT_DIR)/.installed

libgcrypt-source: $(DL_DIR)/$(LIBGCRYPT_SOURCE)

libgcrypt-clean:
	rm -f $(TARGET_DIR)/usr/lib/libgcrypt.so*
	rm -f $(STAGING_DIR)/usr/lib/libgcrypt*
	rm -f $(STAGING_DIR)/bin/libgcrypt-config
	rm -f $(STAGING_DIR)/share/aclocal/libgcrypt.m4
	-$(MAKE) -C $(LIBGCRYPT_DIR) clean

libgcrypt-dirclean:
	rm -rf $(LIBGCRYPT_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBGCRYPT)),y)
TARGETS+=libgcrypt
endif
