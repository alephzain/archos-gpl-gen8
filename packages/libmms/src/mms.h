/*
 * Copyright (C) 2002-2003 the xine project
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
 * libmms public header
 */

/* TODO/dexineification:
 * + functions needed:
 * 	- _x_io_*()
 * 	- xine_malloc() [?]
 * 	- xine_fast_memcpy() [?]
 */

#ifndef HAVE_MMS_H
#define HAVE_MMS_H

#include <inttypes.h>
#include <stdio.h>
#include <sys/types.h>

/* #include "xine_internal.h" */

#include "bswap.h"
#include "mmsio.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

typedef struct mms_s mms_t;
typedef int (*mms_abort_t) ( void *ctx );

mms_t*   mms_connect (mms_io_t *io, void *data, const char *url, int bandwidth);

int      mms_read (mms_io_t *io, mms_t *instance, char *data, int len, mms_abort_t abort, void *abort_ctx);
uint32_t mms_get_length (mms_t *instance);
void     mms_close (mms_t *instance);

int      mms_peek_header (mms_t *instance, char *data, int maxsize);

off_t    mms_get_current_pos (mms_t *instance);
int      mms_seekable(mms_t *instance);

typedef void (*mms_log_t) ( void *ctx, int level, const char *msg );
void 	 mms_set_log( mms_log_t log, void *ctx );

int      mms_start_streaming(mms_io_t *io, mms_t *instance, unsigned int time, unsigned int position, unsigned int packet, int ignore_header );
int      mms_stop_streaming (mms_io_t *io, mms_t *instance );


#define MMS_ASF_MAX_NUM_STREAMS     23

/* asf stream types */
enum {
	ASF_STREAM_TYPE_UNKNOWN = 0,
	ASF_STREAM_TYPE_AUDIO,
	ASF_STREAM_TYPE_VIDEO,	
	ASF_STREAM_TYPE_CONTROL,
	ASF_STREAM_TYPE_JFIF,
	ASF_STREAM_TYPE_DEGRADABLE_JPEG,
	ASF_STREAM_TYPE_FILE_TRANSFER,
	ASF_STREAM_TYPE_BINARY,
};

typedef struct mms_asf_stream_t 
{
	int type;
	int bitrate;
	int bitrate_pos;
	int active;
} mms_stream_t;

typedef struct mms_asf_header_t 
{
	uint64_t file_len;
	uint32_t packet_len;
	int has_audio;
	int has_video;
	int num_streams;
	int stream_ids[MMS_ASF_MAX_NUM_STREAMS];

	mms_stream_t streams[MMS_ASF_MAX_NUM_STREAMS];
} mms_asf_header_t;

typedef int (*mms_asf_handler_t) ( void *ctx, const unsigned char *data, const int size, mms_asf_header_t *asf_header );
void 	 mms_set_asf_handler( mms_asf_handler_t asf_handler, void *ctx );

int lprintf( int level, const char *fmt, ... );


#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif

