TINYMAIL_DIR:=$(BUILD_DIR)/libtinymail
TINYMAIL_SOURCE:=libtinymail.tar.bz2

TINYMAIL_LIBS := \
	libtinymail-1.0.so \
	libtinymailui-1.0.so \
	libtinymail-camel-1.0.so \
	libcamel-lite-1.2.so \
	camel-lite-1.2/camel-providers/libcamelimap.so \
	camel-lite-1.2/camel-providers/libcamellocal.so \
	camel-lite-1.2/camel-providers/libcamelnntp.so \
	camel-lite-1.2/camel-providers/libcamelpop3.so \
	camel-lite-1.2/camel-providers/libcamelsendmail.so \
	camel-lite-1.2/camel-providers/libcamelsmtp.so
TINYMAIL_TARGETS := $(foreach TINYMAIL_LIB,$(TINYMAIL_LIBS),$(TARGET_DIR)/usr/lib/$(TINYMAIL_LIB))
TINYMAIL_CLEAN_TARGETS := $(foreach TINYMAIL_TARGET,$(TINYMAIL_TARGETS),$(TINYMAIL_TARGET)*)

ifeq ($(BUILD),DEBUG)
TINYMAIL_TARGET_CFLAGS=-g -O0 -DDBC $(TARGET_CFLAGS:-O%=-DDEBUG)
TINYMAIL_TARGET_CONFIGURE_OPTS=$(TARGET_CONFIGURE_OPTS:-O%=)
else
TINYMAIL_TARGET_CFLAGS=-DG_DISABLE_ASSERT
TINYMAIL_TARGET_CONFIGURE_OPTS=
endif

ICONV_CONF_MAGIC= --with-libiconv=gnu --with-iconv-detect-h=$(BUILD_DIR)/../package/tinymail/iconv-detect.h

$(DL_DIR)/$(TINYMAIL_SOURCE):
	@echo "ERROR: $@ is not found" && false
	#$(WGET) -P $(DL_DIR) $(TINYMAIL_SITE)/$(TINYMAIL_SOURCE)

TINYMAIL-source: $(DL_DIR)/$(TINYMAIL_SOURCE)

$(TINYMAIL_DIR)/.unpacked: $(DL_DIR)/$(TINYMAIL_SOURCE)
	rm -rf $(TINYMAIL_DIR)
	tar -C $(BUILD_DIR) -j $(TAR_OPTIONS) $(DL_DIR)/$(TINYMAIL_SOURCE)
	toolchain/patch-kernel.sh $(TINYMAIL_DIR) package/tinymail \*.patch
	touch $(TINYMAIL_DIR)/.unpacked

$(TINYMAIL_DIR)/.configured: $(TINYMAIL_DIR)/.unpacked
	( \
	cd $(TINYMAIL_DIR); \
	$(TINYMAIL_TARGET_CONFIGURE_OPTS) \
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) \
	LDFLAGS="${TARGET_LDFLAGS}" \
	CFLAGS="$(TINYMAIL_TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include" \
	CPPFLAGS="${TARGET_CPPFLAGS}" \
	LIBTINYMAIL_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	LIBTINYMAIL_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	TINYMAIL_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	TINYMAIL_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	LIBTINYMAILUI_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	LIBTINYMAILUI_LIBS="-L$(STAGING_DIR)/usr/lib/ " \
	LIBTINYMAIL_CAMEL_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	LIBTINYMAIL_CAMEL_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	LIBTINYMAILUI_GTK_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	LIBTINYMAILUI_GTK_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	E_DATA_SERVER_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	E_DATA_SERVER_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	CAMEL_CFLAGS="-I$(STAGING_DIR)/include/glib-2.0/ -I$(STAGING_DIR)/lib/glib-2.0/include/ -I$(STAGING_DIR)/usr/include" \
	CAMEL_LIBS="-L$(STAGING_DIR)/usr/lib/" \
	ac_cv_path_PKG_CONFIG=/bin/true \
	ac_cv_libiconv_utf8=yes \
	./configure \
	--with-platform=none \
	--disable-gnome \
	--with-html-component=none \
	--disable-uigtk \
	--disable-gtk-doc \
	--disable-demoui \
	--with-ssl=openssl \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--prefix=/usr \
	--enable-shared \
	--disable-static \
	--enable-ipv6=no \
	$(ICONV_CONF_MAGIC) ; \
	)
	touch $(TINYMAIL_DIR)/.configured

$(TINYMAIL_DIR)/.build: $(TINYMAIL_DIR)/.configured
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) CFLAGS="-I$(STAGING_DIR)/include" $(MAKE) -C $(TINYMAIL_DIR)
	#build iconv-detect so we can use it manually for generating
	#iconv-detect.h. This should only need updating if libiconv is upgraded
	PATH=$(STAGING_DIR)/arm-linux-uclibc/bin:$(PATH) $(TARGET_CC) ${TARGET_LDFLAGS} ${TINYMAIL_TARGET_CFLAGS} -liconv -I$(STAGING_DIR)/usr/include $(TINYMAIL_DIR)/libtinymail-camel/camel-lite/iconv-detect.c -o $(TINYMAIL_DIR)/libtinymail-camel/camel-lite/iconv-detect
	touch $(TINYMAIL_DIR)/.build

TINYMAIL_STAGING_LIB=$(STAGING_DIR)/usr/lib/$(firstword $(TINYMAIL_LIBS))

$(TINYMAIL_STAGING_LIB): $(TINYMAIL_DIR)/.build
	$(MAKE) -C $(TINYMAIL_DIR) install DESTDIR=$(STAGING_DIR)

$(TARGET_DIR)/usr/lib/camel-lite-1.2/camel-providers:
	mkdir -p $@

$(TARGET_DIR)/usr/lib/camel-lite-1.2/camel-providers/%: $(TINYMAIL_STAGING_LIB) $(TARGET_DIR)/usr/lib/camel-lite-1.2/camel-providers
	cp -dpf $(STAGING_DIR)/usr/lib/camel-lite-1.2/camel-providers/$** $(TARGET_DIR)/usr/lib/camel-lite-1.2/camel-providers
	cp -pf $(patsubst %.so,%.urls,$(STAGING_DIR)/usr/lib/camel-lite-1.2/camel-providers/$*) $(TARGET_DIR)/usr/lib/camel-lite-1.2/camel-providers
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

$(TARGET_DIR)/usr/lib/%: $(TINYMAIL_STAGING_LIB)
	cp -dpf $(STAGING_DIR)/usr/lib/$** $(TARGET_DIR)/usr/lib
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

tinymail: uclibc $(TINYMAIL_TARGETS)

tinymail-clean:
	rm -f $(TINYMAIL_CLEAN_TARGETS)
	-$(MAKE) -C $(TINYMAIL_DIR) DESTDIR=$(STAGING_DIR) uninstall
	-$(MAKE) -C $(TINYMAIL_DIR) clean

tinymail-dirclean:
	rm -rf $(TINYMAIL_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_TINYMAIL)),y)
TARGETS+=tinymail
endif
