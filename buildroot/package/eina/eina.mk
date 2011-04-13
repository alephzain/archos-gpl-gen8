#############################################################
#
# eina
#
#############################################################
EINA_VERSION:=0.0.1svn
EINA_SOURCE:=eina-$(EINA_VERSION).tar.bz2
EINA_SITE:=http://www.enlightenment.org
EINA_REPO:=http://svn.enlightenment.org/svn/e/trunk/eina
EINA_DIR:=$(BUILD_DIR)/eina-$(EINA_VERSION)
EINA_BINARY:=eina.a

$(EINA_DIR)/repo:
	[ `svn co $(EINA_REPO) $(EINA_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(EINA_DIR)/.unpacked
	[ -f $(EINA_DIR)/.unpacked ] || touch $(EINA_DIR)/.unpacked

$(EINA_DIR)/Makefile: $(EINA_DIR)/.unpacked
	toolchain/patch-kernel.sh $(EINA_DIR) package/eina/ eina-\*.patch
	(cd $(EINA_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--enable-shared \
		--disable-static \
		--disable-pthread \
	)

$(EINA_DIR)/.compiled: $(EINA_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(EINA_DIR) CFLAGS="-ggdb"
	touch $@

$(EINA_DIR)/.installed: $(EINA_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(EINA_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libeina.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/lib/eina $(TARGET_DIR)/usr/lib/
	touch $@

eina: uclibc $(EINA_DIR)/repo $(EINA_DIR)/.installed

eina-source: $(DL_DIR)/$(EINA_SOURCE)

eina-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(EINA_DIR) uninstall
	-$(MAKE) -C $(EINA_DIR) clean

eina-dirclean:
	rm -rf $(EINA_DIR)

.PHONY:	$(EINA_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_EINA)),y)
TARGETS+=eina
endif
