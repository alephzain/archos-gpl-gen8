#############################################################
#
# libfaac
#
#############################################################
LIBFAAC_VERSION=1.26
LIBFAAC_SOURCE=faac-$(LIBFAAC_VERSION).tar.gz
LIBFAAC_SITE=http://www.nih.at/libfaac
LIBFAAC_DIR=$(BUILD_DIR)/faac
LIBFAAC_CAT:=zcat

$(DL_DIR)/$(LIBFAAC_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBFAAC_SITE)/$(LIBFAAC_SOURCE)

$(LIBFAAC_DIR)/.unpacked: $(DL_DIR)/$(LIBFAAC_SOURCE)
	$(LIBFAAC_CAT) $(DL_DIR)/$(LIBFAAC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBFAAC_DIR)/.unpacked

$(LIBFAAC_DIR)/.configured: $(LIBFAAC_DIR)/.unpacked
	(cd $(LIBFAAC_DIR);\
        $(TARGET_CONFIGURE_OPTS) \
	./bootstrap );
	(cd $(LIBFAAC_DIR);\
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
	touch $(LIBFAAC_DIR)/.configured

$(LIBFAAC_DIR)/lib/.libs/libfaac.so: $(LIBFAAC_DIR)/.configured
	$(MAKE) -C $(LIBFAAC_DIR)

$(LIBFAAC_DIR)/.installed: $(LIBFAAC_DIR)/lib/.libs/libfaac.so
	$(MAKE) prefix=$(STAGING_DIR) -C $(LIBFAAC_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libfaac.so* $(TARGET_DIR)/usr/lib/
	touch $(LIBFAAC_DIR)/.installed

libfaac: uclibc zlib $(LIBFAAC_DIR)/.installed

libfaac-source: $(DL_DIR)/$(LIBFAAC_SOURCE)

libfaac-clean:
	-make -C $(LIBFAAC_DIR) uninstall
	-make -C $(LIBFAAC_DIR) clean
	#-rm $(TARGET_DIR)/usr/lib/libfaac.so*
	-rm $(LIBFAAC_DIR)/.installed

libfaac-dirclean: libfaac-clean
	-rm -rf $(LIBFAAC_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBFAAC)),y)
TARGETS+=libfaac
endif
