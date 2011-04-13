#############################################################
#
# opencore-amr
http://freefr.dl.sourceforge.net/project/opencore-amr/opencore-amr/0.1.2/opencore-amr-0.1.2.tar.gz
#
#############################################################
OPENCORE_AMR_VERSION:=0.1.2
OPENCORE_AMR_SOURCE:=opencore-amr-$(OPENCORE_AMR_VERSION).tar.gz
OPENCORE_AMR_SITE:=http://freefr.dl.sourceforge.net
OPENCORE_AMR_SOURCE_URL:=$(OPENCORE_AMR_SITE)/project/opencore-amr/opencore-amr/$(OPENCORE_AMR_VERSION)/$(OPENCORE_AMR_SOURCE)
OPENCORE_AMR_DIR:=$(BUILD_DIR)/opencore-amr-$(OPENCORE_AMR_VERSION)

$(DL_DIR)/$(OPENCORE_AMR_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENCORE_AMR_SOURCE_URL)

$(OPENCORE_AMR_DIR)/.unpacked: $(DL_DIR)/$(OPENCORE_AMR_SOURCE)
	(cd $(BUILD_DIR) ; \
	tar -xvzf $(DL_DIR)/$(OPENCORE_AMR_SOURCE) )
	toolchain/patch-kernel.sh $(OPENCORE_AMR_DIR) package/opencore-amr/ opencore-amr-\*.patch
	touch $@

$(OPENCORE_AMR_DIR)/.configured: $(OPENCORE_AMR_DIR)/.unpacked
	(cd $(OPENCORE_AMR_DIR) ; \
	$(TARGET_CONFIGURE_OPTS) \
	$(TARGET_CONFIGURE_ARGS) \
	./configure \
	--prefix=/usr \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--libdir=$(STAGING_DIR)/usr/lib \
	--includedir=$(STAGING_DIR)/usr/include \
	)
	touch $@

$(OPENCORE_AMR_DIR)/.compiled: $(OPENCORE_AMR_DIR)/.configured
	$(MAKE) -C $(OPENCORE_AMR_DIR)
	touch $@

$(OPENCORE_AMR_DIR)/.installed: $(OPENCORE_AMR_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(OPENCORE_AMR_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libopencore-amrnb.so* $(TARGET_DIR)/usr/lib/
	touch $@

opencore-amr: uclibc $(OPENCORE_AMR_DIR)/.installed

opencore-amr-source: $(DL_DIR)/$(OPENCORE_AMR_SOURCE)

opencore-amr-clean:
	$(MAKE) prefix=$(STAGING_DIR) CC=$(TARGET_CC) -C $(OPENCORE_AMR_DIR) uninstall
	-$(MAKE) -C $(OPENCORE_AMR_DIR) clean
	rm -rf $(TARGET_DIR)/usr/lib/libopencore-amrnb.so*

opencore-amr-dirclean:
	rm -rf $(OPENCORE_AMR_DIR)

.PHONY:	$(OPENCORE_AMR_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_OPENCORE_AMR)),y)
TARGETS+=opencore-amr
endif
