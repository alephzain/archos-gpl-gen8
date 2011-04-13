#############################################################
#
# fusesmb
#
#############################################################

FUSESMB_VERSION:=0.8.7
FUSESMB_SOURCE:=fusesmb-$(FUSESMB_VERSION).tar.gz
FUSESMB_SITE:=http://www.ricardis.tudelft.nl/~vincent/fusesmb/download/
FUSESMB_DIR:=$(BUILD_DIR)/fusesmb-$(FUSESMB_VERSION)
FUSESMB_CAT:=$(ZCAT)

FUSESMB_TARGET_DIR:=$(TARGET_DIR)

FUSESMB_PREFIX=
FUSESMB_BIN:=fusesmb
FUSESMB_TARGET_BIN:=$(FUSESMB_PREFIX)/usr/bin/$(FUSESMB_BIN)

$(DL_DIR)/$(FUSESMB_SOURCE):
	$(WGET) -P $(DL_DIR) $(FUSESMB_SITE)/$(FUSESMB_SOURCE)

$(FUSESMB_DIR)/.unpacked: $(DL_DIR)/$(FUSESMB_SOURCE)
	$(FUSESMB_CAT) $(DL_DIR)/$(FUSESMB_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(FUSESMB_DIR) package/fusesmb/ \*.patch
	touch $(FUSESMB_DIR)/.unpacked

$(FUSESMB_DIR)/.configured: $(FUSESMB_DIR)/.unpacked
	(cd $(FUSESMB_DIR); $(RM) -rf config.cache; \
	/usr/bin/aclocal && \
	/usr/bin/automake --add-missing && \
	/usr/bin/autoreconf && \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -DARCHOS" \
	LDFLAGS="-L$(STAGING_DIR)/lib -L$(STAGING_DIR)/usr/lib \
	-Wl,-rpath,$(FUSESMB_TARGET_DIR)/usr/lib \
	-Wl,-rpath-link,$(STAGING_DIR)/usr/lib" \
        ac_cv_prog_NMBLOOKUP=yes \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr );
	touch  $(FUSESMB_DIR)/.configured

fusesmb-compile: $(FUSESMB_DIR)/.configured
	$(MAKE) -C $(FUSESMB_DIR)

$(FUSESMB_TARGET_DIR)/usr/bin/fusesmb:
	$(MAKE) -C $(FUSESMB_DIR) DESTDIR=$(FUSESMB_TARGET_DIR) install 
	-$(STRIPCMD) --strip-unneeded $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb
	-$(STRIPCMD) --strip-unneeded $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb.cache
	-$(RM) -rf $(FUSESMB_TARGET_DIR)/usr/share/man
	touch -c $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb

fusesmb: uclibc fuse samba nbtscan fusesmb-compile $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb

fusesmb-clean:
	-$(MAKE) DESTDIR=$(FUSESMB_TARGET_DIR) CC=$(TARGET_CC) -C $(FUSESMB_DIR) uninstall
	-$(MAKE) -C $(FUSESMB_DIR) clean
	-$(RM) $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb $(FUSESMB_TARGET_DIR)/usr/bin/fusesmb.cache

fusesmb-dirclean: fusesmb-clean
	-$(RM) -rf $(FUSESMB_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_FUSESMB)),y)
TARGETS+=fusesmb
endif
