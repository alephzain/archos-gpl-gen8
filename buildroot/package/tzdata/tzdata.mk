#############################################################
#
# tzdata
#
#############################################################
TZDATA_VERSION:=2008b
TZCODE_VERSION:=2008a
TZDATA_SOURCE:=tzdata$(TZDATA_VERSION).tar.gz
TZCODE_SOURCE:=tzcode$(TZCODE_VERSION).tar.gz
TZDATA_SITE:=ftp://elsie.nci.nih.gov/pub/
TZDATA_DIR:=$(BUILD_DIR)/tzdata$(TZDATA_VERSION)
TZDATA_CAT:=zcat
SCRIPT:=package/tzdata/process_timezones.sh

$(DL_DIR)/$(TZDATA_SOURCE):
	$(WGET) -P $(DL_DIR) $(TZDATA_SITE)/$(TZDATA_SOURCE)
	$(WGET) -P $(DL_DIR) $(TZDATA_SITE)/$(TZCODE_SOURCE)

#tzdata-source: $(DL_DIR)/$(TZDATA_SOURCE)
#tzcode-source: $(DL_DIR)/$(TZDATA_CODE)

$(TZDATA_DIR)/.unpacked: $(DL_DIR)/$(TZDATA_SOURCE)
	mkdir -p $(TZDATA_DIR)
	$(TZDATA_CAT) $(DL_DIR)/$(TZDATA_SOURCE) | tar -C $(TZDATA_DIR) $(TAR_OPTIONS) -
	$(TZDATA_CAT) $(DL_DIR)/$(TZCODE_SOURCE) | tar -C $(TZDATA_DIR) $(TAR_OPTIONS) -
	touch $(TZDATA_DIR)/.unpacked

tzdata: uclibc $(TZDATA_DIR)/.unpacked
	$(MAKE) -C $(TZDATA_DIR) TOPDIR=$(TZDATA_DIR) posix_only
	chmod +x $(SCRIPT)
	$(SCRIPT) $(TZDATA_DIR)/etc/zoneinfo $(TARGET_DIR)/etc/
	cp -f $(TZDATA_DIR)/zone.tab $(TARGET_DIR)/etc/zoneinfo

tzdata-clean:
	rm -rf $(TARGET_DIR)/etc/zoneinfo
	-$(MAKE) -C $(TZDATA_DIR) clean

tzdata-dirclean:
	rm -rf $(TZDATA_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_TZDATA)),y)
TARGETS+=tzdata
endif

