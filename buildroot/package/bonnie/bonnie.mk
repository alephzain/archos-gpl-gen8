#############################################################
#
# bonnie++
#
#############################################################
BONNIE_VER:=1.03a
BONNIE_SOURCE:=bonnie++-$(BONNIE_VER).tgz
BONNIE_SITE:=http://www.coker.com.au/bonnie++/
BONNIE_DIR:=$(BUILD_DIR)/bonnie++-$(BONNIE_VER)
ifeq ($(BR2_LARGEFILE),y)
BONNIE_CFLAGS+=-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64
endif

$(DL_DIR)/$(BONNIE_SOURCE):
	$(WGET) -P $(DL_DIR) $(BONNIE_SITE)/$(BONNIE_SOURCE)

$(BONNIE_DIR)/.source: $(DL_DIR)/$(BONNIE_SOURCE)
	zcat $(DL_DIR)/$(BONNIE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BONNIE_DIR) package/bonnie/ bonnie\*.patch
	touch $(BONNIE_DIR)/.source

$(BONNIE_DIR)/.configured: $(BONNIE_DIR)/.source
	(cd $(BONNIE_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(BONNIE_CFLAGS)" \
		./configure \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/lib \
		--includedir=$(STAGING_DIR)/include \
	);
	touch $(BONNIE_DIR)/.configured;

$(BONNIE_DIR)/bonnie++: $(BONNIE_DIR)/.configured
	PATH=$(PATH):$(STAGING_DIR)/usr/bin make -C $(BONNIE_DIR)

$(TARGET_DIR)/usr/bin/bonnie++: $(BONNIE_DIR)/bonnie++
	test -d $(TARGET_DIR)/usr/bin || mkdir -p $(TARGET_DIR)/usr/bin
	cp $(BONNIE_DIR)/bonnie++ $(TARGET_DIR)/usr/bin/bonnie++
	$(STRIPCMD) $(TARGET_DIR)/usr/bin/bonnie++

bonnie: uclibc $(TARGET_DIR)/usr/bin/bonnie++

bonnie-source: $(DL_DIR)/$(BONNIE_SOURCE)

bonnie-clean:
	rm -f $(TARGET_DIR)/usr/bin/bonnie++
	-$(MAKE) -C $(BONNIE_DIR) clean

bonnie-dirclean:
	rm -rf $(BONNIE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BONNIE)),y)
TARGETS+=bonnie
endif
