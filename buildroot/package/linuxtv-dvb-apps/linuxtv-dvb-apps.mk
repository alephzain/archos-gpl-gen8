#############################################################
#
# linuxtv-dvb-apps
#
#############################################################

# TARGETS
LINUXTV-DVB-APPS_VERSION:=hg-03042008
LINUXTV-DVB-APPS_SOURCE:=linuxtv-dvb-apps-$(LINUXTV-DVB-APPS_VERSION).tar.gz
LINUXTV-DVB-APPS_DIR:=$(BUILD_DIR)/linuxtv-dvb-apps-$(LINUXTV-DVB-APPS_VERSION)
LINUXTV-DVB-APPS_OPTIONS:=
LINUXTV-DVB-APPS_BINARY:=dvbscan
LINUXTV-DVB-APPS_ALL_BINARIES:=dib3000-watch dvbdate dvbnet dvbscan dvbtraffic gnutv scan tzap zap 
LINUXTV-DVB-APPS_ALL_LIBS:=libdvbapi.so libdvbcfg.so libdvben50221.so libdvbsec.so libesg.so libucsi.so
LINUXTV-DVB-APPS_ALL_FREQ_COUNTRIES:=fr de
LINUXTV_DVB-APPS_SUPP_DIR=package/linuxtv-dvb-apps/root

$(LINUXTV-DVB-APPS_DIR)/.unpacked: $(DL_DIR)/$(LINUXTV-DVB-APPS_SOURCE)
	zcat $(DL_DIR)/$(LINUXTV-DVB-APPS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LINUXTV-DVB-APPS_DIR) package/linuxtv-dvb-apps/ \*.patch
	touch $(LINUXTV-DVB-APPS_DIR)/.unpacked
	
$(LINUXTV-DVB-APPS_DIR)/util/scan/scan: $(LINUXTV-DVB-APPS_DIR)/.unpacked
	$(MAKE)  $(TARGET_CONFIGURE_OPTS) -C $(LINUXTV-DVB-APPS_DIR)
	
$(STAGING_DIR)/usr/bin/$(LINUXTV-DVB-APPS_BINARY): $(LINUXTV-DVB-APPS_DIR)/util/scan/scan
	$(MAKE)	DESTDIR=$(STAGING_DIR) -C $(LINUXTV-DVB-APPS_DIR) install

$(TARGET_DIR)/usr/bin/$(LINUXTV-DVB-APPS_BINARY): $(STAGING_DIR)/usr/bin/$(LINUXTV-DVB-APPS_BINARY)
	# Install local skeleton for archos scripts
	tar cf - -C $(LINUXTV_DVB-APPS_SUPP_DIR) . | tar x --exclude .svn -C $(TARGET_DIR)
	for binary in $(LINUXTV-DVB-APPS_ALL_BINARIES); do \
		echo Installing $$binary ; \
		install -m 0755 $(STAGING_DIR)/usr/bin/$$binary $(TARGET_DIR)/usr/bin/$$binary ; \
		$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/bin/$$binary ; \
	done
	for lib in $(LINUXTV-DVB-APPS_ALL_LIBS); do \
		echo Installing $$lib ; \
		install -m 0755 $(STAGING_DIR)/usr/lib/$$lib $(TARGET_DIR)/usr/lib/$$lib ; \
		$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/lib/$$lib ; \
	done
	mkdir -p $(TARGET_DIR)/usr/share/dvb/dvb-t
	for country in $(LINUXTV-DVB-APPS_ALL_FREQ_COUNTRIES); do \
		echo Installing frequency files for $$country ; \
		cp $(STAGING_DIR)/usr/share/dvb/dvb-t/$$country* $(TARGET_DIR)/usr/share/dvb/dvb-t ;\
	done

linuxtv-dvb-apps: uclibc $(TARGET_DIR)/usr/bin/$(LINUXTV-DVB-APPS_BINARY)

linuxtv-dvb-apps-source: $(DL_DIR)/$(LINUXTV-DVB-APPS_SOURCE)

linuxtv-dvb-apps-clean: 
	rm -rf  $(TARGET_DIR)/usr/share/dvb/dvb-t
	rm -rf  $(STAGING_DIR)/usr/share/dvb/dvb-t
	for binary in $(LINUXTV-DVB-APPS_ALL-BINARIES); do \
		rm -f $(TARGET_DIR)/usr/bin/$$binary; \
		rm -f $(STAGING_DIR)/usr/bin/$$binary; \
	done
	for lib in $(LINUXTV-DVB-APPS_ALL-LIBS); do \
		rm -f $(TARGET_DIR)/usr/bin/$$lib; \
		rm -f $(STAGING_DIR)/usr/bin/$$lib; \
	done

	# Remove local skeleton
	- ( cd package/linuxtv-dvb-apps/root && find . -type f -exec rm $(TARGET_DIR)/{} \; ) 
	$(MAKE) -C $(LINUXTV-DVB-APPS_DIR) clean

linuxtv-dvb-apps-dirclean:
	rm -rf $(LINUXTV-DVB-APPS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LINUXTV-DVB-APPS)),y)
TARGETS+=linuxtv-dvb-apps
endif
