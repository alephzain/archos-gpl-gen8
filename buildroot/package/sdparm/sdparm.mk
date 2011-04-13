#############################################################
#
# sdparm
#
#############################################################
SDPARM_VERSION:=1.02
SDPARM_SOURCE:=sdparm-$(SDPARM_VERSION).tgz
SDPARM_SITE:=http://sg.torque.net/sg/p
SDPARM_CAT:=$(ZCAT)
SDPARM_DIR:=$(BUILD_DIR)/sdparm-$(SDPARM_VERSION)
SDPARM_BINARY:=src/sdparm
SDPARM_TARGET_BINARY:=sbin/sdparm

$(DL_DIR)/$(SDPARM_SOURCE):
	 $(WGET) -P $(DL_DIR) $(SDPARM_SITE)/$(SDPARM_SOURCE)

sdparm-source: $(DL_DIR)/$(SDPARM_SOURCE)

$(SDPARM_DIR)/.unpacked: $(DL_DIR)/$(SDPARM_SOURCE)
	$(SDPARM_CAT) $(DL_DIR)/$(SDPARM_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(SDPARM_DIR) package/sdparm \*.patch
	touch $@

$(SDPARM_DIR)/.configured: $(SDPARM_DIR)/.unpacked
	( cd $(SDPARM_DIR) && \
		$(TARGET_CONFIGURE_OPTS) \
		./configure \
		--host=$(REAL_GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
	)
	touch $(SDPARM_DIR)/.configured

$(SDPARM_DIR)/$(SDPARM_BINARY): $(SDPARM_DIR)/.configured
	$(MAKE) -C $(SDPARM_DIR)

$(TARGET_DIR)/$(SDPARM_TARGET_BINARY): $(SDPARM_DIR)/$(SDPARM_BINARY)
	rm -f $(TARGET_DIR)/$(SDPARM_TARGET_BINARY)
	$(INSTALL) -D -m 0755 $(SDPARM_DIR)/$(SDPARM_BINARY) $(TARGET_DIR)/$(SDPARM_TARGET_BINARY)
ifeq ($(BR2_HAVE_MANPAGES),y)
	$(INSTALL) -D $(SDPARM_DIR)/sdparm.8 $(TARGET_DIR)/usr/share/man/man8/sdparm.8
endif
	$(STRIPCMD) $(STRIP_STRIP_ALL) $@

sdparm: uclibc $(TARGET_DIR)/$(SDPARM_TARGET_BINARY)

sdparm-clean:
	-$(MAKE) -C $(SDPARM_DIR) clean
	rm -f $(TARGET_DIR)/$(SDPARM_TARGET_BINARY)

sdparm-dirclean:
	rm -rf $(SDPARM_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_SDPARM)),y)
TARGETS+=sdparm
endif
