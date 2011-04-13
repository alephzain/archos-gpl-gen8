#############################################################
#
# tremor
#
#############################################################

TREMOR_VERSION=r4564
TREMOR_SOURCE=Tremor_$(TREMOR_VERSION).tgz
TREMOR_DIR=$(BUILD_DIR)/${shell basename $(TREMOR_SOURCE) .tgz}
TREMOR_WORKDIR=$(BUILD_DIR)/Tremor_$(TREMOR_VERSION)
TREMOR_CAT:=zcat

$(TREMOR_DIR)/.unpacked:
	$(TREMOR_CAT) $(DL_DIR)/$(TREMOR_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(TREMOR_DIR)/.configured: $(TREMOR_DIR)/.unpacked
	(cd $(TREMOR_DIR); \
		./autogen.sh \
		rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(STAGING_DIR) \
		--sysconfdir=/etc \
		$(DISABLE_NLS) \
		--enable-static=no \
		--enable-shared=yes \
	);
	touch $@

$(TREMOR_WORKDIR)/.compiled: $(TREMOR_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(TREMOR_WORKDIR)
	touch $@

$(TREMOR_WORKDIR)/.installed: $(TREMOR_WORKDIR)/.compiled
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(TREMOR_WORKDIR) install
	rm -rf $(TARGET_DIR)/usr/include/tremor
	$(MAKE) prefix=$(STAGING_DIR)/usr -C $(TREMOR_WORKDIR) install install-data
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libvorbis*
	touch $@

tremor:	uclibc $(TREMOR_WORKDIR)/.installed

tremor-source: $(DL_DIR)/$(TREMOR_SOURCE)

tremor-clean:
	@if [ -d $(TREMOR_WORKDIR)/Makefile ] ; then \
		$(MAKE) -C $(TREMOR_WORKDIR) clean ; \
	fi;
	rm $(TREMOR_WORKDIR)/.installed

tremor-dirclean:
	rm -rf $(TREMOR_DIR) $(TREMOR_WORKDIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_TREMOR)),y)
TARGETS+=tremor
endif
