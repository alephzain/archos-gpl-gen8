ifeq ($(ARCH),arm)
#############################################################
#
# ffmpeg_tiny (now using libav.org)
#
#############################################################
FFMPEG_TINY_SOURCE=libav_f1f60f5252b0b448adcce0c1c52f3161ee69b9bf.tgz
FFMPEG_TINY_CAT:=$(ZCAT)
FFMPEG_TINY_DIR:=$(BUILD_DIR)/ffmpeg_tiny

FFMPEG_TINY_LIBAVCODEC_REV=52
FFMPEG_TINY_LIBAVFORMAT_REV=52
FFMPEG_TINY_LIBAVUTIL_REV=50

$(FFMPEG_TINY_DIR)/.unpacked: $(DL_DIR)/$(FFMPEG_TINY_SOURCE)
	$(FFMPEG_TINY_CAT) $(DL_DIR)/$(FFMPEG_TINY_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	mv $(BUILD_DIR)/libav $(FFMPEG_TINY_DIR)
	toolchain/patch-kernel.sh $(FFMPEG_TINY_DIR) package/ffmpeg_tiny/ \*.patch
	touch $@

$(FFMPEG_TINY_DIR)/.configured: $(FFMPEG_TINY_DIR)/.unpacked
	(cd $(FFMPEG_TINY_DIR); \
	$(TARGET_CONFIGURE_OPTS) \
	$(TARGET_CONFIGURE_ARGS) \
	./configure \
	--arch=$(ARCH) \
	--cc=$(TARGET_CC) \
	--target-os=linux \
	--enable-cross-compile \
	--extra-cflags="-fPIC -DPIC -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=softfp" \
	--prefix=/usr  \
	--libdir=/usr/lib \
	--enable-shared \
	--disable-bzlib \
	--disable-sse \
	--disable-ffmpeg --disable-ffplay --disable-ffserver --disable-ffprobe \
	--disable-libfaac \
	--disable-muxers \
	--disable-demuxers \
	--disable-parsers \
	--disable-bsfs \
	--disable-protocols \
	--disable-devices \
	--disable-filters \
	--disable-encoders \
	--disable-decoders \
	\
	--enable-decoder=cook \
	--enable-decoder=flac \
	--enable-decoder=dca \
	--enable-decoder=ac3 \
	--enable-decoder=aac \
	--enable-decoder=mp2 \
	--enable-decoder=mp3 \
	\
	--enable-decoder=msmpeg4v1 \
	--enable-decoder=msmpeg4v2 \
	--enable-decoder=msmpeg4v3 \
	--enable-decoder=h263 \
	--enable-decoder=h264 \
	--enable-decoder=mpeg4 \
	--enable-decoder=mpegvideo \
	--enable-decoder=mpeg1video \
	--enable-decoder=mpeg2video \
	--enable-decoder=flv \
	--enable-decoder=rv10 \
	--enable-decoder=rv20 \
	--enable-decoder=rv30 \
	--enable-decoder=rv40 \
	--enable-decoder=mjpeg \
	--enable-decoder=vp6f \
	\
	--enable-demuxer=avi \
	--enable-demuxer=matroska \
	--enable-demuxer=rtsp \
	--enable-demuxer=sdp \
	--enable-demuxer=aac \
	--enable-demuxer=ac3 \
	--enable-demuxer=mp3 \
	--enable-demuxer=h261 \
	--enable-demuxer=h263 \
	--enable-demuxer=h264 \
	--enable-demuxer=mpegts \
	--enable-demuxer=mpegtsraw \
	--enable-demuxer=mpegps \
	--enable-demuxer=mpegvideo \
	\
	--enable-protocol=file \
	--enable-protocol=http \
	--enable-protocol=rtp \
	--enable-protocol=tcp \
	--enable-protocol=udp \
	\
	--enable-parser=aac \
	--enable-parser=h261 \
	--enable-parser=h263 \
	--enable-parser=h264 \
	--enable-parser=mpeg4video \
	--enable-parser=mpegaudio \
	--enable-parser=mpegvideo \
	--enable-parser=flac \
	\
	--disable-static \
	--disable-mmx \
	--disable-stripping \
	--disable-symver \
	--enable-memalign-hack );
	touch $@

$(FFMPEG_TINY_DIR)/.compiled: $(FFMPEG_TINY_DIR)/.configured
	$(MAKE) -C $(FFMPEG_TINY_DIR)
	touch $@

$(TARGET_DIR)/usr/lib/libavcodec.so.$(FFMPEG_TINY_LIBAVCODEC_REV): $(FFMPEG_TINY_DIR)/.compiled
	cp $(FFMPEG_TINY_DIR)/libavcodec/libavcodec.so.$(FFMPEG_TINY_LIBAVCODEC_REV) $@
	rm -f $(TARGET_DIR)/usr/lib/libavcodec.so && ln -s $(@F) $(TARGET_DIR)/usr/lib/libavcodec.so

$(TARGET_DIR)/usr/lib/libavformat.so.$(FFMPEG_TINY_LIBAVFORMAT_REV): $(FFMPEG_TINY_DIR)/.compiled
	cp $(FFMPEG_TINY_DIR)/libavformat/libavformat.so.$(FFMPEG_TINY_LIBAVFORMAT_REV) $@
	rm -f $(TARGET_DIR)/usr/lib/libavformat.so && ln -s $(@F) $(TARGET_DIR)/usr/lib/libavformat.so

$(TARGET_DIR)/usr/lib/libavutil.so.$(FFMPEG_TINY_LIBAVUTIL_REV): $(FFMPEG_TINY_DIR)/.compiled
	cp $(FFMPEG_TINY_DIR)/libavutil/libavutil.so.$(FFMPEG_TINY_LIBAVUTIL_REV) $@
	rm -f $(TARGET_DIR)/usr/lib/libavutil.so && ln -s $(@F) $(TARGET_DIR)/usr/lib/libavutil.so

$(FFMPEG_TINY_DIR)/.installed: $(TARGET_DIR)/usr/lib/libavformat.so.$(FFMPEG_TINY_LIBAVFORMAT_REV) $(TARGET_DIR)/usr/lib/libavcodec.so.$(FFMPEG_TINY_LIBAVCODEC_REV) $(TARGET_DIR)/usr/lib/libavutil.so.$(FFMPEG_TINY_LIBAVUTIL_REV)
	DESTDIR=$(STAGING_DIR) $(MAKE) -C $(FFMPEG_TINY_DIR) install
	touch $@

ffmpeg_tiny: uclibc $(FFMPEG_TINY_DIR)/.installed 

ffmpeg_tiny-clean:
	rm -f $(STAGING_DIR)/usr/liblibav*
	rm -f $(TARGET_DIR)/usr/lib/libav*
	rm -rf $(STAGING_DIR)/usr/include/ffmpeg
	-$(MAKE) -C $(FFMPEG_TINY_DIR) clean
	rm -f $(FFMPEG_TINY_DIR)/.configured
	rm -f $(FFMPEG_TINY_DIR)/.compiled
	rm -f $(FFMPEG_TINY_DIR)/.installed

ffmpeg_tiny-dirclean:
	rm -rf $(FFMPEG_TINY_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_FFMPEG_TINY)),y)
TARGETS+=ffmpeg_tiny
endif
endif
