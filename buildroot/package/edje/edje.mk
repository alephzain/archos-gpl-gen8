#############################################################
#
# edje
#
#############################################################
EDJE_VERSION:=0.0.0svn
EDJE_SOURCE:=edje-$(EDJE_VERSION).tar.bz2
EDJE_SITE:=http://www.enlightenment.org
EDJE_REPO:=http://svn.enlightenment.org/svn/e/trunk/edje
EDJE_DIR:=$(BUILD_DIR)/edje-$(EDJE_VERSION)
EDJE_BINARY:=edje.a

$(EDJE_DIR)/repo:
	[ `svn co $(EDJE_REPO) $(EDJE_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(EDJE_DIR)/.unpacked
	[ -f $(EDJE_DIR)/.unpacked ] || touch $(EDJE_DIR)/.unpacked

$(EDJE_DIR)/Makefile: $(EDJE_DIR)/.unpacked
	toolchain/patch-kernel.sh $(EDJE_DIR) package/edje/ edje-\*.patch
	(cd $(EDJE_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--datarootdir=$(STAGING_DIR)/usr/share \
		--includedir=$(STAGING_DIR)/usr/include \
		--enable-shared \
		--disable-static \
	)

$(EDJE_DIR)/.compiled: $(EDJE_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(EDJE_DIR) CFLAGS="-ggdb"
	touch $@

$(EDJE_DIR)/.installed: $(EDJE_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(EDJE_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libedje.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/edje* $(TARGET_DIR)/usr/bin/
	cp -av $(STAGING_DIR)/usr/share/edje $(TARGET_DIR)/usr/share/
	touch $@

edje: uclibc eina eet evas ecore embryo $(EDJE_DIR)/repo $(EDJE_DIR)/.installed

edje-source: $(DL_DIR)/$(EDJE_SOURCE)

edje-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(EDJE_DIR) uninstall
	-$(MAKE) -C $(EDJE_DIR) clean

edje-dirclean:
	rm -rf $(EDJE_DIR)

.PHONY:	$(EDJE_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_EDJE)),y)
TARGETS+=edje
endif
