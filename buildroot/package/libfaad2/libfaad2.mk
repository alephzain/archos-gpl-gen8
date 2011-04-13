############################################################
#
# libfaad2
#
#############################################################
LIBFAAD2_VERSION=2.6.1
LIBFAAD2_SOURCE=faad2-$(LIBFAAD2_VERSION).tar.gz
LIBFAAD2_SITE=http://www.nih.at/libfaad2
LIBFAAD2_DIR=$(BUILD_DIR)/faad2
LIBFAAD2_CAT:=zcat

$(DL_DIR)/$(LIBFAAD2_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBFAAD2_SITE)/$(LIBFAAD2_SOURCE)

$(LIBFAAD2_DIR)/.unpacked: $(DL_DIR)/$(LIBFAAD2_SOURCE)
	$(LIBFAAD2_CAT) $(DL_DIR)/$(LIBFAAD2_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LIBFAAD2_DIR) package/libfaad2/ \*.patch
	touch $(LIBFAAD2_DIR)/.unpacked

$(LIBFAAD2_DIR)/.configured: $(LIBFAAD2_DIR)/.unpacked
	(cd $(LIBFAAD2_DIR);\
        $(TARGET_CONFIGURE_OPTS) \
	./bootstrap );
	(cd $(LIBFAAD2_DIR);\
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
	touch $(LIBFAAD2_DIR)/.configured

$(LIBFAAD2_DIR)/lib/.libs/libfaad2.so: $(LIBFAAD2_DIR)/.configured
	$(MAKE) -C $(LIBFAAD2_DIR)

$(LIBFAAD2_DIR)/.installed: $(LIBFAAD2_DIR)/lib/.libs/libfaad2.so
	$(MAKE) prefix=$(STAGING_DIR) -C $(LIBFAAD2_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libfaad.so* $(TARGET_DIR)/usr/lib/
	touch $(LIBFAAD2_DIR)/.installed

libfaad2: uclibc zlib $(LIBFAAD2_DIR)/.installed

libfaad2-source: $(DL_DIR)/$(LIBFAAD2_SOURCE)

libfaad2-clean:
	-make -C $(LIBFAAD2_DIR) uninstall
	-make -C $(LIBFAAD2_DIR) clean
	#-rm $(TARGET_DIR)/usr/lib/libfaad2.so*
	-rm $(LIBFAAD2_DIR)/.installed

libfaad2-dirclean: libfaad2-clean
	-rm -rf $(LIBFAAD2_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBFAAD2)),y)
TARGETS+=libfaad2
endif
