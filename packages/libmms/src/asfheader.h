/*
 * Copyright (C) 2000-2003 the xine project
 *
 * This file is part of xine, a free video player.
 *
 * xine is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * xine is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 *
 * demultiplexer for asf streams
 *
 * based on ffmpeg's
 * ASF compatible encoder and decoder.
 * Copyright (c) 2000, 2001 Gerard Lantau.
 *
 * GUID list from avifile
 * some other ideas from MPlayer
 */

#ifndef ASFHEADER_H
#define ASFHEADER_H

enum {
	GUID_ERROR = 0,

	/* base ASF objects */
	GUID_ASF_HEADER,
	GUID_ASF_DATA,
	GUID_ASF_SIMPLE_INDEX,
	GUID_INDEX,
	GUID_MEDIA_OBJECT_INDEX,
	GUID_TIMECODE_INDEX,

	/* header ASF objects */
	GUID_ASF_FILE_PROPERTIES,
	GUID_ASF_STREAM_PROPERTIES,
	GUID_ASF_HEADER_EXTENSION,
	GUID_ASF_CODEC_LIST,
	GUID_ASF_SCRIPT_COMMAND,
	GUID_ASF_MARKER,
	GUID_ASF_BITRATE_MUTUAL_EXCLUSION,
	GUID_ASF_ERROR_CORRECTION,
	GUID_ASF_CONTENT_DESCRIPTION,
	GUID_ASF_EXTENDED_CONTENT_DESCRIPTION,
	GUID_ASF_STREAM_BITRATE_PROPERTIES,
	GUID_ASF_EXTENDED_CONTENT_ENCRYPTION,
	GUID_ASF_PADDING,

	 /* stream properties object stream type */
	GUID_ASF_AUDIO_MEDIA,
	GUID_ASF_VIDEO_MEDIA,
	GUID_ASF_COMMAND_MEDIA,
	GUID_ASF_JFIF_MEDIA,
	GUID_ASF_DEGRADABLE_JPEG_MEDIA,
	GUID_ASF_FILE_TRANSFER_MEDIA,
	GUID_ASF_BINARY_MEDIA,

	/* stream properties object error correction type */
	GUID_ASF_NO_ERROR_CORRECTION,
	GUID_ASF_AUDIO_SPREAD,

	/* mutual exclusion object exlusion type */
	GUID_ASF_MUTEX_BITRATE,
	GUID_ASF_MUTEX_UKNOWN,

	/* header extension */
	GUID_ASF_RESERVED_1,

	/* script command */
	GUID_ASF_RESERVED_SCRIPT_COMMNAND,

	/* marker object */
	GUID_ASF_RESERVED_MARKER,

	/* various */
	GUID_ASF_AUDIO_CONCEAL_NONE,
	GUID_ASF_CODEC_COMMENT1_HEADER,
	GUID_ASF_2_0_HEADER,
};

#ifndef GUID_DEFINED
#define GUID_DEFINED

typedef struct _GUID {          /* size is 16 */
  uint32_t Data1;
  uint16_t Data2;
  uint16_t Data3;
  uint8_t  Data4[8];
} GUID;

#endif /* !GUID_DEFINED */

static const struct
{
    int		type;
    const char* name;
    const GUID  guid;
} guids[] =
{
    { GUID_ERROR, "error",
    { 0x0,} },


    /* base ASF objects */
    { GUID_ASF_HEADER,			"header",
    { 0x75b22630, 0x668e, 0x11cf, { 0xa6, 0xd9, 0x00, 0xaa, 0x00, 0x62, 0xce, 0x6c }} },

    { GUID_ASF_DATA,			"data",
    { 0x75b22636, 0x668e, 0x11cf, { 0xa6, 0xd9, 0x00, 0xaa, 0x00, 0x62, 0xce, 0x6c }} },

    { GUID_ASF_SIMPLE_INDEX,		"simple index",
    { 0x33000890, 0xe5b1, 0x11cf, { 0x89, 0xf4, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xcb }} },

    { GUID_INDEX,			"index",
    { 0xd6e229d3, 0x35da, 0x11d1, { 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe }} },

    { GUID_MEDIA_OBJECT_INDEX,		"media object index",
    { 0xfeb103f8, 0x12ad, 0x4c64, { 0x84, 0x0f, 0x2a, 0x1d, 0x2f, 0x7a, 0xd4, 0x8c }} },

    { GUID_TIMECODE_INDEX,		"timecode index",
    { 0x3cb73fd0, 0x0c4a, 0x4803, { 0x95, 0x3d, 0xed, 0xf7, 0xb6, 0x22, 0x8f, 0x0c }} },

    /* header ASF objects */
    { GUID_ASF_FILE_PROPERTIES,		"file properties",
    { 0x8cabdca1, 0xa947, 0x11cf, { 0x8e, 0xe4, 0x00, 0xc0, 0x0c, 0x20, 0x53, 0x65 }} },

    { GUID_ASF_STREAM_PROPERTIES,	"stream header",
    { 0xb7dc0791, 0xa9b7, 0x11cf, { 0x8e, 0xe6, 0x00, 0xc0, 0x0c, 0x20, 0x53, 0x65 }} },

    { GUID_ASF_HEADER_EXTENSION,	"header extension",
    { 0x5fbf03b5, 0xa92e, 0x11cf, { 0x8e, 0xe3, 0x00, 0xc0, 0x0c, 0x20, 0x53, 0x65 }} },

    { GUID_ASF_CODEC_LIST,		"codec list",
    { 0x86d15240, 0x311d, 0x11d0, { 0xa3, 0xa4, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0xf6 }} },

    { GUID_ASF_SCRIPT_COMMAND,		"script command",
    { 0x1efb1a30, 0x0b62, 0x11d0, { 0xa3, 0x9b, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0xf6 }} },

    { GUID_ASF_MARKER,"marker",
    { 0xf487cd01, 0xa951, 0x11cf, { 0x8e, 0xe6, 0x00, 0xc0, 0x0c, 0x20, 0x53, 0x65 }} },

    { GUID_ASF_BITRATE_MUTUAL_EXCLUSION,"bitrate mutual exclusion",
    { 0xd6e229dc, 0x35da, 0x11d1, { 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe }} },

    { GUID_ASF_ERROR_CORRECTION,	"error correction",
    { 0x75b22635, 0x668e, 0x11cf, { 0xa6, 0xd9, 0x00, 0xaa, 0x00, 0x62, 0xce, 0x6c }} },

    { GUID_ASF_CONTENT_DESCRIPTION,	"content description",
    { 0x75b22633, 0x668e, 0x11cf, { 0xa6, 0xd9, 0x00, 0xaa, 0x00, 0x62, 0xce, 0x6c }} },

    { GUID_ASF_EXTENDED_CONTENT_DESCRIPTION,"extended content description",
    { 0xd2d0a440, 0xe307, 0x11d2, { 0x97, 0xf0, 0x00, 0xa0, 0xc9, 0x5e, 0xa8, 0x50 }} },

    { GUID_ASF_STREAM_BITRATE_PROPERTIES,"stream bitrate properties", /* (http://get.to/sdp) */
    { 0x7bf875ce, 0x468d, 0x11d1, { 0x8d, 0x82, 0x00, 0x60, 0x97, 0xc9, 0xa2, 0xb2 }} },

    { GUID_ASF_EXTENDED_CONTENT_ENCRYPTION,"extended content encryption",
    { 0x298ae614, 0x2622, 0x4c17, { 0xb9, 0x35, 0xda, 0xe0, 0x7e, 0xe9, 0x28, 0x9c }} },

    { GUID_ASF_PADDING,			"padding",
    { 0x1806d474, 0xcadf, 0x4509, { 0xa4, 0xba, 0x9a, 0xab, 0xcb, 0x96, 0xaa, 0xe8 }} },


    /* stream properties object stream type */
    { GUID_ASF_AUDIO_MEDIA,		"audio media",
    { 0xf8699e40, 0x5b4d, 0x11cf, { 0xa8, 0xfd, 0x00, 0x80, 0x5f, 0x5c, 0x44, 0x2b }} },

    { GUID_ASF_VIDEO_MEDIA,		"video media",
    { 0xbc19efc0, 0x5b4d, 0x11cf, { 0xa8, 0xfd, 0x00, 0x80, 0x5f, 0x5c, 0x44, 0x2b }} },

    { GUID_ASF_COMMAND_MEDIA,		"command media",
    { 0x59dacfc0, 0x59e6, 0x11d0, { 0xa3, 0xac, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0xf6 }} },

    { GUID_ASF_JFIF_MEDIA,		"JFIF media (JPEG)",
    { 0xb61be100, 0x5b4e, 0x11cf, { 0xa8, 0xfd, 0x00, 0x80, 0x5f, 0x5c, 0x44, 0x2b }} },

    { GUID_ASF_DEGRADABLE_JPEG_MEDIA,	"Degradable JPEG media",
    { 0x35907de0, 0xe415, 0x11cf, { 0xa9, 0x17, 0x00, 0x80, 0x5f, 0x5c, 0x44, 0x2b }} },

    { GUID_ASF_FILE_TRANSFER_MEDIA,	"File Transfer media",
    { 0x91bd222c, 0xf21c, 0x497a, { 0x8b, 0x6d, 0x5a, 0xa8, 0x6b, 0xfc, 0x01, 0x85 }} },

    { GUID_ASF_BINARY_MEDIA,		"Binary media",
    { 0x3afb65e2, 0x47ef, 0x40f2, { 0xac, 0x2c, 0x70, 0xa9, 0x0d, 0x71, 0xd3, 0x43 }} },

    /* stream properties object error correction */
    { GUID_ASF_NO_ERROR_CORRECTION,	"no error correction",
    { 0x20fb5700, 0x5b55, 0x11cf, { 0xa8, 0xfd, 0x00, 0x80, 0x5f, 0x5c, 0x44, 0x2b }} },

    { GUID_ASF_AUDIO_SPREAD,		"audio spread",
    { 0xbfc3cd50, 0x618f, 0x11cf, { 0x8b, 0xb2, 0x00, 0xaa, 0x00, 0xb4, 0xe2, 0x20 }} },


    /* mutual exclusion object exlusion type */
    { GUID_ASF_MUTEX_BITRATE,		"mutex bitrate",
    { 0xd6e22a01, 0x35da, 0x11d1, { 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe }} },

    { GUID_ASF_MUTEX_UKNOWN,		"mutex unknown", 
    { 0xd6e22a02, 0x35da, 0x11d1, { 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe }} },


    /* header extension */
    { GUID_ASF_RESERVED_1,		"reserved_1",
    { 0xabd3d211, 0xa9ba, 0x11cf, { 0x8e, 0xe6, 0x00, 0xc0, 0x0c, 0x20, 0x53, 0x65 }} },


    /* script command */
    { GUID_ASF_RESERVED_SCRIPT_COMMNAND,"reserved script command",
    { 0x4B1ACBE3, 0x100B, 0x11D0, { 0xA3, 0x9B, 0x00, 0xA0, 0xC9, 0x03, 0x48, 0xF6 }} },

    /* marker object */
    { GUID_ASF_RESERVED_MARKER,		"reserved marker",
    { 0x4CFEDB20, 0x75F6, 0x11CF, { 0x9C, 0x0F, 0x00, 0xA0, 0xC9, 0x03, 0x49, 0xCB }} },

    { GUID_ASF_AUDIO_CONCEAL_NONE,	"audio conceal none",
    { 0x49f1a440, 0x4ece, 0x11d0, { 0xa3, 0xac, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0xf6 }} },

    { GUID_ASF_CODEC_COMMENT1_HEADER,	"codec comment1 header",
    { 0x86d15241, 0x311d, 0x11d0, { 0xa3, 0xa4, 0x00, 0xa0, 0xc9, 0x03, 0x48, 0xf6 }} },

    { GUID_ASF_2_0_HEADER,		"asf 2.0 header",
    { 0xd6e229d1, 0x35da, 0x11d1, { 0x90, 0x34, 0x00, 0xa0, 0xc9, 0x03, 0x49, 0xbe }} },

};

#endif
