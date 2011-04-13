#############################################################
#
# libzip
#
#############################################################
LIBZIP_VERSION=0.8
LIBZIP_SOURCE=libzip-$(LIBZIP_VERSION).tar.gz
LIBZIP_SITE=http://www.nih.at/libzip
LIBZIP_DIR=$(BUILD_DIR)/${shell basename $(LIBZIP_SOURCE) .tar.gz}
LIBZIP_CAT:=zcat

$(DL_DIR)/$(LIBZIP_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBZIP_SITE)/$(LIBZIP_SOURCE)

$(LIBZIP_DIR)/.unpacked: $(DL_DIR)/$(LIBZIP_SOURCE)
	$(LIBZIP_CAT) $(DL_DIR)/$(LIBZIP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBZIP_DIR)/.unpacked

$(LIBZIP_DIR)/.configured: $(LIBZIP_DIR)/.unpacked
	(cd $(LIBZIP_DIR);\
	$(TARGET_CONFIGURE_OPTS) \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr \
	--libdir=$(STAGING_DIR)/usr/lib \
	--includedir=$(STAGING_DIR)/usr/include \
	--enable-static=no \
	--enable-shared=yes \
	);
	touch $(LIBZIP_DIR)/.configured

$(LIBZIP_DIR)/lib/.libs/libzip.so: $(LIBZIP_DIR)/.configured
	$(MAKE) -C $(LIBZIP_DIR)

$(LIBZIP_DIR)/.installed: $(LIBZIP_DIR)/lib/.libs/libzip.so
	$(MAKE) prefix=$(STAGING_DIR) -C $(LIBZIP_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libzip.so* $(TARGET_DIR)/usr/lib/
	touch $(LIBZIP_DIR)/.installed

libzip: uclibc zlib $(LIBZIP_DIR)/.installed

libzip-source: $(DL_DIR)/$(LIBZIP_SOURCE)

libzip-clean:
	-make -C $(LIBZIP_DIR) uninstall
	-make -C $(LIBZIP_DIR) clean
	-rm $(TARGET_DIR)/usr/lib/libzip.so*
	-rm $(LIBZIP_DIR)/.installed

libzip-dirclean: libzip-clean
	-rm -rf $(LIBZIP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBZIP)),y)
TARGETS+=libzip
endif
