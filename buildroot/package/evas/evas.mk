#############################################################
#
# evas
#
#############################################################
EVAS_VERSION:=0.0.0svn
EVAS_SOURCE:=evas-$(EVAS_VERSION).tar.bz2
EVAS_SITE:=http://www.enlightenment.org
EVAS_REPO:=http://svn.enlightenment.org/svn/e/trunk/evas
EVAS_DIR:=$(BUILD_DIR)/evas-$(EVAS_VERSION)
EVAS_BINARY:=evas.a

$(EVAS_DIR)/repo:
	[ `svn co $(EVAS_REPO) $(EVAS_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(EVAS_DIR)/.unpacked
	[ -f $(EVAS_DIR)/.unpacked ] || touch $(EVAS_DIR)/.unpacked

$(EVAS_DIR)/Makefile: $(EVAS_DIR)/.unpacked
	toolchain/patch-kernel.sh $(EVAS_DIR) package/evas/ evas-\*.patch
	(cd $(EVAS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--enable-shared \
		--disable-static \
		--enable-fb \
		--disable-software-x11 \
		--disable-xrender-x11 \
		--disable-software-xcb \
		--disable-xrender-xcb \
		--disable-pthread \
		--disable-image-loader-gif \
		--disable-async-events \
		--disable-async-preload \
	)

$(EVAS_DIR)/.compiled: $(EVAS_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(EVAS_DIR) CFLAGS="-ggdb"
	touch $@

$(EVAS_DIR)/.installed: $(EVAS_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(EVAS_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libevas.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/lib/evas $(TARGET_DIR)/usr/lib/
	touch $@

evas: uclibc eina eet fontconfig freetype libpng jpeg $(EVAS_DIR)/repo $(EVAS_DIR)/.installed

evas-source: $(DL_DIR)/$(EVAS_SOURCE)

evas-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(EVAS_DIR) uninstall
	-$(MAKE) -C $(EVAS_DIR) clean

evas-dirclean:
	rm -rf $(EVAS_DIR)

.PHONY:	$(EVAS_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_EVAS)),y)
TARGETS+=evas
endif
