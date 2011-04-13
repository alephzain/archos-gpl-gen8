#include "mms.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <string.h>

#include <errno.h>

static mms_io_t fallback_io;

#define io_write(io, args...) ((io) ? (io)->write(io, ## args) : fallback_io.write(NULL, ## args))

off_t mms_io_read( mms_io_t *io, int socket, char *buf, off_t num )
{
	if( io )
		return io->read( io, socket, buf, num );
	else
		return fallback_io.read( NULL, socket, buf, num );
}

off_t mms_io_write( mms_io_t *io, int socket, char *buf, off_t num )
{
	if( io )
		return io->write( io, socket, buf, num );
	else
		return fallback_io.write( NULL, socket, buf, num );
}

int mms_io_select( mms_io_t *io, int socket, int state, int timeout_msec )
{
	if( io )
		return io->select( io, socket, state, timeout_msec );
	else
		return fallback_io.select( NULL, socket, state, timeout_msec );
}

int mms_io_connect( mms_io_t *io, const char *host, int port )
{
	if( io )
		return io->connect( io, host, port );
	else
		return fallback_io.connect( NULL, host, port );
}

static int fallback_io_select( mms_io_t *io, int socket, int state, int timeout_msec )
{
lprintf( 2, "fallback_io_select: %08X\r\n", io );
	fd_set set;
	struct timeval tv = { timeout_msec / 1000, ( timeout_msec % 1000 ) * 1000 };
	FD_ZERO( &set );
	FD_SET( socket, &set );
	return select( socket + 1, ( state == MMS_IO_READ_READY ) ? &set : NULL, ( state == MMS_IO_WRITE_READY ) ? &set : NULL, NULL, &tv );
}

static off_t fallback_io_read( mms_io_t *io, int socket, char *buf, off_t num )
{
	off_t len = 0;
	errno = 0;

	while ( len < num ) {
		while( 1 )  {
			
			int ret = mms_io_select( io, socket, MMS_IO_READ_READY, 500 );
			
			if( ret < 0 && errno != EINTR ) {
lprintf( 0, "read select err: %d -> %s\r\n", errno, strerror(errno) );
				return len;
			} else if(ret > 0) {
lprintf( 2, "read OK\r\n" );
				// OK, go on
				break;
			}
lprintf( 2, "read retry...\r\n" );
		}	

		off_t ret = ( off_t ) read( socket, buf + len, num - len );
		if ( ret == 0 )
			break;	/* EOF */
		if ( ret < 0 )
			switch ( errno ) {
				case EAGAIN:
lprintf( 3, "len == %lld\n", ( long long int ) len );
					break;
				default:
lprintf( 3, "read err, len == %lld\n", ( long long int ) len );
					/* if already read something, return it, we will fail next time */
					return len ? len : ret;
			}
		len += ret;
	}
lprintf( 3, "[num %6lld ret %6lld]", ( long long int ) num, ( long long int ) len );
	return len;
}

static off_t fallback_io_write( mms_io_t *io, int socket, char *buf, off_t num )
{
	return ( off_t ) write( socket, buf, num );
}

#define MMS_IO_TIMEOUT	500
#define MMS_IO_RETRIES	15

static int fallback_io_tcp_connect( mms_io_t *io, const char *host, int port )
{
lprintf( 2, "fallback_io_tcp_connect: %08X\r\n", io );
	struct hostent *h;
	int i, s;

	h = gethostbyname( host );
	if ( h == NULL ) {
lprintf( 0, "unable to resolve host: %s\n", host );
		return -1;
	}

	s = socket( PF_INET, SOCK_STREAM, IPPROTO_TCP );
	if ( s == -1 ) {
lprintf( 0, "failed to create socket: %s\r\n", strerror(errno) );
		return -1;
	}

	if ( fcntl( s, F_SETFL, fcntl( s, F_GETFL ) | O_NONBLOCK ) == -1 ) {
lprintf( 0, "can't put socket in non-blocking mode", strerror(errno) );
		return -1;
	}

	for ( i = 0; h->h_addr_list[i]; i++ ) {
		struct in_addr ia;
		struct sockaddr_in sin;
		int    ret;
		int    count = 0;

		memcpy( &ia, h->h_addr_list[i], 4 );
		sin.sin_family = AF_INET;
		sin.sin_addr = ia;
		sin.sin_port = htons( port );

lprintf( 2, "connect: connecting...\r\n" );
		int rc = connect( s, ( struct sockaddr * ) &sin, sizeof( sin ) );
		
		if( rc == -1 ) {
			if( errno != EINPROGRESS ) {
lprintf( 0, "connect err: %s\r\n", strerror(errno) );
				close( s );
				continue; 
			
			}
		}

		while( 1 ) {
			int ret = mms_io_select( io, s, MMS_IO_WRITE_READY, MMS_IO_TIMEOUT );

			if( ret < 0 ) {
lprintf( 0, "connect select err: %s\r\n", strerror(errno) );
				close( s );
				goto NEXT_ADDR;
			} else if(ret > 0) {
lprintf( 2, "connect OK\r\n" );
				// OK, go on
				fcntl( s, F_SETFL, fcntl(s, F_GETFL) & ~O_NONBLOCK );
				return s;
			} else if(count > MMS_IO_RETRIES ) {
lprintf( 0, "connect timeout\r\n" );
				close( s );
				goto NEXT_ADDR;
			}
			count++;
lprintf( 2, "connect retry( %2d )...\r\n", count );
		}
NEXT_ADDR:		
		continue;
	}
lprintf( 0, "connect no more servers!\r\n" );
	return -1;
}

static mms_io_t fallback_io = {
	&fallback_io_select,
	&fallback_io_read,
	&fallback_io_write,
	&fallback_io_tcp_connect,
	NULL,
};

static mms_io_t default_io = {
	&fallback_io_select,
	&fallback_io_read,
	&fallback_io_write,
	&fallback_io_tcp_connect,
	NULL,
};

const mms_io_t *mms_get_default_io_impl(  )
{
	return &fallback_io;
}

void mms_set_default_io_impl( const mms_io_t * io )
{
	if ( io->select ) {
		default_io.select = io->select;
	} else {
		default_io.select = fallback_io.select;
	}
	if ( io->read ) {
		default_io.read = io->read;
	} else {
		default_io.read = fallback_io.read;
	}
	if ( io->write ) {
		default_io.write = io->write;
	} else {
		default_io.write = fallback_io.write;
	}
	if ( io->connect ) {
		default_io.connect = io->connect;
	} else {
		default_io.connect = fallback_io.connect;
	}
	if ( io->ctx ) {
		default_io.ctx = io->ctx;
	} else {
		default_io.ctx = fallback_io.ctx;
	}
}
