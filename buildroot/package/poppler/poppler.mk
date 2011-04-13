#############################################################
#
# poppler
#
#############################################################

POPPLER_VERSION:=0.5.1
POPPLER_SOURCE:=poppler-$(POPPLER_VERSION).tar.gz
POPPLER_SITE:=http://poppler.freedesktop.org
POPPLER_DIR:=$(BUILD_DIR)/poppler-$(POPPLER_VERSION)
POPPLER_CAT:=$(ZCAT)

POPPLER_TARGET_DIR:=$(TARGET_DIR)
POPPLER_PREFIX=/opt/usr

# Build with -O2. APDF crashes on target if poppler is built with -Os.
POPPLER_CFLAGS:=-O2

$(DL_DIR)/$(POPPLER_SOURCE):
	$(WGET) -P $(DL_DIR) $(POPPLER_SITE)/$(POPPLER_SOURCE)

$(POPPLER_DIR)/.unpacked: $(DL_DIR)/$(POPPLER_SOURCE)
	$(POPPLER_CAT) $(DL_DIR)/$(POPPLER_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(POPPLER_DIR) package/poppler/ \*.patch
	touch $(POPPLER_DIR)/.unpacked

#
# Behold! Right know the poppler autoconf system fails
# to detect the QT library. The reason is that it's looking
# for libqte.so but we have libqte-mt.so.
# I principle it should be a piece of cake to change the name
# in configure.ac. Unfortunatly the autotools fail
# to remake everything.
# For now i fixed it with a symbolic link in $QTDIR/lib
#

$(POPPLER_DIR)/.configured: $(POPPLER_DIR)/.unpacked
	(cd $(POPPLER_DIR); rm -rf config.cache; \
	/usr/bin/aclocal && \
	/usr/bin/automake --add-missing && \
	/usr/bin/autoreconf && \
	libtoolize -c -f && \
	$(TARGET_CONFIGURE_OPTS) \
	CPPFLAGS="-I$(STAGING_DIR)/usr/include" \
	CFLAGS="$(TARGET_CFLAGS) $(POPPLER_CFLAGS)" \
	CXXFLAGS="$(POPPLER_CFLAGS) -DQWS -fno-rtti" \
	PKG_CONFIG_PATH=$(STAGING_DIR)/usr/lib/pkgconfig/ \
	LDFLAGS="-L$(STAGING_DIR)/lib -L$(STAGING_DIR)/usr/lib -fno-rtti" \
	QTDIR=$(BUILD_DIR)/qt-2.3.10 \
	QTLIB=$QTDIR/lib \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--disable-poppler-qt4 \
	--disable-gtk-test \
	--disable-utils \
	--prefix=$(POPPLER_PREFIX) \
	--enable-zlib \
	--disable-poppler-glib \
	--disable-cairo-output )
	touch  $(POPPLER_DIR)/.configured

$(POPPLER_DIR)/.compiled: $(POPPLER_DIR)/.configured
	(cd $(POPPLER_DIR); \
	$(TARGET_CONFIGURE_OPTS) \
	CPPFLAGS="-I$(STAGING_DIR)/usr/include" \
	CFLAGS="$(TARGET_CFLAGS) $(POPPLER_CFLAGS)"\
	CXXFLAGS="$(POPPLER_CFLAGS) -DQWS -fno-rtti" \
	PKG_CONFIG_PATH=$(STAGING_DIR)/usr/lib/pkgconfig/ \
	LDFLAGS="-L$(STAGING_DIR)/lib -L$(STAGING_DIR)/usr/lib -fno-rtti" \
	QTDIR=$(BUILD_DIR)/qt-2.3.10 \
	QTLIB=$QTDIR/lib \
	$(MAKE) -C $(POPPLER_DIR) )
	touch $(POPPLER_DIR)/.compiled

$(STAGING_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so: $(POPPLER_DIR)/.compiled
	$(MAKE) -C $(POPPLER_DIR) install DESTDIR=$(STAGING_DIR)
	touch -c $(STAGING_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so

$(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so: $(STAGING_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so
	mkdir -p $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/
	cp -dpf $(STAGING_DIR)$(POPPLER_PREFIX)/lib/libpoppler*so* $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/libpoppler-qt.so

poppler: uclibc expat fontconfig freetype qte $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/libpoppler.so

poppler-clean:
	-$(MAKE) DESTDIR=$(STAGING_DIR) CC=$(TARGET_CC) -C $(POPPLER_DIR) uninstall
	-rm $(POPPLER_TARGET_DIR)$(POPPLER_PREFIX)/lib/libpoppler*
	-$(MAKE) -C $(POPPLER_DIR) clean

poppler-dirclean:
	rm -rf $(POPPLER_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_POPPLER)),y)
TARGETS+=poppler
endif
