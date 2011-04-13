#############################################################
#
# nbtscan
#
#############################################################

NBTSCAN_VERSION:=1.0.35
NBTSCAN_SOURCE:=nbtscan-source-$(NBTSCAN_VERSION).tgz
NBTSCAN_SITE:=http://unixwiz.net/tools
NBTSCAN_DIR:=$(BUILD_DIR)/nbtscan-$(NBTSCAN_VERSION)
NBTSCAN_CAT:=$(ZCAT)

NBTSCAN_TARGET_DIR:=$(TARGET_DIR)

NBTSCAN_PREFIX=
NBTSCAN_BIN:=nbtscan
NBTSCAN_TARGET_BIN:=$(NBTSCAN_TARGET_DIR)/usr/bin/$(NBTSCAN_BIN)

$(DL_DIR)/$(NBTSCAN_SOURCE):
	$(WGET) -P $(DL_DIR) $(NBTSCAN_SITE)/$(NBTSCAN_SOURCE)

$(NBTSCAN_DIR)/.unpacked: $(DL_DIR)/$(NBTSCAN_SOURCE)
	mkdir -p $(NBTSCAN_DIR)
	$(NBTSCAN_CAT) $(DL_DIR)/$(NBTSCAN_SOURCE) | tar -C $(NBTSCAN_DIR) $(TAR_OPTIONS) -
	chmod u+wX  $(NBTSCAN_DIR)/*
	toolchain/patch-kernel.sh $(NBTSCAN_DIR) package/nbtscan/ \*.patch
	touch $(NBTSCAN_DIR)/.unpacked

nbtscan-compile: $(NBTSCAN_DIR)/.unpacked
	$(MAKE) CC=$(TARGET_CC) -I$(STAGING_DIR)/usr/include -C $(NBTSCAN_DIR)

$(NBTSCAN_TARGET_BIN):
	cp $(NBTSCAN_DIR)/$(NBTSCAN_BIN) $(NBTSCAN_TARGET_BIN)  
	-$(STRIPCMD) --strip-unneeded $(NBTSCAN_TARGET_DIR)/usr/bin/nbtscan
	touch -c $(NBTSCAN_TARGET_BIN)

nbtscan: uclibc nbtscan-compile $(NBTSCAN_TARGET_BIN)

nbtscan-clean:
	-$(RM) $(NBTSCAN_TARGET_BIN) 
	-$(MAKE) -C $(NBTSCAN_DIR) clean

nbtscan-dirclean: nbtscan-clean
	-$(RM) -rf $(NBTSCAN_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_NBTSCAN)),y)
TARGETS+=nbtscan
endif
