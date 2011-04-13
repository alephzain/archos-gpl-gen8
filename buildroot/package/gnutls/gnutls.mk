#############################################################
#                          
# GNUTLS                          
#                          
#############################################################
GNUTLS_VERSION:=2.6.2
GNUTLS_SOURCE:=gnutls-$(GNUTLS_VERSION).tar.bz2
GNUTLS_SITE:=ftp://ftp.gnu.org/pub/gnu/gnutls/
GNUTLS_DIR:=$(BUILD_DIR)/gnutls-$(GNUTLS_VERSION)


$(DL_DIR)/$(GNUTLS_SOURCE):
	$(WGET) -P $(DL_DIR) $(GNUTLS_SITE)/$(GNUTLS_SOURCE)


$(GNUTLS_DIR)/.unpacked: $(DL_DIR)/$(GNUTLS_SOURCE)
	bzcat $(DL_DIR)/$(GNUTLS_SOURCE) | tar -C $(BUILD_DIR) -xf -
	toolchain/patch-kernel.sh $(GNUTLS_DIR) package/gnutls/ gnutls-\*.patch
	touch $@


$(GNUTLS_DIR)/.configured: $(GNUTLS_DIR)/.unpacked
	(cd $(GNUTLS_DIR); \
	rm -rf config.cache; \
	$(TARGET_CONFIGURE_OPTS) \
	$(TARGET_CONFIGURE_ARGS) \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr \
	--libdir=$(STAGING_DIR)/usr/lib \
	--includedir=$(STAGING_DIR)/usr/include \
	--with-included-libtasn1 \
	--with-libgcrypt-prefix=$(STAGING_DIR) \
	)
	touch $@


$(GNUTLS_DIR)/.compiled: $(GNUTLS_DIR)/.configured
	$(MAKE) CXX=$(TARGET_CXX) CC=$(TARGET_CC) CFLAGS="-DWORDS_BIGENDIAN=1" -C $(GNUTLS_DIR)
	touch $@


$(GNUTLS_DIR)/.installed: $(GNUTLS_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(GNUTLS_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libgnutls.so* $(TARGET_DIR)/usr/lib/
	touch $@

gnutls: uclibc libgcrypt $(GNUTLS_DIR)/.installed

gnutls-source: $(DL_DIR)/$(GNUTLS_SOURCE)

gnutls-clean:
	$(MAKE) prefix=$(STAGING_DIR) CC=$(TARGET_CC) -C $(GNUTLS_DIR) uninstall
	rm -f $(TARGET_DIR)/usr/lib/libgnutls.so*
	-$(MAKE) -C $(GNUTLS_DIR) clean

gnutls-dirclean:
	rm -rf $(GNUTLS_DIR)


#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_GNUTLS)),y)
TARGETS+=gnutls
endif
