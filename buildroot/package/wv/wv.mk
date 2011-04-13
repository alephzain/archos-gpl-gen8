#############################################################
#
# wv (wvware)
#
#############################################################
WV_VERSION:=1.2.4
WV_SOURCE:=wv-$(WV_VERSION).tar.gz
WV_SITE:=http://downloads.sourceforge.net/wvware
WV_DIR:=$(BUILD_DIR)/wv-$(WV_VERSION)
WV_CAT:=$(ZCAT)

WV_PREFIX=/opt/usr
WV_BIN:=wvWare
WV_TARGET_BIN:=$(WV_PREFIX)/bin/wvWare
WV_TARGET_LIB:=$(WV_PREFIX)/lib/libwv-1.2.so.3.0.1

$(DL_DIR)/$(WV_SOURCE):
	$(WGET) -P $(DL_DIR) $(WV_SITE)/$(WV_SOURCE)

wv-source: $(DL_DIR)/$(WV_SOURCE)

$(WV_DIR)/.unpacked: $(DL_DIR)/$(WV_SOURCE)
	$(WV_CAT) $(DL_DIR)/$(WV_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(WV_DIR) package/wv/ \*.patch*
	touch $(WV_DIR)/.unpacked

$(WV_DIR)/.configured: $(WV_DIR)/.unpacked
	(cd $(WV_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(WV_PREFIX) \
		--libdir=$(STAGING_DIR)$(WV_PREFIX)/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--without-x \
		--with-libwmf=$(STAGING_DIR)/opt/usr/lib \
		--with-libgsf=$(STAGING_DIR)/opt/usr/lib \
		LIBWMF_CONFIG=$(STAGING_DIR)/opt/usr/bin/libwmf-config \
	)
	touch $(WV_DIR)/.configured

$(WV_DIR)/$(WV_BIN): $(WV_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(WV_DIR)

$(STAGING_DIR)$(WV_TARGET_BIN): $(WV_DIR)/$(WV_BIN)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)$(WV_PREFIX) -C $(WV_DIR) install
	rm -f $(STAGING_DIR)$(WV_PREFIX)/lib/libwv.la

$(TARGET_DIR)$(WV_TARGET_BIN): $(STAGING_DIR)$(WV_TARGET_BIN)
	cp -av $(STAGING_DIR)$(WV_PREFIX)/lib/libwv-1.2.so* $(TARGET_DIR)$(WV_PREFIX)/lib/
	cp -av $(STAGING_DIR)$(WV_PREFIX)/lib/libwv.so $(TARGET_DIR)$(WV_PREFIX)/lib/
	cp -av $(STAGING_DIR)$(WV_PREFIX)/bin/wvWare $(TARGET_DIR)$(WV_PREFIX)/bin/
	cp -av $(STAGING_DIR)$(WV_PREFIX)/bin/wvSummary $(TARGET_DIR)$(WV_PREFIX)/bin/
	mkdir -p $(TARGET_DIR)$(WV_PREFIX)/share/wv
	cp -av $(STAGING_DIR)$(WV_PREFIX)/share/wv/wvHtml.xml $(TARGET_DIR)$(WV_PREFIX)/share/wv
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)$(WV_TARGET_LIB)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)$(WV_TARGET_BIN)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/wvSummary

wv: uclibc libgsf libwmf $(TARGET_DIR)$(WV_TARGET_BIN)

wv-clean:
	$(MAKE) prefix=$(STAGING_DIR)$(WV_PREFIX) -C $(WV_DIR) uninstall
	rm -f $(STAGING_DIR)$(WV_PREFIX)/lib/libwv*
	rm -f $(STAGING_DIR)$(WV_PREFIX)/bin/wv*
	rm -rf $(STAGING_DIR)_DIR)$(WV_PREFIX)/share/wv
	rm -f $(TARGET_DIR)$(WV_PREFIX)/lib/libwv*
	rm -f $(TARGET_DIR)$(WV_PREFIX)/bin/wv*
	rm -rf $(TARGET_DIR)$(WV_PREFIX)/share/wv
	$(MAKE) -C $(WV_DIR) clean

wv-dirclean:
	rm -rf $(WV_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_WV)),y)
TARGETS+=wv
endif
