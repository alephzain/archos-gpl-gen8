/*
 * Copyright (C) 2002-2004 the xine project
 * 
 * This file is part of LibMMS, an MMS protocol handling library.
 * 
 * xine is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the ree Software Foundation; either version 2 of the License, or
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
 * MMS over TCP protocol
 *   based on work from major mms
 *   utility functions to handle communication with an mms server
 *
 * TODO:
 *   error messages
 *   enable seeking !
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <unistd.h>
#include <stdio.h>
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
#include <stdarg.h>
#include <values.h>

#if defined(HAVE_ICONV) && defined(HAVE_LANGINFO_CODESET)
#define USE_ICONV
#include <iconv.h>
#include <locale.h>
#include <langinfo.h>
#endif

#include "bswap.h"
#include "mms.h"
#include "asfheader.h"
#include "uri.h"

#define DEBUG
static mms_asf_handler_t mms_asf_handler = NULL;
static void 		*mms_asf_ctx     = NULL;
mms_log_t         	mms_log         = NULL;
void 			*mms_log_ctx     = NULL;

int lprintf( int level, const char *fmt, ... )
{
	if ( !mms_log )
		return 0;

	va_list ap;
	va_start( ap, fmt );

	char msg[1024];
	int ret = vsnprintf( msg, 1024 - 1, fmt, ap );

	va_end( ap );

	mms_log( mms_log_ctx, level, msg );

	return ret;
}

void mms_set_log( mms_log_t log, void *ctx )
{
	mms_log     = log;
	mms_log_ctx = ctx;
}

void mms_set_asf_handler( mms_asf_handler_t asf_handler, void *ctx )
{
	mms_asf_handler = asf_handler;
	mms_asf_ctx     = ctx;
}

/* 
 * mms specific types 
 */

#define MMST_PORT 1755

#define BUF_SIZE 102400

#define CMD_HEADER_LEN   40
#define CMD_PREFIX_LEN    8
#define CMD_BODY_LEN   1024

#define ASF_HEADER_LEN 8192


#define MMS_PACKET_ERR        0
#define MMS_PACKET_COMMAND    1
#define MMS_PACKET_ASF_HEADER 2
#define MMS_PACKET_ASF_PACKET 3

#define ASF_HEADER_PACKET_ID_TYPE 2
#define ASF_MEDIA_PACKET_ID_TYPE  4


typedef struct mms_buffer_s mms_buffer_t;
struct mms_buffer_s
{
	uint8_t *buffer;
	int pos;
};

typedef struct mms_packet_header_s mms_packet_header_t;
struct mms_packet_header_s
{
	uint32_t packet_len;
	uint8_t flags;
	uint8_t packet_id_type;
	uint32_t packet_seq;
};

struct mms_s
{
	void *custom_data;

	int s;

	/* url parsing */
	char *url;
	char *proto;
	char *host;
	int port;
	char *user;
	char *password;
	char *uri;

	/* command to send */
	char scmd[CMD_HEADER_LEN + CMD_BODY_LEN];
	char *scmd_body;	/* pointer to &scmd[CMD_HEADER_LEN] */
	int scmd_len;		/* num bytes written in header */

	char str[1024];		/* scratch buffer to built strings */

	/* receive buffer */
	uint8_t buf[BUF_SIZE];
	int buf_size;
	int buf_read;

	uint8_t asf_header[ASF_HEADER_LEN];
	uint32_t asf_header_len;
	uint32_t asf_header_read;
	int seq_num;
	off_t start_packet_seq;	/* for live streams != 0, need to keep it around */
	int need_discont;	/* whether we need to set start_packet_seq */
	char guid[37];
	int bandwidth;

	int live_flag;
	off_t current_pos;
	int eos;
	
	mms_asf_header_t asf;
	
	int	prefix1;
	int	prefix2;
};

static void mms_buffer_init( mms_buffer_t * mms_buffer, uint8_t * buffer )
{
	mms_buffer->buffer = buffer;
	mms_buffer->pos = 0;
}

static void mms_buffer_put_8( mms_buffer_t * mms_buffer, uint8_t value )
{
	mms_buffer->buffer[mms_buffer->pos] = value & 0xff;
	mms_buffer->pos += 1;
}

#if 0
static void mms_buffer_put_16( mms_buffer_t * mms_buffer, uint16_t value )
{
	mms_buffer->buffer[mms_buffer->pos    ] =   value        & 0xff;
	mms_buffer->buffer[mms_buffer->pos + 1] = ( value >> 8 ) & 0xff;
	mms_buffer->pos += 2;
}
#endif

static void mms_buffer_put_32( mms_buffer_t * mms_buffer, uint32_t value )
{
	mms_buffer->buffer[mms_buffer->pos    ] =   value         & 0xff;
	mms_buffer->buffer[mms_buffer->pos + 1] = ( value >>  8 ) & 0xff;
	mms_buffer->buffer[mms_buffer->pos + 2] = ( value >> 16 ) & 0xff;
	mms_buffer->buffer[mms_buffer->pos + 3] = ( value >> 24 ) & 0xff;
	mms_buffer->pos += 4;
}

static void mms_buffer_put_double( mms_buffer_t * mms_buffer, double value )
{
	double v = value;
	char *c = (char*)&v;
	
	int i;
	for( i = 0; i < 8; i++ )
		mms_buffer->buffer[mms_buffer->pos++] = *c++;
}

#ifdef DEBUG
static void dump( int lvl, const unsigned char *buf , int size)
{
	char printable[] = "abcdefghijklmnopqrstuvwxyz!/\\\"#$%&'()*?+,-=|[]ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:^._<>{} ";
	char *c;
	int i,j;

	i = 0;
	while( i < size ) {
		if ((i % 512) == 0) {
		lprintf( lvl, "\n[%08X] 00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F\n", (unsigned int) (buf + i) );
		lprintf( lvl, "           -----------+-----------+-----------+-----------\n" );
				}		
		lprintf( lvl, "    [%04X] ", i % 512 );
		for ( j = i; j < ( i + 16 ); j++ ) {
			if ( j < size )
				lprintf( lvl, "%02X", buf[j] );
			else
				lprintf( lvl, "  ");		
			if ( ( ( j - 3 ) % 4 ) == 0 ) {
				lprintf( lvl, "|");
			} else {
				lprintf( lvl, " ");
			}
		}
		lprintf( lvl, " |");
		
		for ( j = i; j < ( i + 16 ); j++ ) {
			c = printable;
			while ( *c != ' ' ) {
				if (*c == buf[j] ) {
					break;
				}
				c++;
			}
			if ( j < size )
				lprintf( lvl, "%c", *c );
			else
				lprintf( lvl, " ");
		}
		lprintf( lvl, "|\n");
		i += 16;
	}
	lprintf( lvl, "\n\n");
}
#endif

static void print_command( int lvl, char *data, int len )
{
#ifdef DEBUG
	int i;
	int dir = LE_32( data + 36 ) >> 16;
	int comm = LE_32( data + 36 ) & 0xFFFF;

	lprintf( lvl,  "----------------------------------------------\n" );
	if ( dir == 3 ) {
		lprintf( lvl,  "send command 0x%02x, %d bytes\n", comm, len );
	} else {
		lprintf( lvl,  "receive command 0x%02x, %d bytes\n", comm, len );
	}
	lprintf( lvl,  "  start sequence %08x\n", LE_32( data + 0 ) );
	lprintf( lvl,  "  command id     %08x\n", LE_32( data + 4 ) );
	lprintf( lvl,  "  length         %8x \n", LE_32( data + 8 ) );
	lprintf( lvl,  "  protocol       %08x\n", LE_32( data + 12 ) );
	lprintf( lvl,  "  len8           %8x \n", LE_32( data + 16 ) );
	lprintf( lvl,  "  sequence #     %08x\n", LE_32( data + 20 ) );
	lprintf( lvl,  "  len8  (II)     %8x \n", LE_32( data + 32 ) );
	lprintf( lvl,  "  dir | comm     %08x\n", LE_32( data + 36 ) );
	if ( len >= 4 )
		lprintf( lvl,  "  prefix1        %08x\n", LE_32( data + 40 ) );
	if ( len >= 8 )
		lprintf( lvl,  "  prefix2        %08x\n", LE_32( data + 44 ) );

/*
	for ( i = ( CMD_HEADER_LEN + CMD_PREFIX_LEN ); i < ( CMD_HEADER_LEN + CMD_PREFIX_LEN + len ); i += 1 ) {
		unsigned char c = data[i];

		if ( ( c >= 32 ) && ( c < 128 ) )
			lprintf( "%c", c );
		else
			lprintf( " %02x ", c );

	}
	if ( len > CMD_HEADER_LEN )
		lprintf( "\n" );
*/
	dump( lvl, data, CMD_HEADER_LEN + CMD_PREFIX_LEN + len );
	lprintf( lvl,  "----------------------------------------------\n" );
#endif
}

static int send_command( mms_io_t * io, mms_t * this, int command, uint32_t prefix1, uint32_t prefix2, int length )
{
	int len8;
	off_t n;
	mms_buffer_t command_buffer;

lprintf( 1, "send_command: %02X\r\n", command ); 
	len8 = ( length + 7 ) / 8;

	this->scmd_len = 0;

	mms_buffer_init( &command_buffer, this->scmd );
	mms_buffer_put_32( &command_buffer, 0x00000001 );	/* start sequence */
	mms_buffer_put_32( &command_buffer, 0xB00BFACE );	/* #-)) */
	mms_buffer_put_32( &command_buffer, len8 * 8 + 32 );
	mms_buffer_put_32( &command_buffer, 0x20534d4d );	/* protocol type "MMS " */
	mms_buffer_put_32( &command_buffer, len8 + 4 );
	mms_buffer_put_32( &command_buffer, this->seq_num );
	this->seq_num++;
	mms_buffer_put_32( &command_buffer, 0x0 );	/* timestamp */
	mms_buffer_put_32( &command_buffer, 0x0 );
	mms_buffer_put_32( &command_buffer, len8 + 2 );
	mms_buffer_put_32( &command_buffer, 0x00030000 | command );	/* dir | command */
	/* end of the 40 byte command header */

	mms_buffer_put_32( &command_buffer, prefix1 );
	mms_buffer_put_32( &command_buffer, prefix2 );

	if ( length & 7 )
		memset( this->scmd + length + CMD_HEADER_LEN + CMD_PREFIX_LEN, 0, 8 - ( length & 7 ) );

	int cmd_len = len8 * 8 + CMD_HEADER_LEN + CMD_PREFIX_LEN;
//lprintf("cmd_len: %d\n", cmd_len );
	n = mms_io_write( io, this->s, this->scmd, cmd_len );
	if ( n != cmd_len ) {
		return 0;
	}

	print_command( 2, this->scmd, length );

	return 1;
}

#ifdef USE_ICONV
static iconv_t string_utf16_open(  )
{
	return iconv_open( "UTF-16LE", nl_langinfo( CODESET ) );
}

static void string_utf16_close( iconv_t url_conv )
{
	if ( url_conv != ( iconv_t ) - 1 ) {
		iconv_close( url_conv );
	}
}

static void string_utf16( iconv_t url_conv, char *dest, char *src, int len )
{
	memset( dest, 0, 2 * len );

	if ( url_conv == ( iconv_t ) - 1 ) {
		int i;

		for ( i = 0; i < len; i++ ) {
			dest[i * 2] = src[i];
			dest[i * 2 + 1] = 0;
		}
		dest[i * 2] = 0;
		dest[i * 2 + 1] = 0;
	} else {
		size_t len1, len2;
		char *ip, *op;

		len1 = len;
		len2 = 1000;
		ip = src;
		op = dest;
		iconv( url_conv, &ip, &len1, &op, &len2 );
	}
}

#else
static void string_utf16( int unused, char *dest, char *src, int len )
{
	int i;

	memset( dest, 0, 2 * len );

	for ( i = 0; i < len; i++ ) {
		dest[i * 2] = src[i];
		dest[i * 2 + 1] = 0;
	}

	dest[i * 2] = 0;
	dest[i * 2 + 1] = 0;
}
#endif

/*
 * return packet type
 */
static int get_packet_header( mms_io_t * io, mms_t * this, mms_packet_header_t * header )
{
	size_t len;
	int packet_type;

lprintf( 1, "get_packet_header: ");
	header->packet_len = 0;
	header->packet_seq = 0;
	header->flags = 0;
	header->packet_id_type = 0;

	len = mms_io_read( io, this->s, this->buf, 8 );
	if ( len != 8 ) {
lprintf( 0, "\r\nlibmms: err not8 %d!\r\n", len );		
		goto error;
	}
	if ( LE_32( this->buf + 4 ) == 0xb00bface ) {
		/* command packet */
		header->flags = this->buf[3];
		len = mms_io_read( io, this->s, this->buf + 8, 4 );
		if ( len != 4 ) {
lprintf( 0, "\r\nlibmms: err not4!\r\n");		
			goto error;
		}
		header->packet_len = LE_32( this->buf + 8 ) + 4;
		if ( header->packet_len > BUF_SIZE - 12 ) {
			header->packet_len = 0;
lprintf( 0, "\r\nlibmms: err not > BUF_SIZE - 12\r\n");		
			goto error;
		}
lprintf( 1,  "-> mms command" );
		packet_type = MMS_PACKET_COMMAND;
	} else {
		header->packet_seq = LE_32( this->buf );
		header->packet_id_type = this->buf[4];
		header->flags = this->buf[5];
		header->packet_len = ( LE_16( this->buf + 6 ) - 8 ) & 0xffff;
		if ( header->packet_id_type == ASF_HEADER_PACKET_ID_TYPE ) {
lprintf( 1,  "-> asf header" );
			packet_type = MMS_PACKET_ASF_HEADER;
		} else {
lprintf( 1,  "-> asf packet" );
			packet_type = MMS_PACKET_ASF_PACKET;
		}
	}

	return packet_type;

error:
lprintf( 1,  "read error, len=%d\n", len );
	return MMS_PACKET_ERR;
}

static int get_packet_command( mms_io_t * io, mms_t * this, uint32_t packet_len )
{
lprintf( 1, "  get_packet_command");

	int command = 0;
	size_t len;

	/* always enter this loop */
lprintf( 1,  "  len: %5d bytes ", packet_len );

	len = mms_io_read( io, this->s, this->buf + 12, packet_len );
	if ( len != packet_len ) {
		return 0;
	}

	command = LE_32( this->buf + 36 ) & 0xFFFF;
	
	this->prefix1 =  LE_32( this->buf + 40 );
	this->prefix2 =  LE_32( this->buf + 44 );
lprintf( 1,  "  -> command 0x%02x, prefix1 %08X, prefix2 %08X\n", command, this->prefix1, this->prefix2 );

	print_command( 2, this->buf, len );

	/* check protocol type ("MMS ") */
	if ( LE_32( this->buf + 12 ) != 0x20534D4D ) {
lprintf( 0,  "MMS: unknown protocol type: %c%c%c%c (0x%08X)\n", this->buf[12], this->buf[13], this->buf[14], this->buf[15], LE_32( this->buf + 12 ) );
		return 0;
	}


	return command;
}

static int get_answer( mms_io_t * io, mms_t * this )
{
	int command = 0;
	mms_packet_header_t header;

	switch ( get_packet_header( io, this, &header ) ) {
		case MMS_PACKET_ERR:
lprintf( 0, "libmms: failed to read mms packet header\n" );
			break;
		case MMS_PACKET_COMMAND:
			command = get_packet_command( io, this, header.packet_len );
			// 2.2.4.1 LinkMacToViewerPing 0x4001b
			if ( command == 0x1b ) {
				// 2.2.4.22 LinkViewerToMacPong 0x3001b
				if ( !send_command( io, this, 0x1b, 0, 0, 0 ) ) {
lprintf( 0, "libmms: failed to send command\n" );
					return 0;
				}
				/* FIXME: limit recursion */
				command = get_answer( io, this );
			}
			break;
		case MMS_PACKET_ASF_HEADER:
lprintf( 0, "libmms: unexpected asf header packet\n" );
			break;
		case MMS_PACKET_ASF_PACKET:
lprintf( 0, "libmms: unexpected asf packet\n" );
			break;
	}

	return command;
}

static int get_asf_header( mms_io_t * io, mms_t * this )
{

	off_t len;
	int stop = 0;

	this->asf_header_read = 0;
	this->asf_header_len = 0;

	while ( !stop ) {
		mms_packet_header_t header;
		int command;

		switch ( get_packet_header( io, this, &header ) ) {
			case MMS_PACKET_ERR:
lprintf( 0, "libmms: failed to read mms packet header\n" );
				return 0;
				break;
			case MMS_PACKET_COMMAND:
				command = get_packet_command( io, this, header.packet_len );

				// 2.2.4.1 LinkMacToViewerPing 0x4001b
				if ( command == 0x1b ) {
					// 2.2.4.22 LinkViewerToMacPong 0x3001b
					if ( !send_command( io, this, 0x1b, 0, 0, 0 ) ) {
lprintf( 0, "libmms: failed to send command\n" );
						return 0;
					}
					command = get_answer( io, this );
				} else {
lprintf( 0, "libmms: unexpected command packet\n" );
				}
				break;
			case MMS_PACKET_ASF_HEADER:
			case MMS_PACKET_ASF_PACKET:
				if ( header.packet_len + this->asf_header_len > ASF_HEADER_LEN ) {
lprintf( 0, "libmms: asf packet too large\n" );
					return 0;
				}
				len = mms_io_read( io, this->s, this->asf_header + this->asf_header_len, header.packet_len );
				if ( len != header.packet_len ) {
lprintf( 0, "libmms: get_asf_header failed\n" );
					return 0;
				}
				this->asf_header_len += header.packet_len;
lprintf( 1, "  header flags: %02X\n", header.flags );
				if ( ( header.flags == 0X08 ) || ( header.flags == 0X0C ) )
					stop = 1;
				break;
		}
	}
//lprintf( 1, "get header packet succ\n" );
	return 1;
}

int  mms_default_asf_handler( const unsigned char *asf_header, const int asf_header_len, mms_asf_header_t *asf, int is_mmsh );
void mms_default_choose_best_streams( mms_asf_header_t *asf, int bandwidth );

static int interp_asf_header( mms_t *this )
{
	if( mms_asf_handler ) {
		if( mms_asf_handler( mms_asf_ctx, this->asf_header, this->asf_header_len, &this->asf ) )
			return 1;
	} else {
		if( mms_default_asf_handler( this->asf_header, this->asf_header_len, &this->asf, 0 /* is not mmsh */ ) ) {
			return 1;
		}
		mms_default_choose_best_streams( &this->asf, this->bandwidth );
	}

	if ( this->asf.packet_len > BUF_SIZE ) {
		this->asf.packet_len = 0;
lprintf( 0, "libmms: asf packet len too large\n" );
		return 1;
	}
	return 0;
}

const static char *const mmst_proto_s[] = { "mms", "mmst", NULL };

static int mmst_valid_proto( char *proto )
{
	int i = 0;


	if ( !proto )
		return 0;

	while ( mmst_proto_s[i] ) {
		if ( !strcasecmp( proto, mmst_proto_s[i] ) ) {
			return 1;
		}
		i++;
	}
lprintf( 0, "libmms: invalid proto: %s\n", proto );
	return 0;
}

/*
 * returns 1 on error
 */
static int mms_tcp_connect( mms_io_t * io, mms_t * this )
{
	int progress, res;

	if ( !this->port )
		this->port = MMST_PORT;

	/* 
	 * try to connect 
	 */
lprintf( 1, "mms_tcp_connect: '%s:%d'\r\n", this->host, this->port );
	this->s = mms_io_connect( io, this->host, this->port );
	if ( this->s == -1 ) {
lprintf( 0, "libmms: failed to tcp connect '%s:%d'\r\n", this->host, this->port );
		return 1;
	}
return 0;
	/* connection timeout 15s */
	progress = 0;
	do {
		res = mms_io_select( io, this->s, MMS_IO_WRITE_READY, 500 );
		progress += 1;
	} while ( ( res == MMS_IO_STATUS_TIMEOUT ) && ( progress < 30 ) );
	if ( res != MMS_IO_STATUS_READY ) {
lprintf( 0, "libmms: tcp connect timeout '%s:%d'\r\n", this->host, this->port );
		return 1;
	}
	return 0;
}

static void mms_gen_guid( char guid[] )
{
	static char digit[16] = "0123456789ABCDEF";
	int i = 0;

	srand( time( NULL ) );
	for ( i = 0; i < 36; i++ ) {
		guid[i] = digit[( int ) ( ( 16.0 * rand(  ) ) / ( RAND_MAX + 1.0 ) )];
	}
	guid[8] = '-';
	guid[13] = '-';
	guid[18] = '-';
	guid[23] = '-';
	guid[36] = '\0';
}

/*
 * return 0 on error
 */
int static mms_disable_streams( mms_io_t * io, mms_t * this )
{
	int i;
	int res;
	/* command 0x33 */
lprintf( 1, "\r\nmms_disable_streams:\r\n");
	char *scmd_body = this->scmd + CMD_HEADER_LEN;

	memset( this->scmd_body, 0, 36 + 8 + 4 );
	for ( i = 0; i < this->asf.num_streams; i++ ) {
		int stream_id = this->asf.stream_ids[i];
		scmd_body[ i * 6 + 0 + 4 ] = 0xFF;
		scmd_body[ i * 6 + 1 + 4 ] = 0xFF;
		scmd_body[ i * 6 + 2 + 4 ] = stream_id;
		scmd_body[ i * 6 + 3 + 4 ] = stream_id >> 8;

		int cmd;
		if ( this->asf.streams[stream_id].active ) {
lprintf( 1, "\tENABLING stream  %d\n", stream_id );
			cmd = 0x0000;
		} else {
			cmd = 0x0002;
lprintf( 1, "\tdisabling stream %d\n", stream_id );
/*
			// forces the asf demuxer to not choose this stream
			if ( this->asf.bitrates_pos[this->asf.stream_ids[i]] ) {
				this->asf_header[this->asf.bitrates_pos[this->asf.stream_ids[i]]] = 0;
				this->asf_header[this->asf.bitrates_pos[this->asf.stream_ids[i]] + 1] = 0;
				this->asf_header[this->asf.bitrates_pos[this->asf.stream_ids[i]] + 2] = 0;
				this->asf_header[this->asf.bitrates_pos[this->asf.stream_ids[i]] + 3] = 0;
			}
*/
		}
		scmd_body[ i * 6 + 4 + 4 ] = cmd;
		scmd_body[ i * 6 + 5 + 4 ] = cmd >> 8;
	}

	// 2.2.4.28 LinkViewerToMacStreamSwitch 0x30033
	if ( !send_command( io, this, 0x33, this->asf.num_streams, 0xFFFF | this->asf.stream_ids[0] << 16, this->asf.num_streams * 6 + 2 ) ) {
lprintf( 0, "libmms: mms_choose_best_streams failed\n" );
		return 0;
	}

	// 2.2.4.13 LinkMacToViewerReportStreamSwitch 0x40021
	if ( ( res = get_answer( io, this ) ) != 0x21 ) {
lprintf( 0, "libmms: unexpected response: %02x (0x21)\n", res );
	}

	return 1;
}

static int _start_streaming( mms_io_t *io, mms_t *this, unsigned int time, unsigned int position, unsigned int packet, int ignore_header )
{
lprintf( 0, "libmms: start streaming  time %d  pos %d  packet %d\n", time, position, packet );
	// 2.2.4.25 LinkViewerToMacStartPlaying 0x30007
	mms_buffer_t command_buffer;
	mms_buffer_init      ( &command_buffer, this->scmd_body );
	if( !position && !packet ) {
		// we start from a given time
		double d_time = ((double)time)/1000;
		mms_buffer_put_double( &command_buffer, d_time     );	// time
		mms_buffer_put_32    ( &command_buffer, 0xFFFFFFFF );	// asfOffset   = position
		mms_buffer_put_32    ( &command_buffer, 0xFFFFFFFF );	// location ID = packet
	} else if( position ) {
		// start from a given position
		mms_buffer_put_double( &command_buffer, DBL_MAX    );	// time
		mms_buffer_put_32    ( &command_buffer, position   );	// asfOffset   = position
		mms_buffer_put_32    ( &command_buffer, 0xFFFFFFFF );	// location ID = packet
	} else {
		// start from a given packet
		mms_buffer_put_double( &command_buffer, DBL_MAX    );	// time
		mms_buffer_put_32    ( &command_buffer, 0xFFFFFFFF );	// asfOffset   = position
		mms_buffer_put_32    ( &command_buffer, packet     );	// location ID = packet
	}

	mms_buffer_put_32( &command_buffer, 0x00000000 );		// frameOffset = when to stop (ms)
	mms_buffer_put_32( &command_buffer, ASF_MEDIA_PACKET_ID_TYPE );	// playIncarnation

	if ( !send_command( io, this, 0x07, 1, 0x0001FFFF, command_buffer.pos ) ) {
lprintf( 0, "libmms: failed to send command 0x07\n" );
		return 1;
	}
	
	return 0;
}

int mms_seekable( mms_t *this )
{
	return 0;
}

static int _stop_streaming( mms_io_t * io, mms_t *this )
{
	// 2.2.4.27 LinkViewerToMacStopPlaying 0x30009
	mms_buffer_t command_buffer;
	mms_buffer_init( &command_buffer, this->scmd_body );
		
	if ( !send_command( io, this, 0x09, 1, ASF_MEDIA_PACKET_ID_TYPE, command_buffer.pos ) ) {
lprintf( 0, "libmms: failed to send command 0x09\n" );
		return 1;
	}

	int res = get_answer( io, this );
lprintf( 0, "libmms: stop streaming response: %02x\n", res );

	return 0;
}

int mms_start_streaming( mms_io_t *io, mms_t *this, unsigned int time, unsigned int position, unsigned int packet, int ignore_header )
{
	return _start_streaming( io, this, time, position, packet, ignore_header );
}

int mms_stop_streaming( mms_io_t *io, mms_t *this )
{
	return _stop_streaming( io, this );
}

/*
 * TODO: error messages
 *       network timing request
 */
mms_t *mms_connect( mms_io_t * io, void *data, const char *url, int bandwidth )
{
#ifdef USE_ICONV
	iconv_t url_conv;
#else
	int url_conv = 0;
#endif
	mms_t *this;
	int res;
	GURI *uri;

	if ( !url )
		return NULL;

	/* FIXME: needs proper error-signalling work */
	this = ( mms_t * ) malloc( sizeof( mms_t ) );
	
	memset( this, 0, sizeof( mms_t ) );
	
	this->custom_data = data;
	this->url = strdup( url );
	this->s = -1;
	this->seq_num = 0;
	this->scmd_body = this->scmd + CMD_HEADER_LEN + CMD_PREFIX_LEN;
	
	memset( &this->asf, 0, sizeof( mms_asf_header_t ) );

	this->asf_header_len = 0;
	this->asf_header_read = 0;
	this->start_packet_seq = 0;
	this->need_discont = 1;
	this->buf_size = 0;
	this->buf_read = 0;
	this->bandwidth = bandwidth;
	this->current_pos = 0;
	this->eos = 0;

	uri = gnet_uri_new( this->url );
	if ( !uri ) {
lprintf( 0, "libmms: invalid url\n" );
		goto fail;
	}
	this->proto = uri->scheme;
	this->user = uri->user;
	this->host = uri->hostname;
	this->port = uri->port;
	this->password = uri->passwd;
	this->uri = uri->path;

	if ( !mmst_valid_proto( this->proto ) ) {
lprintf( 0, "libmms: unsupported protocol\n" );
		goto fail;
	}

	if ( mms_tcp_connect( io, this ) ) {
		goto fail;
	}

#ifdef USE_ICONV
	url_conv = string_utf16_open(  );
#endif
	/*
	 * let the negotiations begin...
	 */

	// 2.2.4.17 LinkViewerToMacConnect 0x30001
	mms_gen_guid( this->guid );
	sprintf( this->str, "\x1c\x03NSPlayer/7.0.0.1956; {%s}; Host: %s", this->guid, this->host );
	string_utf16( url_conv, this->scmd_body, this->str, strlen( this->str ) + 2 );

	if ( !send_command( io, this, 1, 0, 0x0004000b, strlen( this->str ) * 2 + 8 ) ) {
lprintf( 0, "libmms: failed to send command 0x01\n" );
		goto fail;
	}

	// 2.2.4.2 LinkMacToViewerReportConnectedEX 0x40001
	if ( ( res = get_answer( io, this ) ) != 0x01 ) {
lprintf( 0, "libmms: unexpected response: %02x (0x01)\n", res );
lprintf( 0, "answer: %d\n", res );
		goto fail;
	}

	/* TODO: insert network timing request here */

	// 2.2.4.18 LinkViewerToMacConnectFunnel 0x30002
	string_utf16( url_conv, &this->scmd_body[8], "\002\000\\\\192.168.0.129\\TCP\\1037\0000", 28 );
	memset( this->scmd_body, 0, 8 );
	if ( !send_command( io, this, 2, 0, 0, 28 * 2 + 8 ) ) {
lprintf( 0, "libmms: failed to send command 0x02\n" );
		goto fail;
	}

	switch ( res = get_answer( io, this ) ) {
		case 0x02:
			/* protocol accepted */
			// 2.2.4.3 LinkMacToViewerReportConnectFunnel 0x40002
			break;
		case 0x03:
			// 2.2.4.4 LinkMacToViewerReportDisconnectedFunnel 0x40003
lprintf( 0, "libmms: protocol failed\n" );
			goto fail;
			break;
		default:
lprintf( 0, "libmms: unexpected response: %02x (0x02 or 0x03)\n", res );
			goto fail;
	}

	// 2.2.4.21 LinkViewerToMacOpenFile 0x30005
	{
		mms_buffer_t command_buffer;

lprintf( 1, "\r\nuri: (%d) [%s]\n", strlen( this->uri ), this->uri );
		mms_buffer_init( &command_buffer, this->scmd_body );
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// token
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// cbtoken

		string_utf16( url_conv, this->scmd_body + command_buffer.pos, this->uri, strlen( this->uri ) );
		if ( !send_command( io, this, 5, 1, 0xffffffff, strlen( this->uri ) * 2 + 12 ) )
			goto fail;
	}

	switch ( res = get_answer( io, this ) ) {
		case 0x06:
			// 2.2.4.7 LinkMacToViewerReportOpenFile 0x40006

			// check for error
			if( this->prefix1 ) {
lprintf( 0, "libmms: cmd 0x06 error: %08X\r\n", this->prefix1 );
				goto fail;
			}
			{
				int xx, yy;
				/* no authentication required */

				/* Warning: sdp is not right here */
				xx = this->buf[62];
				yy = this->buf[63];
				this->live_flag = ( ( xx == 0 ) && ( ( yy & 0xf ) == 2 ) );
lprintf( 1, "live: live_flag=%d, xx=%d, yy=%d\n", this->live_flag, xx, yy );
			}
			break;
		case 0x1A:
			// 2.2.4.14 LinkMacToViewerSecurityChallenge 0x4001A
			/* authentication request, not yet supported */
lprintf( 0, "libmms: authentication request, not yet supported\n" );
			goto fail;
			break;
		default:
lprintf( 0, "libmms: unexpected response: %02x (0x06 or 0x1A)\n", res );
			goto fail;
	}

	// 2.2.4.23 LinkViewerToMacReadBlock 0x30015
	{
		mms_buffer_t command_buffer;
		mms_buffer_init( &command_buffer, this->scmd_body );
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// offset
		mms_buffer_put_32( &command_buffer, 0x00800000 );	// length
		mms_buffer_put_32( &command_buffer, 0xFFFFFFFF );	// flags
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// padding
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// tEarliest
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// tEarliest
		mms_buffer_put_32( &command_buffer, 0x00000000 );	// tDeadline
		mms_buffer_put_32( &command_buffer, 0x40AC2000 );	// tDeadline
		mms_buffer_put_32( &command_buffer, ASF_HEADER_PACKET_ID_TYPE );	// playIncarnation
		mms_buffer_put_32( &command_buffer, 0x00000000 );	//  playSequence
		if ( !send_command( io, this, 0x15, 1, 0, command_buffer.pos ) ) {
lprintf( 0, "libmms: failed to send command 0x15\n" );
			goto fail;
		}
	}

	// 2.2.4.8 LinkMacToViewerReportReadBlock 0x40011
	if ( ( res = get_answer( io, this ) ) != 0x11 ) {
lprintf( 0, "libmms: unexpected response: %02x (0x11)\n", res );
		goto fail;
	}

	if ( !get_asf_header( io, this ) )
		goto fail;

	if( interp_asf_header( this ) ) {
		goto fail;
	}

	if ( !mms_disable_streams( io, this ) ) {
lprintf( 0, "libmms: mms_disable_streams failed" );
		goto fail;
	}

	if( _start_streaming( io, this, 0, 0, 0, 0 ) ) {
lprintf( 0, "libmms: cannot start streaming\n" );
		goto fail;
	}

/*   report_progress (stream, 100); */

#ifdef USE_ICONV
	string_utf16_close( url_conv );
#endif

lprintf( 1, "mms_connect: passed\n" );

	return this;

fail:
	if ( this->s != -1 )
		close( this->s );
	if ( this->url )
		free( this->url );
	if ( this->proto )
		free( this->proto );
	if ( this->host )
		free( this->host );
	if ( this->user )
		free( this->user );
	if ( this->password )
		free( this->password );
	if ( this->uri )
		free( this->uri );

	free( this );
	return NULL;
}

static int get_media_packet( mms_io_t * io, mms_t * this )
{
	mms_packet_header_t header;
	off_t len;

	switch ( get_packet_header( io, this, &header ) ) {
	case MMS_PACKET_ERR:
lprintf( 0, "libmms: failed to read mms packet header\n" );
		return 0;
		break;

	case MMS_PACKET_COMMAND:
	{
		int command;
		command = get_packet_command( io, this, header.packet_len );

		switch ( command ) {
		
		// 2.2.4.5 LinkMacToViewerReportEndOfStream 0x4001e
		case 0x1e:
		{
			uint32_t error_code;

			/* Warning: sdp is incomplete. Do not stop if error_code==1 */
			error_code = LE_32( this->buf + CMD_HEADER_LEN );
lprintf( 0, "End of the current stream. Continue=%d\n", error_code );

			if ( error_code == 0 ) {
				this->eos = 1;
				return 0;
			}

			break;
		}

		// 2.2.4.12 LinkMacToViewerReportStreamChange 0x40020
		case 0x20:
		{
lprintf( 1, "\r\n-> new ASF HEADER!\n" );
			/* asf header */
			if ( !get_asf_header( io, this ) ) {
lprintf( 0, "\r\nlibmms: failed to read new ASF header\n" );
				return 0;
			}

			interp_asf_header( this );

			if ( !mms_disable_streams( io, this ) )
				return 0;

			if( _start_streaming( io, this, 0, 0, 0, 0 ) ) {
				return 0;
			}

			this->current_pos = 0;
			break;
		}

		// 2.2.4.1 LinkMacToViewerPing 0x4001b
		case 0x1b:
		{
			// 2.2.4.22 LinkViewerToMacPong 0x3001b
			if ( !send_command( io, this, 0x1b, 0, 0, 0 ) ) {
lprintf( 0, "\r\nlibmms: failed to send command\n" );
				return 0;
			}
			break;
		}

		// 2.2.4.10 LinkMacToViewerREportStartedPlaying 0x40005
		case 0x05:
			break;

		default:
lprintf( 0, "\r\n\r\nlibmms: unexpected mms command %02x\n", command );
		}
		this->buf_size = 0;
		break;
	}

	case MMS_PACKET_ASF_HEADER:
lprintf( 0, "\r\n\r\nlibmms: unexpected asf header packet\n" );
		this->buf_size = 0;
		break;

	case MMS_PACKET_ASF_PACKET:
	{
		/* media packet */

		/* FIXME: probably needs some more sophisticated logic, but
		   until we do seeking, this should work */
		if ( this->need_discont ) {
			this->need_discont = 0;
			this->start_packet_seq = header.packet_seq;
		}

lprintf( 1, "  len %4d, seq %4d ", header.packet_len, header.packet_seq );
		if ( header.packet_len > this->asf.packet_len ) {
lprintf( 0, "libmms: invalid asf packet len: %d bytes\n", header.packet_len );
			return 0;
		}

		/* simulate a seek */
		this->current_pos = ( off_t ) this->asf_header_len + ( ( off_t ) header.packet_seq - this->start_packet_seq ) * ( off_t ) this->asf.packet_len;

		len = mms_io_read( io, this->s, this->buf, header.packet_len );
		if ( len != header.packet_len ) {
lprintf( 0, "libmms: read failed\n" );
			return 0;
		}

		/* explicit padding with 0 */
//lprintf( 1, "padding %4d", this->asf.packet_len - header.packet_len );
		{
			char *base = ( char * ) ( this->buf );
			char *start = base + header.packet_len;
			char *end = start + this->asf.packet_len - header.packet_len;
			if ( ( start > base ) && ( start < ( base + BUF_SIZE - 1 ) ) && ( start < end ) && ( end < ( base + BUF_SIZE - 1 ) ) ) {
				memset( this->buf + header.packet_len, 0, this->asf.packet_len - header.packet_len );
			}
			if ( this->asf.packet_len > BUF_SIZE ) {
				this->buf_size = BUF_SIZE;
			} else {
				this->buf_size = this->asf.packet_len;
			}
		}
		break;
	}
	}

lprintf( 1, "\r\n" );

	return 1;
}


int mms_peek_header( mms_t *this, char *data, int maxsize )
{
	int len;

	len = ( this->asf_header_len < maxsize ) ? this->asf_header_len : maxsize;

	memcpy( data, this->asf_header, len );
	return len;
}

int mms_read( mms_io_t *io, mms_t *this, char *data, int len, mms_abort_t abort, void *abort_ctx )
{
	if( !this )
		return -1;
	
	if( this->eos ) {
		// at the end, give up
		return -1;
	}

	int total = 0;
	while ( total < len && !this->eos ) {
		if( abort && abort( abort_ctx ) ) {
lprintf( 0, "libmms: ABORT\n" );
			return total;
		}
		if ( this->asf_header_read < this->asf_header_len ) {
			int n, bytes_left;

			bytes_left = this->asf_header_len - this->asf_header_read;

			if ( ( len - total ) < bytes_left )
				n = len - total;
			else
				n = bytes_left;

			memcpy( &data[total], &this->asf_header[this->asf_header_read], n );

			this->asf_header_read += n;
			total += n;
lprintf( 2, "libmms: head %4d\n", n );
			this->current_pos += n;
		} else {

			int n, bytes_left;

			bytes_left = this->buf_size - this->buf_read;
			if ( bytes_left == 0 ) {
				this->buf_size = this->buf_read = 0;
				if ( !get_media_packet( io, this ) ) {
					
lprintf( 0, "libmms: get_media_packet failed\n" );
					return total;
				}
				bytes_left = this->buf_size;
			}

			if ( ( len - total ) < bytes_left )
				n = len - total;
			else
				n = bytes_left;

			memcpy( &data[total], &this->buf[this->buf_read], n );

			this->buf_read += n;
			total += n;
lprintf( 2, "libmms: norm %4d\n", n );
			this->current_pos += n;
		}
	}
	return total;
}

void mms_close( mms_t * this )
{
	if( !this )
		return;
		
	if ( this->s != -1 )
		close( this->s );
	if ( this->url )
		free( this->url );
	if ( this->proto )
		free( this->proto );
	if ( this->host )
		free( this->host );
	if ( this->user )
		free( this->user );
	if ( this->password )
		free( this->password );
	if ( this->uri )
		free( this->uri );

	free( this );
}

uint32_t mms_get_length( mms_t * this )
{
	if( !this )
		return 0;
	return this->asf.file_len;
}

off_t mms_get_current_pos( mms_t * this )
{
	if( !this )
		return 0;
	return this->current_pos;
}
