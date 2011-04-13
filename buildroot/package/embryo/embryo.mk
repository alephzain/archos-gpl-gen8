#############################################################
#
# embryo
#
#############################################################
EMBRYO_VERSION:=0.9.9.050svn
EMBRYO_SOURCE:=embryo-$(EMBRYO_VERSION).tar.bz2
EMBRYO_SITE:=http://www.enlightenment.org
EMBRYO_REPO:=http://svn.enlightenment.org/svn/e/trunk/embryo
EMBRYO_DIR:=$(BUILD_DIR)/embryo-$(EMBRYO_VERSION)
EMBRYO_BINARY:=embryo.a

$(EMBRYO_DIR)/repo:
	[ `svn co $(EMBRYO_REPO) $(EMBRYO_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(EMBRYO_DIR)/.unpacked
	[ -f $(EMBRYO_DIR)/.unpacked ] || touch $(EMBRYO_DIR)/.unpacked

$(EMBRYO_DIR)/Makefile: $(EMBRYO_DIR)/.unpacked
	toolchain/patch-kernel.sh $(EMBRYO_DIR) package/embryo/ embryo-\*.patch
	(cd $(EMBRYO_DIR); rm -rf config.cache; \
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
	)

$(EMBRYO_DIR)/.compiled: $(EMBRYO_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(EMBRYO_DIR) CFLAGS="-ggdb"
	touch $@

$(EMBRYO_DIR)/.installed: $(EMBRYO_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(EMBRYO_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libembryo.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/embryo* $(TARGET_DIR)/usr/bin/
	touch $@

embryo: uclibc $(EMBRYO_DIR)/repo $(EMBRYO_DIR)/.installed

embryo-source: $(DL_DIR)/$(EMBRYO_SOURCE)

embryo-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(EMBRYO_DIR) uninstall
	-$(MAKE) -C $(EMBRYO_DIR) clean

embryo-dirclean:
	rm -rf $(EMBRYO_DIR)

.PHONY: $(EMBRYO_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_EMBRYO)),y)
TARGETS+=embryo
endif
