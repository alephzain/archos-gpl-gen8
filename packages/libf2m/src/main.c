/*
 * Copyright (c) 2006 ARCHOS SA
 *       make it independent of the FLV parser.
 *       ------------------------------------- 2007-01-01 nz@archos
 *
 */
 
#include "fetch.h"
#include "f2m.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

static int raw = -1;

static int on_flv_packet(void* ptr, uint8 picture_type, const uint8* buf, uint32 size, uint32 time)
{
	switch (buf[0]) {
	case 9: // Video 
		{
			int key = (picture_type == 0x12 );
			unsigned char dst[65536];
			int dst_size;
			if (!f2m_process( ptr, dst, &dst_size, buf + 12, size - 16, time, key ) ) {
				if( raw != -1 ) {
					write( raw, dst, dst_size );
				}

			}
			break;
		}	
	}
	
	return 0; // continueing loop
}

int main (int argc, const char * argv[]) 
{
	F2M_CTX *ctx;
	FILE* fp;
	FETCH* fetch;
	int r = -1;

	if (argc < 2) {
		fprintf(stderr, "usage: %s in.flv [outfile]\n", argv[0]);
		return -1;
	}

	if (argc == 3)
		raw = open(argv[2], O_WRONLY | O_TRUNC | O_CREAT, 0600 );
		
	fp = fopen(argv[1], "rb");
	
	ctx = f2m_create();
	
	fseek(fp, 0L, SEEK_SET);
	fetch = FETCH_createInstance(on_flv_packet, ctx);
	FETCH_read(fetch, fp);
	FETCH_release(fetch);

	f2m_destroy( ctx );
	r = 0;
	
	fclose(fp);

	if( raw != -1 )
		close( raw );
	return r;
}

