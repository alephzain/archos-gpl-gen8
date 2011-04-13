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
 * MMS over HTTP protocol
 *   written by Thibaut Mattern
 *   based on mms.c and specs from avifile
 *   (http://avifile.sourceforge.net/asf-1.0.htm)
 *
 * TODO:
 *   error messages
 *   http support cleanup, find a way to share code with input_http.c (http.h|c)
 *   http proxy support
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

#define DEBUG

#define LOG_MODULE "mmsh"
#define LOG_VERBOSE

#include "bswap.h"
#include "mms.h"
#include "mmsh.h"
#include "asfheader.h"
#include "uri.h"

/* #define USERAGENT "User-Agent: NSPlayer/7.1.0.3055\r\n" */
#define USERAGENT "User-Agent: NSPlayer/4.1.0.3856\r\n"
#define CLIENTGUID "Pragma: xClientGUID={c77e7400-738a-11d2-9add-0020af0a3278}\r\n"


#define MMSH_PORT                  80
#define MMSH_UNKNOWN                0
#define MMSH_SEEKABLE               1
#define MMSH_LIVE                   2

#define CHUNK_HEADER_LENGTH         4
#define EXT_HEADER_LENGTH           8
#define CHUNK_TYPE_RESET       0x4324
#define CHUNK_TYPE_DATA        0x4424
#define CHUNK_TYPE_END         0x4524
#define CHUNK_TYPE_ASF_HEADER  0x4824
#define CHUNK_SIZE              65536  /* max chunk size */
#define ASF_HEADER_SIZE          8192  /* max header size */

#define SCRATCH_SIZE             1024

static mms_asf_handler_t mmsh_asf_handler = NULL;
static void 		*mmsh_asf_ctx     = NULL;
extern mms_log_t         mms_log;
extern void 		*mms_log_ctx;


void mmsh_set_asf_handler( int (*asf_handler)(void *ctx, const unsigned char *data, const int size, struct mms_asf_header_t *asf_header), void *ctx )
{
	mmsh_asf_handler = asf_handler;
	mmsh_asf_ctx     = ctx;
}

static const char* mmsh_FirstRequest =
    "GET /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s:%d\r\n"
    "Pragma: no-cache,rate=1.000000,stream-time=0,stream-offset=0:0,request-context=%u,max-duration=0\r\n"
    CLIENTGUID
    "Connection: Close\r\n\r\n";

static const char* mmsh_SeekableRequest =
    "GET /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s:%d\r\n"
    "Pragma: client-id=%u\r\n"
    "Pragma: no-cache,rate=1.000000,stream-time=%u,stream-offset=%u:%u,packet_num=%u,request-context=%u,max-duration=%u\r\n"
    CLIENTGUID
    "Pragma: xPlayStrm=1\r\n"
    "Pragma: stream-switch-count=%d\r\n"
    "Pragma: stream-switch-entry=%s\r\n" /*  ffff:1:0 ffff:2:0 */
    "Connection: Close\r\n\r\n";

static const char* mmsh_LiveRequest =
    "GET /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s:%d\r\n"
    "Pragma: no-cache,rate=1.000000,request-context=%u\r\n"
    "Pragma: xPlayStrm=1\r\n"
    CLIENTGUID
    "Pragma: stream-switch-count=%d\r\n"
    "Pragma: stream-switch-entry=%s\r\n"
    "Connection: Close\r\n\r\n";

static const char* mmsh_StopRequest =
    "POST /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s:%d\r\n"
    CLIENTGUID
    "Pragma: xStopStrm=1\r\n"
    "Connection: Close\r\n\r\n";

#if 0
/* Unused requests */
static const char* mmsh_PostRequest =
    "POST /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s\r\n"
    "Pragma: client-id=%u\r\n"
/*    "Pragma: log-line=no-cache,rate=1.000000,stream-time=%u,stream-offset=%u:%u,request-context=2,max-duration=%u\r\n" */
    "Pragma: Content-Length: 0\r\n"
    CLIENTGUID
    "\r\n";

static const char* mmsh_RangeRequest =
    "GET /%s HTTP/1.0\r\n"
    "Accept: */*\r\n"
    USERAGENT
    "Host: %s:%d\r\n"
    "Range: bytes=%Lu-\r\n"
    CLIENTGUID
    "Connection: Close\r\n\r\n";
#endif



/* 
 * mmsh specific types 
 */


struct mmsh_s
{
	/* FIXME: de-xine-ification */
	void *custom_data;

	int s;

	/* url parsing */
	char *url;
	char *proxy_url;
	char *proto;
	char *connect_host;
	int connect_port;
	char *http_host;
	int http_port;
	char *proxy_user;
	char *proxy_password;
	char *host_user;
	char *host_password;
	char *uri;

	char str[SCRATCH_SIZE];	/* scratch buffer to built strings */

	int stream_type;	/* seekable or broadcast */
	int client_id;
	
	/* receive buffer */

	/* chunk */
	uint16_t chunk_type;
	uint16_t chunk_length;
	uint16_t chunk_seq_number;
	uint8_t buf[CHUNK_SIZE];

	int buf_size;
	int buf_read;
	int ignore_header;
	
	uint8_t asf_header[ASF_HEADER_SIZE];
	uint32_t asf_header_len;
	uint32_t asf_header_read;
	int eos;		// end of stream
	char guid[37];

	off_t current_pos;
	int user_bandwidth;
	
	mms_asf_header_t asf;

};

static int send_command( mms_io_t * io, mmsh_t * this, char *cmd )
{
	int length;

lprintf( 1, "send_command:\n%s\n", cmd );

	length = strlen( cmd );
	if ( mms_io_write( io, this->s, cmd, length ) != length ) {
lprintf( 0, "mmsh: send error.\n" );
		return 0;
	}
	return 1;
}

static int get_answer( mms_io_t * io, mmsh_t * this )
{
	int done, len, linenum;
	char *features;

lprintf( 1, "get_answer\n" );

	done = 0;
	len = 0;
	linenum = 0;
	this->stream_type = MMSH_UNKNOWN;

	while ( !done ) {

		if ( mms_io_read( io, this->s, &( this->buf[len] ), 1 ) != 1 ) {
lprintf( 0, "mmsh: alart: end of stream\n" );
			return 0;
		}

		if ( this->buf[len] == '\012' ) {

			this->buf[len] = '\0';
			len--;

			if ( ( len >= 0 ) && ( this->buf[len] == '\015' ) ) {
				this->buf[len] = '\0';
				len--;
			}

			linenum++;

lprintf( 1, "answer: >%s<\n", this->buf );

			if ( linenum == 1 ) {
				int httpver, httpsub, httpcode;
				char httpstatus[51];

				if ( sscanf( this->buf, "HTTP/%d.%d %d %50[^\015\012]", &httpver, &httpsub, &httpcode, httpstatus ) != 4 ) {
lprintf( 0, "mmsh: bad response format\n" );
					return 0;
				}

				if ( httpcode >= 300 && httpcode < 400 ) {
lprintf( 0, "mmsh: 3xx redirection not implemented: >%d %s<\n", httpcode, httpstatus );
					return 0;
				}

				if ( httpcode < 200 || httpcode >= 300 ) {
lprintf( 0, "mmsh: http status not 2xx: >%d %s<\n", httpcode, httpstatus );
					return 0;
				}
			} else {

				if ( !strncasecmp( this->buf, "Location: ", 10 ) ) {
lprintf( 0, "mmsh: Location redirection not implemented.\n" );
					return 0;
				}

				if ( !strncasecmp( this->buf, "Pragma:", 7 ) ) {
					features = strstr( this->buf + 7, "features=" );
					if ( features ) {
						if ( strstr( features, "seekable" ) ) {
lprintf( 0, "seekable stream\n" );
							this->stream_type = MMSH_SEEKABLE;
						} else {
							if ( strstr( features, "broadcast" ) ) {
lprintf( 0, "live stream\n" );
								this->stream_type = MMSH_LIVE;
							}
						}
					}
					char *id = strstr( this->buf + 7, "client-id=" );
					if( id ) {
						this->client_id = atoi( id + strlen("client-id=") );
lprintf( 0, "client-id: %d\n", this->client_id );
					}					
				}
			}

			if ( len == -1 ) {
				done = 1;
			} else {
				len = 0;
			}
		} else {
			len++;
		}
	}
	if ( this->stream_type == MMSH_UNKNOWN ) {
lprintf( 0, "mmsh: unknown stream type\n" );
		this->stream_type = MMSH_SEEKABLE;	/* FIXME ? */
	}
	return 1;
}

static int get_chunk_header( mms_io_t * io, mmsh_t * this )
{
	uint8_t chunk_header[CHUNK_HEADER_LENGTH];
	uint8_t ext_header[EXT_HEADER_LENGTH];
	int read_len;
	int ext_header_len;

lprintf( 1, "get_chunk_header: " );

	/* read chunk header */
	read_len = mms_io_read( io, this->s, chunk_header, CHUNK_HEADER_LENGTH );
	if ( read_len != CHUNK_HEADER_LENGTH ) {
lprintf( 0, "chunk header read failed, %d != %d\n", read_len, CHUNK_HEADER_LENGTH );
		return 0;
	}
	this->chunk_type   = LE_16( &chunk_header[0] );
	this->chunk_length = LE_16( &chunk_header[2] );

	switch ( this->chunk_type ) {
		case CHUNK_TYPE_DATA:
			ext_header_len = 8;
			break;
		case CHUNK_TYPE_END:
			ext_header_len = 4;
			break;
		case CHUNK_TYPE_ASF_HEADER:
			ext_header_len = 8;
			break;
		case CHUNK_TYPE_RESET:
			ext_header_len = 4;
			break;
		default:
			ext_header_len = 0;
	}
	/* read extended header */
	if ( ext_header_len > 0 ) {
		read_len = mms_io_read( io, this->s, ext_header, ext_header_len );
		if ( read_len != ext_header_len ) {
lprintf( 0, "extended header read failed. %d != %d\n", read_len, ext_header_len );
			return 0;
		}
	}
	/* display debug infos */
#ifdef DEBUG
	switch ( this->chunk_type ) {
		case CHUNK_TYPE_DATA:
			this->chunk_seq_number = LE_32( &ext_header[0] );
lprintf( 1, "DATA    len %5d  pkt %4d  unk %d  seq %3d  len2 %d\n", 
this->chunk_length, this->chunk_seq_number, ext_header[4], ext_header[5], LE_16( &ext_header[6] ) );
			break;
		case CHUNK_TYPE_END:
			this->chunk_seq_number = LE_32( &ext_header[0] );
lprintf( 1, "END     continue: %d\n", this->chunk_seq_number );
			break;
		case CHUNK_TYPE_ASF_HEADER:
lprintf( 1, "HEADER  len %5d  ", this->chunk_length );
lprintf( 1, "unknown: %2X %2X %2X %2X %2X %2X  ", ext_header[0], ext_header[1], ext_header[2], ext_header[3], ext_header[4], ext_header[5] );
lprintf( 1, "len2: %d\n", LE_16( &ext_header[6] ) );
			break;
		case CHUNK_TYPE_RESET:
lprintf( 1, "RESET   " );
lprintf( 1, "pkt: %d  ", this->chunk_seq_number );
lprintf( 1, "unknown: %2X %2X %2X %2X\n", ext_header[0], ext_header[1], ext_header[2], ext_header[3] );
			break;
		default:
lprintf( 0, "UNKNOWN %4X\n", this->chunk_type );
	}
#endif

	this->chunk_length -= ext_header_len;
	return 1;
}

static int get_header( mms_io_t * io, mmsh_t * this )
{
	int need_header = 0;
	int len = 0;

lprintf( 1, "get_header\n" );

	this->asf_header_len  = 0;
	this->asf_header_read = 0;

	/* read chunk */
	while ( 1 ) {
		if ( get_chunk_header( io, this ) ) {
			if ( this->chunk_type == CHUNK_TYPE_ASF_HEADER ) {
lprintf( 1, "get_header size %d  %d\n", this->asf_header_len, this->chunk_length );
				if ( ( this->asf_header_len + this->chunk_length ) > ASF_HEADER_SIZE ) {
lprintf( 0, "mmsh: the asf header exceed %d bytes\n", ASF_HEADER_SIZE );
					return 0;
				} else {
					len = mms_io_read( io, this->s, this->asf_header + this->asf_header_len, this->chunk_length );
					this->asf_header_len += len;
					if ( len != this->chunk_length ) {
						return 0;
					}
					if( !need_header ) {
						need_header = mms_asf_check_header( this->asf_header, this->asf_header_len );
lprintf( 0, "mmsh: need header %d\n", need_header );
					}
					if( this->asf_header_len >= need_header ) {
lprintf( 0, "mmsh: got header %d\n", this->asf_header_len );
						return 1;
					}
				}
			} else {
lprintf( 0, "get_chunk_header failed\n" );
				return 0;
			}
		} else {
lprintf( 0, "get_chunk_header failed\n" );
			return 0;
		}
	}
}

int  mms_default_asf_handler( const unsigned char *asf_header, const int asf_header_len, mms_asf_header_t *asf, int is_mmsh );
void mms_default_choose_best_streams( mms_asf_header_t *asf, int bandwidth );

static int interp_asf_header(mms_io_t *io, mmsh_t *this, int choose_stream ) 
{
 	this->asf.packet_len = 0;

	if( mmsh_asf_handler ) {
		if( mmsh_asf_handler( mmsh_asf_ctx, this->asf_header, this->asf_header_len, &this->asf ) ) {
			return 1;
		}
	} else {
		if( mms_default_asf_handler( this->asf_header, this->asf_header_len, &this->asf, 1 /* is mmsh */) ) {
			return 1;
		}
		mms_default_choose_best_streams( &this->asf, this->user_bandwidth );
	}

	if ( this->asf.packet_len > CHUNK_SIZE ) {
		this->asf.packet_len = 0;
lprintf(0, "libmms: asf packet len too large\n" );
		return 1;
	}
	return 0;
}

const static char *const mmsh_proto_s[] = { "mms", "mmsh", NULL };

static int mmsh_valid_proto (char *proto) 
{
	int i = 0;

lprintf(1, "mmsh_valid_proto\n");

	if (!proto)
		return 0;

	while(mmsh_proto_s[i]) {
		if (!strcasecmp(proto, mmsh_proto_s[i])) {
			return 1;
		}
		i++;
	}
	return 0;
}

/*
 * returns 1 on error
 */
static int mmsh_tcp_connect(mms_io_t *io, mmsh_t *this) 
{
	int progress, res;
  
	if (!this->connect_port) 
		this->connect_port = MMSH_PORT;
  
	/* 
	 * try to connect 
	 */
lprintf(1, "try to connect to %s on port %d \n", this->connect_host, this->connect_port);

	this->s = mms_io_connect (io, this->connect_host, this->connect_port);

	if (this->s == -1) {
lprintf(0, "mmsh: failed to connect '%s'\n", this->connect_host);
		return 1;
	}
return 0;

	/* connection timeout 15s */
	progress = 0;
	do {
		res = mms_io_select (io, this->s, MMS_IO_WRITE_READY, 500);
		progress += 1;
	} while ((res == MMS_IO_STATUS_TIMEOUT) && (progress < 30));
	if (res != MMS_IO_STATUS_READY) {
lprintf( 0, "mmsh: tcp connect timeout '%s:%d'\r\n", this->connect_host, this->connect_port );
		return 1;
	}
lprintf(0, "connected\n");

	return 0;
}

static int _stop_streaming( mms_io_t * io, mmsh_t *this )
{
	snprintf (this->str, SCRATCH_SIZE, mmsh_StopRequest, this->uri,
			this->http_host, this->http_port, 1);

	if (!send_command (io, this, this->str))
		return 1;
	return 0;
}


int mmsh_stop_streaming( mms_io_t *io, mmsh_t *this )
{
	return _stop_streaming( io, this );
}

int mmsh_start_streaming( mms_io_t *io, mmsh_t *this, unsigned int time, unsigned int position, unsigned int packet, int ignore_header )
{
lprintf( 0, "mmsh: start streaming  time %d  pos %d  packet %d\n", time, position, packet );
	close(this->s);

	if (mmsh_tcp_connect(io, this)) {
		goto fail;
	}

	/* stream selection string */
	/* The same selection is done with mmst */
	/* 0 means selected */
	/* 2 means disabled */

	int    i;
	char   stream_selection[10 * MMS_ASF_MAX_NUM_STREAMS]; /* 10 chars per stream */
	int    offset = 0;
	for (i = 0; i < this->asf.num_streams; i++) {
		int size;
		if (this->asf.streams[this->asf.stream_ids[i]].active) {
			size = snprintf(stream_selection + offset, sizeof(stream_selection) - offset,
                      		"ffff:%d:0 ", this->asf.stream_ids[i]);
		} else {
lprintf(0, "disabling stream %d\n", this->asf.stream_ids[i]);
			size = snprintf(stream_selection + offset, sizeof(stream_selection) - offset,
				"ffff:%d:2 ", this->asf.stream_ids[i]);
		}
		if (size < 0) 
			goto fail;
		offset += size;
	}

	unsigned int pos_high = 0xFFFFFFFF;
	unsigned int pos_low  = 0xFFFFFFFF;
	
	if( !position && !packet ) {
		// we start from a given time
		packet   = 0xFFFFFFFF;		
		pos_high = 0xFFFFFFFF;
		pos_low  = 0xFFFFFFFF;
	} else if( position ) {
		// start from a given position
		packet   = 0xFFFFFFFF;		
		pos_high = 0;
		pos_low  = position;
	} else {
		// start from a given packet
		pos_high = 0xFFFFFFFF;
		pos_low  = 0xFFFFFFFF;
	}

	snprintf (this->str, SCRATCH_SIZE, mmsh_SeekableRequest, 
			this->uri, this->http_host, this->http_port, 
			this->client_id,
			time, pos_high, pos_low, packet, 2, 0,
			this->asf.num_streams, stream_selection);
lprintf(0, "-----\r\n%s\r\n------------\r\n", this->str );  
	if (!send_command (io, this, this->str))
		goto fail;
  
lprintf(0, "-> get_answer \n");

	if (!get_answer (io, this))
		goto fail;
		
lprintf(0, "-> get_header \n");
	if (!get_header(io, this))
		goto fail;
lprintf(0, "connect_int done!\n");
	
	// reset the buffer
	this->buf_size      = this->buf_read = 0;
	this->ignore_header = ignore_header;
	this->eos           = 0;
	return 0;
	
fail:
	return 1;
}

int mmsh_seekable( mmsh_t *this )
{
	return (this->stream_type == MMSH_SEEKABLE);
}

static int mmsh_connect_int (mms_io_t *io, mmsh_t *this, int bandwidth) 
{
	char   stream_selection[10 * MMS_ASF_MAX_NUM_STREAMS]; /* 10 chars per stream */

	mms_asf_header_t *asf = &this->asf;

	/*
	 * let the negotiations begin...
	 */
	asf->num_streams = 0;

	/* first request */
lprintf(0, "first http request\n");
  
	snprintf (this->str, SCRATCH_SIZE, mmsh_FirstRequest, this->uri,
			this->http_host, this->http_port, 1);

	if (!send_command (io, this, this->str))
		goto fail;

	if (!get_answer (io, this))
		goto fail;

    
	get_header(io, this);
	
	if( interp_asf_header(io, this, 1) ) {
		goto fail;
	}
  
	close(this->s);

	/* second request */
lprintf(0, "second http request\n");

	if (mmsh_tcp_connect(io, this)) {
		goto fail;
	}

	/* stream selection string */
	/* The same selection is done with mmst */
	/* 0 means selected */
	/* 2 means disabled */

	int offset = 0;
	int i;
	for (i = 0; i < this->asf.num_streams; i++) {
		int size;
		if (this->asf.streams[this->asf.stream_ids[i]].active) {
			size = snprintf(stream_selection + offset, sizeof(stream_selection) - offset,
                      		"ffff:%d:0 ", this->asf.stream_ids[i]);
		} else {
lprintf(0, "disabling stream %d\n", this->asf.stream_ids[i]);
			size = snprintf(stream_selection + offset, sizeof(stream_selection) - offset,
				"ffff:%d:2 ", this->asf.stream_ids[i]);
		}
		if (size < 0) 
			goto fail;
		offset += size;
	}

	switch (this->stream_type) {
		case MMSH_SEEKABLE:
			snprintf (this->str, SCRATCH_SIZE, mmsh_SeekableRequest, 
					this->uri, this->http_host, this->http_port, 
					this->client_id,
					0x0, 0x0, 0, 0xFFFFFFFF, 2, 0,
					this->asf.num_streams, stream_selection);
			break;
		case MMSH_LIVE:
			snprintf (this->str, SCRATCH_SIZE, mmsh_LiveRequest, this->uri,
					this->http_host, this->http_port, 2,
					this->asf.num_streams, stream_selection);
			break;
	}
lprintf(0, "-----\r\n%s\r\n------------\r\n", this->str );  
  
	if (!send_command (io, this, this->str))
		goto fail;
  
lprintf(0, "-> get_answer \n");

	if (!get_answer (io, this))
		goto fail;

lprintf(0, "-> get_header \n");
	if (!get_header(io, this))
		goto fail;
lprintf(0, "connect_int done!\n");

	return 1;
fail:
	return 0;
}

mmsh_t *mmsh_connect (mms_io_t *io, void *data, const char *url, int bandwidth) 
{
	mmsh_t *this;
	GURI  *uri = NULL;
	GURI  *proxy_uri = NULL;
	char  *proxy_env;
	if (!url)
		return NULL;

	/*
	 * initializatoin is essential here.  the fail: label depends
	 * on the various char * in our this structure to be
	 * NULL if they haven't been assigned yet.
	 */
	this = (mmsh_t*) calloc (1, sizeof (mmsh_t));

	this->custom_data     = data;
	this->url	      = strdup(url);
	if ((proxy_env = getenv("http_proxy")) != NULL)
		this->proxy_url = strdup(proxy_env);
	else
		this->proxy_url = NULL;
	this->s 	      = -1;

	this->user_bandwidth  = bandwidth;

	memset(&this->asf, 0, sizeof(mms_asf_header_t));

	if (this->proxy_url) {
		proxy_uri = gnet_uri_new(this->proxy_url);
		if (!proxy_uri) {
lprintf(0, "invalid proxy url\n");
			goto fail;
		}
		if (! proxy_uri->port ) {
			proxy_uri->port = 3128; //default squid port
		}
	}
	uri = gnet_uri_new(this->url);
	if (!uri) {
lprintf(0, "invalid url\n");
		goto fail;
	}
	if (! uri->port ) {
		//checked in tcp_connect, but it's better to initialize it here
		uri->port = MMSH_PORT;
	}
	if (this->proxy_url) {
		this->proto = (uri->scheme) ? strdup(uri->scheme) : NULL;
		this->connect_host = (proxy_uri->hostname) ? strdup(proxy_uri->hostname) : NULL;
		this->connect_port = proxy_uri->port;
		this->http_host = (uri->scheme) ? strdup(uri->hostname) : NULL;
		this->http_port = uri->port;
		this->proxy_user = (proxy_uri->user) ? strdup(proxy_uri->user) : NULL;
		this->proxy_password = (proxy_uri->passwd) ? strdup(proxy_uri->passwd) : NULL;
		this->host_user = (uri->user) ? strdup(uri->user) : NULL;
		this->host_password = (uri->passwd) ? strdup(uri->passwd) : NULL;
		gnet_uri_set_scheme(uri,"http");
		char * uri_string = gnet_uri_get_string(uri);
		this->uri = strdup(uri_string);
		ng_free(uri_string);
	} else {
		this->proto = (uri->scheme) ? strdup(uri->scheme) : NULL;
		this->connect_host = (uri->hostname) ? strdup(uri->hostname) : NULL;
		this->connect_port = uri->port;
		this->http_host = (uri->hostname) ? strdup(uri->hostname) : NULL;
		this->http_port = uri->port;
		this->proxy_user = NULL;
		this->proxy_password = NULL;
		this->host_user =(uri->user) ?  strdup(uri->user) : NULL;
		this->host_password = (uri->passwd) ? strdup(uri->passwd) : NULL;
		this->uri = (uri->path) ? strdup(uri->path) : NULL;
	}
	if (proxy_uri) {
		gnet_uri_delete(proxy_uri);
		proxy_uri = NULL;
	}
	if (uri) {
		gnet_uri_delete(uri);
		uri = NULL;
	}
	if (!mmsh_valid_proto(this->proto)) {
lprintf(0, "unsupported protocol\n");
		goto fail;
	}
  
	if (mmsh_tcp_connect(io, this)) {
lprintf(0, "mmsh_connect: tcp failed\n" );
		goto fail;
	}

	if (!mmsh_connect_int(io, this, this->user_bandwidth))
		goto fail;

lprintf(0, "mmsh_connect: passed\n" );

	return this;

fail:
lprintf(0, "mmsh_connect: failed\n" );
	if (proxy_uri)
		gnet_uri_delete(proxy_uri);
	if (uri)
		gnet_uri_delete(uri);
	if (this->s != -1)
		close(this->s);
	if (this->url)
		free(this->url);
	if (this->proxy_url)
		free(this->proxy_url);
	if (this->proto)
		free(this->proto);
	if (this->connect_host)
		free(this->connect_host);
	if (this->http_host)
		free(this->http_host);
	if (this->proxy_user)
		free(this->proxy_user);
	if (this->proxy_password)
		free(this->proxy_password);
	if (this->host_user)
		free(this->host_user);
	if (this->host_password)
		free(this->host_password);
	if (this->uri)
		free(this->uri);

	free(this);

lprintf(0, "mmsh_connect: failed return\n" );
	return NULL;
}


/*
 * returned value:
 *  0: error
 *  1: data packet read
 *  2: new header read
 */
static int get_media_packet (mms_io_t *io, mmsh_t *this) 
{
	int len = 0;

lprintf(1, "get_media_packet: %d\n", this->asf.packet_len);

	if (get_chunk_header(io, this)) {
		switch (this->chunk_type) {
			case CHUNK_TYPE_END:
				/* this->chunk_seq_number:
				 *     0: stop
				 *     1: a new stream follows
				 */
lprintf(0, "mmsh: CHUNK_TYPE_END: continue: %d\n", this->chunk_seq_number);
				if (this->chunk_seq_number == 0) {
					this->eos = 1;	// we are done!
					return 99;
				}
				
				close (this->s);

				if (mmsh_tcp_connect (io, this))
					return 0;

				if (!mmsh_connect_int (io, this, this->user_bandwidth))
					return 0;

				/* mmsh_connect_int reads the first data packet */
				/* this->buf_size is set by mmsh_connect_int */
				return 2;

			case CHUNK_TYPE_DATA:
				/* nothing to do */
				break;

			case CHUNK_TYPE_RESET:
				/* next chunk is an ASF header */

				if (this->chunk_length != 0) {
					/* that's strange, don't know what to do */
					return 0;
				}
				if (!get_header (io, this))
					return 0;
				interp_asf_header(io, this, 0);

				return 2;

			default:
lprintf(0, "mmsh: unexpected chunk type\n");
				return 0;
		}

		len = mms_io_read (io, this->s, this->buf, this->chunk_length);
      
		if (len == this->chunk_length) {
			/* explicit padding with 0 */
			if (this->chunk_length > this->asf.packet_len) {
lprintf(0, "mmsh: chunk_length(%d) > packet_length(%d)\n",
				this->chunk_length, this->asf.packet_len);
				return 0;
			}

			{
				char *base  = (char *)(this->buf);
				char *start = base + this->chunk_length;
				char *end   = start + this->asf.packet_len - this->chunk_length;
				if ((start > base) && (start < (base+CHUNK_SIZE-1)) &&
	    				(start < end)  && (end < (base+CHUNK_SIZE-1))) {
	  				memset(start, 0,
		 				this->asf.packet_len - this->chunk_length);
				}
				if (this->asf.packet_len > CHUNK_SIZE) {
	  				this->buf_size = CHUNK_SIZE;
				} else {
	  				this->buf_size = this->asf.packet_len;
				}
      			}
      			return 1;
    		} else {
lprintf(0, "mmsh: read error, %d != %d\n", len, this->chunk_length);
      			return 0;
   		}
  	} else {
    		return 0;
  	}
}

int mmsh_peek_header (mmsh_t *this, char *data, int maxsize) 
{
	int len;

lprintf(0, "mmsh_peek_header\n");

	len = (this->asf_header_len < maxsize) ? this->asf_header_len : maxsize;

	memcpy(data, this->asf_header, len);
	return len;
}

int mmsh_read (mms_io_t *io, mmsh_t *this, char *data, int len, int (*abort)(void *ctx), void *abort_ctx) 
{
	int total = 0;

	if( !this )
		return -1;
lprintf(1, "mmsh_read: len: %d\n", len);
	if( this->eos ) {
		// we are done!
		return -2;
	}

	if( this->ignore_header ) {
		// do not pass the header
		this->asf_header_read = 0;
		this->asf_header_len  = 0;
		this->ignore_header   = 0;
	}
	while (total < len) {
		if( abort && abort( abort_ctx ) )  {
lprintf(0,  "libmms: ABORT!\n" );
			return total;
		}

		if (this->asf_header_read < this->asf_header_len) {
			int bytes_left = this->asf_header_len - this->asf_header_read ;

			int n;
			if ((len - total) < bytes_left)
				n = len - total;
			else
				n = bytes_left;

			memcpy (&data[total], &this->asf_header[this->asf_header_read], n);

			this->asf_header_read += n;
			total                 += n;
			this->current_pos     += n;
		} else {
			int bytes_left = this->buf_size - this->buf_read;

			if (bytes_left == 0) {
				int packet_type;

				this->buf_size = this->buf_read = 0;
				packet_type = get_media_packet (io, this);

				if (packet_type == 0) {
lprintf(0, "mmsh: get_media_packet failed\n");
					return total;
				} else if (packet_type == 2) {
					continue;
				} else if( packet_type == 99) {
lprintf(0, "mmsh: get_media_packet: at end, rest %d\n", total);
					// bytes read?
					if( total ) 
						return total;
					else 
					 	return -2;
				}
				bytes_left = this->buf_size;
			}

			int n;
			if ((len - total) < bytes_left)
				n = len - total;
			else
				n = bytes_left;

			memcpy (&data[total], &this->buf[this->buf_read], n);

			this->buf_read    += n;
			total             += n;
			this->current_pos += n;
		}
	}
	return total;
}

void mmsh_close (mmsh_t *this) 
{
lprintf(0, "mmsh_close\n");

	if (this->s != -1)
		close(this->s);
	if (this->url)
		free(this->url);
	if (this->proxy_url)
		free(this->proxy_url);
	if (this->proto)
		free(this->proto);
	if (this->connect_host)
		free(this->connect_host);
	if (this->http_host)
		free(this->http_host);
	if (this->proxy_user)
		free(this->proxy_user);
	if (this->proxy_password)
		free(this->proxy_password);
	if (this->host_user)
		free(this->host_user);
	if (this->host_password)
		free(this->host_password);
	if (this->uri)
		free(this->uri);
	if (this)
		free (this);
}

uint32_t mmsh_get_length (mmsh_t *this) 
{
lprintf(0, "mmsh_get_length: %08x\n", this);
	if( !this )
		return 0;

	return this->asf.file_len;
}

off_t mmsh_get_current_pos (mmsh_t *this) 
{
	if( !this )
		return 0;
		
	return this->current_pos;
}
