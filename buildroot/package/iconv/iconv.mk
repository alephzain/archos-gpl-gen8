#############################################################
#
# iconv
#
#############################################################
ICONV_VER:=1.8
ICONV_DIR:=$(BUILD_DIR)/libiconv-$(ICONV_VER)
ICONV_SITE:=ftp://ftp.gnu.org/pub/gnu/libiconv
ICONV_SOURCE:=libiconv-$(ICONV_VER).tar.gz

$(DL_DIR)/$(ICONV_SOURCE):
	 $(WGET) -P $(DL_DIR) $(ICONV_SITE)/$(ICONV_SOURCE)

$(ICONV_DIR)/.unpacked: $(DL_DIR)/$(ICONV_SOURCE)
	tar -C $(BUILD_DIR) -z $(TAR_OPTIONS) $(DL_DIR)/$(ICONV_SOURCE)
	touch $(ICONV_DIR)/.unpacked

$(ICONV_DIR)/.configured: $(ICONV_DIR)/.unpacked
	(cd $(ICONV_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(STAGING_DIR)/usr \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
	)
	touch $(ICONV_DIR)/.configured


$(STAGING_DIR)/usr/lib/libiconv.la: $(ICONV_DIR)/.configured
	$(MAKE) -C $(ICONV_DIR)
	$(MAKE) -C $(ICONV_DIR) install

$(TARGET_DIR)/usr/lib/libiconv.so.2: $(STAGING_DIR)/usr/lib/libiconv.la
	$(INSTALL) $(STAGING_DIR)/usr/lib/libiconv.so.2.1.0 $(TARGET_DIR)/usr/lib
	$(INSTALL) $(STAGING_DIR)/usr/lib/libiconv_plug.so $(TARGET_DIR)/usr/lib
	$(STRIPCMD) $(TARGET_DIR)/usr/lib/libiconv.so.2.1.0
	$(STRIPCMD) $(TARGET_DIR)/usr/lib/libiconv_plug.so
	ln -s libiconv.so.2.1.0 $(TARGET_DIR)/usr/lib/libiconv.so.2
	ln -s libiconv.so.2.1.0 $(TARGET_DIR)/usr/lib/libiconv.so
	$(INSTALL) $(STAGING_DIR)/usr/lib/libcharset.so.1.0.0 $(TARGET_DIR)/usr/lib
	$(STRIPCMD) $(TARGET_DIR)/usr/lib/libcharset.so.1.0.0
	ln -s libcharset.so.1.0.0 $(TARGET_DIR)/usr/lib/libcharset.so.1
	ln -s libcharset.so.1.0.0 $(TARGET_DIR)/usr/lib/libcharset.so

iconv: uclibc $(TARGET_DIR)/usr/lib/libiconv.so.2

iconv-clean:
	-$(MAKE) -C $(ICONV_DIR) uninstall
	-$(MAKE) -C $(ICONV_DIR) clean
	-rm -f $(TARGET_DIR)/usr/lib/libiconv_plug.so
	-rm -f $(TARGET_DIR)/usr/lib/libiconv.so*
	-rm -f $(TARGET_DIR)/usr/lib/libcharset.so*
	-rm $(ICONV_DIR)/.installed

iconv-dirclean: iconv-clean
	rm -rf $(ICONV_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ICONV)),y)
TARGETS+=iconv
endif
