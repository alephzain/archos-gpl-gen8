/*
 * Bitstream writer
 *
 * Copyright (c) 2006 vixy project
 *
 * Copyright (c) 2006 ARCHOS SA
 *       make it independent of the FLV parser.
 *       ------------------------------------- 2007-01-01 nz@archos
 *
 * Copyright (c) 2007 Neuros Technology
 *       Heavily rewritten to convert flv stream to mpeg4 at run time.
 *       ------------------------------------- 2007-06-02 mgao@neuros
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

#ifndef BITWRITER_H
#define BITWRITER_H

#include "type.h"

// C level, optimization, may need go further to ARM assembly. --- MG
#define C_OPT_MG  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
typedef struct _BW
{
	uint8* buf;
	uint32 size;
	uint32 pos;
	uint32 bitoffset;
	uint32 tmp;

} BW;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
static void __inline clear_bw(BW* p)
{
	p->pos = 0;
	p->bitoffset = 0;
	p->tmp = 0;
}

static void __inline init_bw(BW* p, uint8* buf, uint32 size)
{
	p->buf = buf;
	p->size = size;
	clear_bw(p);
}

static void __inline forword_bits(BW* p, uint32 bits)
{
#ifdef C_OPT_MG
	p->bitoffset += bits;

	if (p->bitoffset >= 32)
	{
		uint8* pb = (uint8*)&p->buf[p->pos];
		uint8* pt = (uint8*)&p->tmp+3;

		*pb++ = *pt--;
		*pb++ = *pt--;
		*pb++ = *pt--;
		*pb++ = *pt--;

		p->pos += 4;

		p->tmp = 0;
		p->bitoffset -= 32;
	}
#else
	p->bitoffset += bits;

	if (p->bitoffset >= 32)
	{
		p->buf[p->pos++] = (p->tmp >> 24) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 16) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 8 ) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 0 ) & 0xff;
		
		p->tmp = 0;
		p->bitoffset -= 32;
	}
#endif
}

static void __inline put_bits(BW* p, uint32 bits, uint32 value)
{
#ifdef C_OPT_MG
	uint32 shift = p->bitoffset + bits;

	if (shift <= 32)
	{
		p->tmp |= value << (32 - shift);
		forword_bits(p, bits);
	}
	else
	{
		shift -= 32;
		p->tmp |= value >> shift;
		forword_bits(p, bits - shift);

		p->tmp |= value << (32 - shift);
		forword_bits(p, shift);
	}
#else
	uint32 shift = 32 - p->bitoffset - bits;

	if (shift <= 32)
	{
		p->tmp |= value << shift;
		forword_bits(p, bits);
	}
	else
	{
		shift = bits - (32 - p->bitoffset);
		p->tmp |= value >> shift;
		forword_bits(p, bits - shift);

		p->tmp |= value << (32 - shift);
		forword_bits(p, shift);
	}
#endif
}

#ifdef C_OPT_MG
static void __inline put_zero_bits(BW* p, uint32 bits)
{
	uint32 shift = p->bitoffset + bits;

	if (shift <= 32)
	{
		forword_bits(p, bits);
	}
	else
	{
		shift -= 32;
		forword_bits(p, bits - shift);
		p->bitoffset += shift;
	}
}
#else
#define put_zero_bits(p, b) put_bits(p, b, 0)
#endif

static void __inline pad_to_boundary(BW* p)
{
#ifdef C_OPT_MG
	uint32 bits = 8 - (p->bitoffset & 0x7);
#else
	uint32 bits = 8 - (p->bitoffset % 8);
#endif
	if (bits < 8)
	{
		put_zero_bits(p, bits);
	}
}

static void __inline flash_bw(BW* p)
{
	pad_to_boundary(p);
	
	switch (p->bitoffset)
	{
	case 0: // nothing to do
		break;
	case 8:
		p->buf[p->pos++] = (p->tmp >> 24) & 0xff;
		break;
	case 16:
		p->buf[p->pos++] = (p->tmp >> 24) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 16) & 0xff;
		break;
	case 24:
		p->buf[p->pos++] = (p->tmp >> 24) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 16) & 0xff;
		p->buf[p->pos++] = (p->tmp >> 8 ) & 0xff;
		break;
	default:
//		fprintf(stderr, "flash_bw error!(%d)\n", p->bitoffset);
		break;
	}

	p->tmp = 0;
	p->bitoffset = 0;
}

static uint32 __inline get_bw_pos(BW* p)
{
	return p->pos* 8 + p->bitoffset;
}

static void __inline put_vlcdec(BW* bw, VLCDEC* vlcdec)
{
	put_bits(bw, vlcdec->bits, vlcdec->value);
}

// M4V ADDED
static void __inline m4v_stuffing(BW* p)
{
	int length;
	
	put_zero_bits(p, 1);
	length = (- p->bitoffset) & 7;
	if (length) put_bits(p, length, (1 << length) - 1);
}

#endif // BITWRITER_H
