#############################################################
#                          
# PIDGIN                          
#                          
#############################################################
PIDGIN_VERSION:=2.5.2
PIDGIN_SOURCE:=pidgin-$(PIDGIN_VERSION).tar.bz2
PIDGIN_SITE:=http://downloads.sourceforge.net/pidgin
PIDGIN_DIR:=$(BUILD_DIR)/pidgin-$(PIDGIN_VERSION)

export ICONV=/usr/bin/iconv

$(DL_DIR)/$(PIDGIN_SOURCE):
	$(WGET) -P $(DL_DIR) $(PIDGIN_SITE)/$(PIDGIN_SOURCE)


$(PIDGIN_DIR)/.unpacked: $(DL_DIR)/$(PIDGIN_SOURCE)
	bzcat $(DL_DIR)/$(PIDGIN_SOURCE) | tar -C $(BUILD_DIR) -xf -
	toolchain/patch-kernel.sh $(PIDGIN_DIR) package/pidgin/ pidgin-\*.patch
	touch $@


$(PIDGIN_DIR)/.configured: $(PIDGIN_DIR)/.unpacked                          
	(cd $(PIDGIN_DIR); \
	rm -rf config.cache; \
	#$(TARGET_CONFIGURE_OPTS) \
	#$(TARGET_CONFIGURE_ARGS) \
	env $(TARGET_CONFIGURE_OPTS) \
	PKG_CONFIG_PATH=$(STAGING_DIR)/lib/pkgconfig \
	CFLAGS="$(TARGET_CFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS) " \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr \
	--libdir=$(STAGING_DIR)/usr/lib \
	--includedir=$(STAGING_DIR)/usr/include \
	--disable-consoleui \
	--disable-gtkui \
	--disable-screensaver \
	--disable-gtkspell \
	--disable-sm \
	--disable-gevolution \
	--disable-gestures \
	--disable-startup-notification \
	--disable-gstreamer \
	--disable-meanwhile \
	--disable-avahi \
	--disable-plugins \
	--disable-nm \
	--disable-fortify \
	--disable-perl \
	--disable-schemas-install \
	--disable-tcl \
	--disable-tk \
	--disable-pixmaps-install \
	--disable-nls \
	--disable-doxygen \
	--disable-debug \
	--disable-devhelp \
	--disable-dot \
	--disable-mono \
	--disable-cap \
	--enable-nss=no \
	--without-x \
	--with-dynamic-prpls=irc,jabber,msn,oscar,yahoo \
	--with-gnutls-includes=$(STAGING_DIR)/usr/include \
	--with-gnutls-libs=$(STAGING_DIR)/usr/ \
	)
	touch $@


$(PIDGIN_DIR)/.compiled: $(PIDGIN_DIR)/.configured
	$(MAKE) CXX=$(TARGET_CXX) CC=$(TARGET_CC) -C $(PIDGIN_DIR)
	touch $@


$(PIDGIN_DIR)/.installed: $(PIDGIN_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(PIDGIN_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libpurple.so* $(TARGET_DIR)/usr/lib/
	touch $@


pidgin: uclibc libxml2 gnutls $(PIDGIN_DIR)/.installed


pidgin-source: $(DL_DIR)/$(PIDGIN_SOURCE)


pidgin-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(PIDGIN_DIR) uninstall
	rm -f $(TARGET_DIR)/usr/lib/libpurple.so*
	-$(MAKE) -C $(PIDGIN_DIR) clean


pidgin-dirclean:
	rm -rf $(PIDGIN_DIR)


#############################################################
#                          
# Toplevel Makefile options                          
#                          
#############################################################
ifeq ($(strip $(BR2_PACKAGE_PIDGIN)),y)
TARGETS+=pidgin
endif
