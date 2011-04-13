#############################################################
#
# qte: Qt/E build, includes Qt/E-2, QVfb
#
#############################################################
ifeq ($(BR2_QTE_VERSION),)
BR2_QTE_VERSION:=FOOBAR1
endif
ifeq ($(BR2_QTE_QT3_VERSION),)
BR2_QTE_QT3_VERSION:=FOOBAR2
endif
ifeq ($(BR2_QTE_QVFB_VERSION),)
BR2_QTE_QVFB_VERSION:=FOOBAR3
endif
ifeq ($(BR2_QTE_TMAKE_VERSION),)
BR2_QTE_TMAKE_VERSION:=FOOBAR5
endif

BR2_QTE_C_QTE_VERSION:=$(shell echo $(BR2_QTE_VERSION)| sed -e 's/"//g')
BR2_QTE_C_QT3_VERSION:=$(shell echo $(BR2_QTE_QT3_VERSION)| sed -e 's/"//g')
BR2_QTE_C_QVFB_VERSION:=$(shell echo $(BR2_QTE_QVFB_VERSION)| sed -e 's/"//g')
BR2_QTE_C_TMAKE_VERSION:=$(shell echo $(BR2_QTE_TMAKE_VERSION)| sed -e 's/"//g')

ifeq ($(BR2_QTE_COMMERCIAL),)
QTE_QTE_SOURCE:=qt-embedded-$(BR2_QTE_C_QTE_VERSION)-free.tar.gz
QTE_QT3_SOURCE:=qt-$(BR2_QTE_C_QT3_VERSION)-free.tar.gz
QTE_QVFB_SOURCE:=qt-x11-$(BR2_QTE_C_QVFB_VERSION).tar.gz
QTE_SITE:=ftp://ftp.trolltech.com/qt/source/
else
QTE_QTE_SOURCE:=qt-embedded-$(BR2_QTE_C_QTE_VERSION)-commercial.tar.gz
QTE_QT3_SOURCE:=qt-$(BR2_QTE_C_QT3_VERSION)-commercial.tar.gz
QTE_QVFB_SOURCE:=qt-x11-$(BR2_QTE_C_QVFB_VERSION)-commercial.tar.gz
BR2_QTE_C_USERNAME:=$(shell echo $(BR2_PACKAGE_QTE_COMMERCIAL_USERNAME)| sed -e 's/"//g')
BR2_QTE_C_PASSWORD:=$(shell echo $(BR2_PACKAGE_QTE_COMMERCIAL_PASSWORD)| sed -e 's/"//g')
QTE_SITE:=http://$(BR2_QTE_C_USERNAME):$(BR2_QTE_C_PASSWORD)@dist.trolltech.com/$(BR2_QTE_C_USERNAME)
endif

QTE_TMAKE_SOURCE:=tmake-$(BR2_QTE_C_TMAKE_VERSION).tar.gz
QTE_QTE_DIR:=$(BUILD_DIR)/qt-$(BR2_QTE_C_QTE_VERSION)
QTE_QT3_DIR:=$(BUILD_DIR)/qt-$(BR2_QTE_C_QT3_VERSION)
QTE_TMAKE_DIR:=$(BUILD_DIR)/tmake-$(BR2_QTE_C_TMAKE_VERSION)
QTE_QVFB_DIR:=$(BUILD_DIR)/qt-$(BR2_QTE_C_QVFB_VERSION)
TMAKE_SITE:=ftp://ftp.trolltech.com/freebies/tmake/

QTE_TARGET_DIR:=$(TARGET_DIR)

QTE_PREFIX=/opt/usr

QTE_CAT:=zcat
TMAKE:=$(QTE_TMAKE_DIR)/bin/tmake
QTE_UIC_BINARY:=bin/uic
QTE_QVFB_BINARY:=bin/qvfb
QTE_QTE_LIB:=$(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/libqte-mt.so.$(BR2_QTE_C_QTE_VERSION)

# don't include qvfb support for the target build
ifneq (,$(findstring arm,$(BR2_QTE_CROSS_PLATFORM)))
DONT_INC_QVFB:=\#define QT_NO_QWS_VFB
else
DONT_INC_QVFB:=
endif


#############################################################
#
# Calculate configure options... scary eventually, trivial now
#
# currently only tested with threading
# FIXME: I should use the staging directory here, but I don't yet.
#
#############################################################
# I choose to make the link in libqte so that the linking later is trivial -- a user may choose to use -luuid, or not, and it'll just work.
# ...since libqte* needs -luuid anyhow... 
QTE_QTE_CONFIGURE:=-no-xft -no-opengl -no-table -no-canvas
QTE_QVFB_CONFIGURE:=-no-xft -system-zlib -no-opengl -no-network -no-table -no-canvas
QTE_QT3_CONFIGURE:=

ifeq ($(BR2_PTHREADS_NATIVE),y)
QTE_QTE_CONFIGURE:=$(QTE_QTE_CONFIGURE) -thread 
QTE_QVFB_CONFIGURE:=$(QTE_QVFB_CONFIGURE) -thread
QTE_QT3_CONFIGURE:=$(QTE_QT3_CONFIGURE) -thread
endif

ifeq ($(BR2_PTHREADS_OLD),y)
QTE_QTE_CONFIGURE:=$(QTE_QTE_CONFIGURE) -thread 
QTE_QVFB_CONFIGURE:=$(QTE_QVFB_CONFIGURE) -thread
QTE_QT3_CONFIGURE:=$(QTE_QT3_CONFIGURE) -thread
endif

ifeq ($(BR2_PACKAGE_JPEG),y)
QTE_QTE_CONFIGURE:=$(QTE_QTE_CONFIGURE) -system-jpeg
#FIXME: Do I need an else on this?
endif

ifeq ($(BR2_PACKAGE_LIBPNG),y)
QTE_QTE_CONFIGURE:=$(QTE_QTE_CONFIGURE) -system-libpng
else
QTE_QTE_CONFIGURE:=$(QTE_QTE_CONFIGURE) -qt-libpng
endif

#############################################################
#
# Build portion
#
#############################################################

ifneq ($(BR2_QTE_C_QTE_VERSION),$(BR2_QTE_C_QT3_VERSION))
$(DL_DIR)/$(QTE_QT3_SOURCE):
	$(WGET) -P $(DL_DIR) $(QTE_SITE)/$(@F)
endif

$(DL_DIR)/$(QTE_QVFB_SOURCE) :
	$(WGET) -P $(DL_DIR) $(QTE_SITE)/$(@F)

$(DL_DIR)/$(QTE_TMAKE_SOURCE):
	$(WGET) -P $(DL_DIR) $(TMAKE_SITE)/$(QTE_TMAKE_SOURCE)

$(DL_DIR)/$(QTE_QTE_SOURCE):
	$(WGET) -P $(DL_DIR) $(QTE_SITE)/$(@F)

$(QTE_TMAKE_DIR)/.unpacked: $(DL_DIR)/$(QTE_TMAKE_SOURCE)
	$(QTE_CAT) $(DL_DIR)/$(QTE_TMAKE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	rm -rf $(QTE_TMAKE_DIR)/lib/qws/linux-uclibc-g++
	cp -af package/qte/linux-uclibc-g++ $(QTE_TMAKE_DIR)/lib/qws/
	toolchain/patch-kernel.sh $(QTE_TMAKE_DIR) package/qte/ tmake-\*.patch
	sed -i "s,__TOOLCHAIN__,$(STAGING_DIR),g" $(QTE_TMAKE_DIR)/lib/qws/linux-x86-g++/tmake.conf
	touch $@

ifneq ($(BR2_QTE_C_QTE_VERSION),$(BR2_QTE_C_QT3_VERSION))
$(QTE_QT3_DIR)/.unpacked: $(DL_DIR)/$(QTE_QT3_SOURCE)
	$(QTE_CAT) $(DL_DIR)/$(QTE_QT3_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@
endif

# Apply "ugly" patches. Ugly as in: "replace whole file instead of just
# patching a few lines"
$(QTE_QTE_DIR)/.unpacked-ugly: $(DL_DIR)/$(QTE_QTE_SOURCE)
	$(QTE_CAT) $(DL_DIR)/$(QTE_QTE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	cp -f package/qte/qfontfactoryttf_qws.* $(QTE_QTE_DIR)/src/kernel/
	cp -f package/qte/qkeyboard_qws.cpp $(QTE_QTE_DIR)/src/kernel/
	cp -f package/qte/qvfbhdr.h $(QTE_QTE_DIR)/src/kernel/
	cp -f package/qte/qwsmouse_qws.cpp $(QTE_QTE_DIR)/src/kernel/
	cp -f package/qte/qgfxvfb_qws.cpp $(QTE_QTE_DIR)/src/kernel/
	cp -f package/qte/linux-arm-g++-shared* $(QTE_QTE_DIR)/configs/
	cp -f package/qte/linux-uclibc-g++-shared* $(QTE_QTE_DIR)/configs/
	sed "s,__TOOLCHAIN__,$(STAGING_DIR),g" package/qte/qte-systemfreetype.patch.in \
		| (cd $(QTE_QTE_DIR) ; patch -p0 )
	touch $@

$(QTE_QTE_DIR)/.unpacked: $(QTE_QTE_DIR)/.unpacked-ugly
	toolchain/patch-kernel.sh $(QTE_QTE_DIR) package/qte/ qte-\*.patch
	touch $@

$(QTE_QVFB_DIR)/.unpacked: $(DL_DIR)/$(QTE_QVFB_SOURCE)
	$(QTE_CAT) $(DL_DIR)/$(QTE_QVFB_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(QTE_QTE_DIR)/.configured: $(QTE_QTE_DIR)/.unpacked $(QTE_TMAKE_DIR)/.unpacked
	cp -f package/qte/qconfig-local.h $(QTE_QTE_DIR)/src/tools/
	#echo "$(DONT_INC_QVFB)" >> $(QTE_QTE_DIR)/src/tools/qconfig-local.h
	(cd $(@D); export QTDIR=`pwd`; export TMAKEPATH=$(QTE_TMAKE_DIR)/lib/qws/linux-x86-g++; export PATH=$(STAGING_DIR)/bin:$$QTDIR/bin:$$PATH; export LD_LIBRARY_PATH=$$QTDIR/lib:$$LD_LIBRARY_PATH; echo 'yes' | \
		$(TARGET_CONFIGURE_OPTS) CC_FOR_BUILD=$(HOSTCC) \
		CFLAGS="$(TARGET_CFLAGS) -O2" \
		./configure \
		$(QTE_QTE_CONFIGURE) -qconfig local -system-zlib -system-freetype -qvfb -depths 4,8,16,32 -xplatform $(BR2_QTE_CROSS_PLATFORM) \
	);
	touch $@

ifneq ($(BR2_QTE_C_QTE_VERSION),$(BR2_QTE_C_QT3_VERSION))
# this is a host-side build, so we don't use any staging dir stuff, nor any TARGET_CONFIGURE_OPTS
$(QTE_QT3_DIR)/.configured: $(QTE_QT3_DIR)/.unpacked $(QTE_TMAKE_DIR)/.unpacked
	(cd $(@D); export QTDIR=`pwd`; export TMAKEPATH=$(QTE_TMAKE_DIR)/lib/qws/linux-x86-g++; export PATH=$$QTDIR/bin:$$PATH; export LD_LIBRARY_PATH=$$QTDIR/lib:$$LD_LIBRARY_PATH; echo 'yes' | \
		CC_FOR_BUILD=$(HOSTCC) \
		./configure \
		-fast $(QTE_QT3_CONFIGURE) \
	);
	touch $@
endif

$(QTE_QVFB_DIR)/.configured: $(QTE_QVFB_DIR)/.unpacked $(QTE_TMAKE_DIR)/.unpacked
	(cd $(@D); export QTDIR=`pwd`; export TMAKEPATH=$(QTE_TMAKE_DIR)/lib/linux-g++; export PATH=$$QTDIR/bin:$$PATH; export LD_LIBRARY_PATH=$$QTDIR/lib:$$LD_LIBRARY_PATH; echo 'yes' | \
		$(TARGET_CONFIGURE_OPTS) CC_FOR_BUILD=$(HOSTCC) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		$(QTE_QVFB_CONFIGURE) \
	);
	touch $@

# --edition {other}
# This has some kooky logic.  Qtopia requires a Qt <= 3.3.0 to build, yet we like to use s Qt-2.3.x
# for size constraints on an embedded device. This target depends on both $(QTE_QTE_DIR)/$(QTE_UIC_BINARY)
# **and** $(QTE_QT3_DIR)/.configured.   if BR2_QTE_C_QTE_VERSION == BR2_QTE_C_QT3_VERSION, then it really 
# depends on $(QTE_QTE_DIR)/.configured, which $(QTE_QTE_DIR)/$(QTE_UIC_BINARY) needs, so it's redundant.
# If QTE is 3.3.0 or later, then BR2_QTE_C_QTE_VERSION != BR2_QTE_C_QT3_VERSION, then we need to unpack
# the other Qt/E, so this dependency is not redundant.

# there is no build for tmake, only unpack
$(TMAKE): $(QTE_TMAKE_DIR)/.unpacked

# This must NOT use TARGET_CC -- it is a host-side tool
$(QTE_QVFB_DIR)/.make: $(QTE_QVFB_DIR)/.configured $(TMAKE)
	#$(TARGET_CONFIGURE_OPTS)
	export QTDIR=$(QTE_QVFB_DIR); export PATH=$$QTDIR/bin:$$PATH; \
	$(MAKE) -C $(QTE_QVFB_DIR)
	touch $@

$(QTE_QTE_DIR)/$(QTE_UIC_BINARY): $(QTE_QVFB_DIR)/.make $(QTE_QTE_DIR)/.unpacked
	export QTDIR=$(QTE_QVFB_DIR); export PATH=$$QTDIR/bin:$$PATH; \
	$(MAKE) -C $(QTE_QVFB_DIR)/tools/designer/uic
	test -d $(@D) || install -dm 0755 $(@D)
	install -m 0755 $(QTE_QVFB_DIR)/bin/$(@F) $@

ifneq ($(BR2_QTE_C_QTE_VERSION),$(BR2_QTE_C_QT3_VERSION))
$(QTE_QT3_DIR)/.make: $(QTE_QT3_DIR)/.unpacked
	( export QTDIR=$(QTE_QT3_DIR); export PATH=$$QTDIR/bin:$$PATH; export LD_LIBRARY_PATH=$$QTDIR/lib:$$LD_LIBRARY_PATH; \
	$(MAKE) -C $(QTE_QT3_DIR) sub-src && \
	$(MAKE) -C $(QTE_QT3_DIR)/tools/linguist/lrelease \
	$(MAKE) -C $(QTE_QT3_DIR)/tools/linguist/lupdate \
	$(MAKE) -C $(QTE_QT3_DIR)/tools/designer/uilib \
	$(MAKE) -C $(QTE_QT3_DIR)/tools/designer/uic
	);
	touch $@
endif

$(QTE_QTE_DIR)/$(QTE_QVFB_BINARY): $(QTE_QVFB_DIR)/.make $(QTE_QTE_DIR)/.unpacked $(TMAKE)
	(cd $(QTE_QVFB_DIR)/tools/qvfb && TMAKEPATH=$(QTE_TMAKE_DIR)/lib/linux-g++ $(TMAKE) -o Makefile qvfb.pro)
	#$(TARGET_CONFIGURE_OPTS)
	export QTDIR=$(QTE_QVFB_DIR); export PATH=$$QTDIR/bin:$$PATH; \
	$(MAKE) -C $(QTE_QVFB_DIR)/tools/qvfb
	test -d $(@D) || install -dm 0755 $(@D)
	install -m 0755 $(QTE_QVFB_DIR)/tools/qvfb/$(@F) $@

$(QTE_QTE_DIR)/src-mt.mk: $(QTE_QTE_DIR)/.configured
	# I don't like the src-mk that gets built, so blow it away.  Too many includes to override yet
	echo "SHELL=/bin/sh" > $@
	echo "" >> $@
	echo "src-mt:" >> $@
	echo "	cd src; "'$$(MAKE)'" 'QT_THREAD_SUFFIX=-mt' 'QT_LFLAGS_MT="'$$$$(SYSCONF_LFLAGS_THREAD)'" "'$$$$(SYSCONF_LIBS_THREAD)'"' 'QT_CXX_MT="'$$$$(SYSCONF_CXXFLAGS_THREAD)'" -DQT_THREAD_SUPPORT' 'QT_C_MT="'$$$$(SYSCONF_CFLAGS_THREAD)'" -DQT_THREAD_SUPPORT'" >> $@

$(QTE_QTE_DIR)/lib/libqte-mt.so.$(BR2_QTE_C_QTE_VERSION): $(QTE_QTE_DIR)/src-mt.mk
	export QTDIR=$(QTE_QTE_DIR); export PATH=$(STAGING_DIR)/bin:$$QTDIR/bin:$$PATH; \
	$(TARGET_CONFIGURE_OPTS) $(MAKE) $(TARGET_CC) -C $(QTE_QTE_DIR) src-mt
	# ... and make sure it actually built... grrr... make deep-deep-deep makefile recursion for this habit
	test -f $(QTE_QTE_DIR)/lib/libqte-mt.so.$(BR2_QTE_C_QTE_VERSION)
	# this is a cludge. the poppler configure script is broken and looks only for libqte.so
	( cd $(QTE_QTE_DIR)/lib/ ;\
	 ln -sf libqte-mt.so.$(BR2_QTE_C_QTE_VERSION) libqte.so ;\
	 ln -sf libqte-mt.so.$(BR2_QTE_C_QTE_VERSION) libqt-mt.so; \
	)

$(QTE_QTE_LIB): $(QTE_QTE_DIR)/lib/libqte-mt.so.$(BR2_QTE_C_QTE_VERSION)
	mkdir -p $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib
	cp -a $(QTE_QTE_DIR)/lib/lib* $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/

$(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/fonts/fontdir:
	mkdir -p $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/fonts
	cp package/qte/fontdir $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/fonts

qte:: freetype jpeg png $(TMAKE) $(QTE_QTE_LIB) $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/fonts/fontdir

# kinda no-op right now, these are built anyhow
ifeq ($(strip $(BR2_PACKAGE_QTE_QVFB)),y)
qte:: $(QTE_QTE_DIR)/$(QTE_UIC_BINARY) $(QTE_QTE_DIR)/$(QTE_QVFB_BINARY)
endif

qte-clean:
	-rm -f $(QTE_QTE_DIR)/$(QTE_UIC_BINARY) $(QTE_QTE_DIR)/$(QTE_QVFB_BINARY) $(QTE_QTE_LIB)
	-rm -f $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/libqte*
	-rm -rf $(QTE_TARGET_DIR)$(QTE_PREFIX)/lib/fonts
	-$(MAKE) -C $(QTE_QTE_DIR) clean
	-$(MAKE) -C $(QTE_QVFB_DIR) clean
	-rm $(QTE_QTE_DIR)/src-mt.mk
	rm $(QTE_QTE_DIR)/.configured

qte-dirclean:
	rm -rf $(QTE_QTE_DIR) $(QTE_QVFB_DIR) $(QTE_TMAKE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_QTE)),y)
TARGETS+=qte
endif
