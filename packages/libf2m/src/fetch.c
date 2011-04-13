/*
 * FLV Reader/Parser
 *
 * Copyright (c) 2006 vixy project
 *
 * Copyright (c) 2006 ARCHOS SA
 *       make it independent of the FLV parser.
 *       ------------------------------------- 2007-01-01 nz@archos
 *
 * This file contains the code that based on FFmpeg (http://ffmpeg.mplayerhq.hu/)
 * See original copyright notice in /FFMPEG_CREDITS and /FFMPEG_IMPORTS
 *
 * This file is part of VIXY FLV Converter.
 *
 * 'VIXY FLV Converter' is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * 'VIXY FLV Converter' is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "fetch.h"
#include <stdlib.h>
#include <memory.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
struct _FETCH
{
	FILE*		stream;

	recv_flv_packet	cb;
	void*		cb_ptr;

	uint8*		packet;
};

///////////////////////////////////////////////////////////////////////////////////////////////////

static int get_u8(FILE* p, uint8* ret)
{
	int r = fgetc(p);
	if( r == EOF ) return -1;
	
	*ret = (uint8)r;
	return 0;
}

static uint32 get_u24(FILE* p, uint32* ret)
{
	uint8 a,b,c;
	int ra,rb,rc;
	
	ra = get_u8(p,&a);
	rb = get_u8(p,&b);
	rc = get_u8(p,&c);
	if( ra != 0 || rb != 0 || rc != 0 ) return -1;
	
	*ret = ((uint32)a << 16) | ((uint32)b << 8) | (uint32)c;
	return 0;
}

static uint32 get_u32(FILE* p, uint32* ret)
{
	uint8 a,b,c,d;
	int ra,rb,rc,rd;
	
	ra = get_u8(p,&a);
	rb = get_u8(p,&b);
	rc = get_u8(p,&c);
	rd = get_u8(p,&d);
	if( ra != 0 || rb != 0 || rc != 0 || rd != 0 ) return -1;

	*ret = ((uint32)a << 24) | ((uint32)b << 16) | ((uint32)c << 8) | (uint32)d;
	return 0;
}

static int skip(FILE* p, int size)
{
	int i;
	uint8 t8;

	for(i=0; i<size; i++)
	{
		if( get_u8(p, &t8) != 0 ) return -1;
	}
	return 0;
}

static int read_buffer(FILE* p, uint8* buf, int size)
{
	return fread(buf, 1, size, p ) == size ? 0 : -1;
}

static void put_u8(uint8* buf, uint8 val)
{
	buf[0] = val;
}

static void put_u24(uint8* buf, uint32 val)
{
	buf[0] = (val >> 16) & 0xff;
	buf[1] = (val >> 8 ) & 0xff;
	buf[2] = (val >> 0 ) & 0xff;
}

static void put_u32(uint8* buf, uint32 val)
{
	buf[0] = (val >> 24) & 0xff;
	buf[1] = (val >> 16) & 0xff;
	buf[2] = (val >> 8 ) & 0xff;
	buf[3] = (val >> 0 ) & 0xff;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

static int send_packet(FETCH* p, uint8 picture_type, uint8* buf, uint32 buf_size, uint32 time)
{
	if( p->cb == NULL ) return -1;
	return p->cb(p->cb_ptr, picture_type, buf, buf_size, time);
}

static int read_header(FETCH* p)
{
  uint32 t32;
  uint8 t8;
  
  if( get_u8(p->stream, &t8) != 0 || t8 != 'F' ) return -1; 
  if( get_u8(p->stream, &t8) != 0 || t8 != 'L' ) return -1;
  if( get_u8(p->stream, &t8) != 0 || t8 != 'V' ) return -1;
  if( get_u8(p->stream, &t8) != 0 || t8 != 1   ) return -1;

  if( get_u8(p->stream, &t8) != 0 ) return -1;
//  printf( "header: %s,%s\n", t8 & 4 ? "hasAudio" : "noAudio", t8 & 1 ? "hasVideo" : "noVideo" );

  if( get_u32(p->stream, &t32) != 0 ) return -1;
//  printf( "header: %08X\n", t32 );

  if( get_u32(p->stream, &t32) != 0 ) return -1;
//  printf( "header: %08X\n", t32 );

  return 0;
}

static int read_packet(FETCH* p, uint8* buf, uint32* buf_size, uint8* picture_type, uint32* time, uint32 max_buf_size)
{
  uint32 size, size2, reserved;
  uint8 flag;
  
  if( get_u24(p->stream, &size) != 0 ) return -1;
//  printf("%d, ", size);
  if(size < 11) return -1; // packet size error

  if( get_u24(p->stream, time) != 0 ) return -1;
//  printf("%dms, ", time );

  if( get_u32(p->stream, &reserved) != 0 ) return -1;

  if( get_u8(p->stream, &flag) != 0 ) return -1;
//  printf("%02X\n", flag);

  *picture_type = flag;

  if( size >= max_buf_size ) return -1; // size over!!

  put_u24(buf + 0, size);
  put_u24(buf + 3, *time);
  put_u32(buf + 6, reserved);
  put_u8(buf + 10, flag);

  if( read_buffer(p->stream, buf + 11, size - 1) != 0 )
  {
    fprintf(stderr,"sizerror!!!!\n" );
     return -1;
  }
//  skip(p->stream,size-1);

  if( get_u32(p->stream, &size2) != 0 ) return -1; 
//  if(size2 != size + 11) return -1; // packet size error;

  put_u32(buf + size + 10, size2);

  *buf_size = size + 15;

  return 0;
}

static int read_body(FETCH* p)
{
  int err;
  uint8 tag;
  uint32 size;
  uint8 picture_type;
  uint32 time;

  while( 1 ) //! is_eob(p))
  {
    if( get_u8(p->stream, &tag) != 0 ) return -1;
    switch(tag)
    {
    case 8: // audio
//      printf("A: ");
      break;
    case 9: // video
//      printf("V: ");
      break;
    default:
//      printf("U: ");
      break;
    }
	
	*p->packet = tag;
    err = read_packet(p, p->packet+1, &size, &picture_type, &time, PACKETBUFFER_SIZE-1);
    if( err != 0 ) return err;
//printf("packet: type %d  pic %02X  %5d\r\n", tag, picture_type, size );

	if (send_packet(p, picture_type, p->packet, size, time) < 0) return -1;
  }

  return 0;
}


///////////////////////////////////////////////////////////////////////////////////////////////////

FETCH* FETCH_createInstance(recv_flv_packet cb, void* cb_ptr)
{
	FETCH* p = malloc(sizeof(FETCH));
	memset( p, 0, sizeof(FETCH));
	
	p->cb = cb;
	p->cb_ptr = cb_ptr;
	
	p->packet = (uint8*)malloc(PACKETBUFFER_SIZE);
	
	return p;
}

void FETCH_release(FETCH* p)
{
	free(p->packet);
	free(p);
}

int FETCH_read(FETCH* p, FILE* fp)
{
	p->stream = fp;
	
	if( read_header( p ) != 0 )
	{
		fprintf(stderr, "header error!!\n");
		return -1;
	}

	read_body( p );
	return 0;
}

