#############################################################
#
# elinks (text based web browser)
#
#############################################################
ELINKS_SITE:=http://elinks.or.cz/download
ELINKS_SOURCE:=elinks-0.11.4rc0.tar.bz2
ELINKS_DIR:=$(BUILD_DIR)/elinks-0.11.4rc0

$(DL_DIR)/$(ELINKS_SOURCE):
	$(WGET) -P $(DL_DIR) $(ELINKS_SITE)/$(ELINKS_SOURCE)

elinks-source: $(DL_DIR)/$(ELINKS_SOURCE)

$(ELINKS_DIR)/.unpacked: $(DL_DIR)/$(ELINKS_SOURCE)
	bzcat $(DL_DIR)/$(ELINKS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(ELINKS_DIR) package/elinks \*.patch
	touch  $(ELINKS_DIR)/.unpacked

$(ELINKS_DIR)/.configured: $(ELINKS_DIR)/.unpacked
	(cd $(ELINKS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/tmp \
		--mandir=/usr/man \
		--infodir=/usr/info \
		$(DISABLE_NLS) \
		--without-xterm \
		--without-gpm \
		--without-zlib \
		--without-bzlib \
		--without-idn \
		--without-spidermonkey \
		--without-guile \
		--without-perl \
		--without-python \
		--without-lua  \
		--without-ruby \
		--without-gnutls \
		--without-openssl \
		--without-x \
		--disable-bookmarks \
		--disable-xbel \
		--disable-sm-scripting \
		--disable-cookies \
		--disable-formhist \
		--disable-globhist \
		--disable-mailcap \
		--disable-mimetypes \
		--disable-ipv6 \
		--disable-bittorrent \
		--disable-data \
		--disable-uri-rewrite \
		--disable-cgi \
		--disable-finger \
		--disable-fsp \
		--disable-ftp \
		--disable-gopher \
		--disable-nntp \
		--disable-smb \
		--disable-mouse \
		--disable-sysmouse \
		--disable-88-colors \
		--disable-256-colors \
		--disable-leds \
		--disable-marks \
		--enable-css \
		--disable-backtrace \
		--enable-fastmem \
		--enable-small \
	);
	touch  $(ELINKS_DIR)/.configured

$(ELINKS_DIR)/src/elinks: $(ELINKS_DIR)/.configured
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS)" \
	$(MAKE) -C $(ELINKS_DIR)
	$(STRIPCMD) $(ELINKS_DIR)/src/elinks

$(TARGET_DIR)/usr/bin/elinks: $(ELINKS_DIR)/src/elinks
	install -c $(ELINKS_DIR)/src/elinks $(TARGET_DIR)/usr/bin/elinks

elinks-clean: 
	$(MAKE) -C $(ELINKS_DIR) clean

elinks-dirclean: 
	rm -rf $(ELINKS_DIR)

elinks: uclibc $(TARGET_DIR)/usr/bin/elinks

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ELINKS)),y)
TARGETS+=elinks
endif
