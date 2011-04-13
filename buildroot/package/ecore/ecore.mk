#############################################################
#
# ecore
#
#############################################################
ECORE_VERSION:=0.0.0svn
ECORE_SOURCE:=ecore-$(ECORE_VERSION).tar.bz2
ECORE_SITE:=http://www.enlightenment.org
ECORE_REPO:=http://svn.enlightenment.org/svn/e/trunk/ecore
ECORE_DIR:=$(BUILD_DIR)/ecore-$(ECORE_VERSION)
ECORE_BINARY:=ecore.a

$(ECORE_DIR)/repo:
	[ `svn co $(ECORE_REPO) $(ECORE_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(ECORE_DIR)/.unpacked
	[ -f $(ECORE_DIR)/.unpacked ] || touch $(ECORE_DIR)/.unpacked

$(ECORE_DIR)/Makefile: $(ECORE_DIR)/.unpacked
	toolchain/patch-kernel.sh $(ECORE_DIR) package/ecore/ ecore-\*.patch
	(cd $(ECORE_DIR); rm -rf config.cache; \
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
		--enable-ecore-fb \
		--disable-ecore-x \
	)

$(ECORE_DIR)/.compiled: $(ECORE_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(ECORE_DIR) CFLAGS="-ggdb"
	touch $@

$(ECORE_DIR)/.installed: $(ECORE_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(ECORE_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libecore*.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/ecore* $(TARGET_DIR)/usr/bin/
	touch $@

ecore: uclibc iconv tslib eina eet evas $(ECORE_DIR)/repo $(ECORE_DIR)/.installed

ecore-source: $(DL_DIR)/$(ECORE_SOURCE)

ecore-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(ECORE_DIR) uninstall
	-$(MAKE) -C $(ECORE_DIR) clean

ecore-dirclean:
	rm -rf $(ECORE_DIR)

.PHONY:	$(ECORE_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ECORE)),y)
TARGETS+=ecore
endif
