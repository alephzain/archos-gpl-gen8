#ifndef LOG_FILE
#error LOG_FILE has not been defined!
#endif

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <limits.h>
#include <errno.h>

#ifndef RTLD_NEXT
// strangely, defining __USE_GNU before should do the trick, but it doesn't...
# define RTLD_NEXT	((void *) -1l)
#endif

static int log_fd = -1;
static FILE *log_f = NULL;

static int prepare();

static int (*real_mkdir) (const char *pathname, mode_t mode) = NULL;
static int (*real_rename) (const char *oldpath, const char *newpath) = NULL;
static int (*real_rmdir) (const char *pathname) = NULL;
static int (*real_unlink) (const char *pathname) = NULL;
static int (*real_open) (const char *pathname, int flags, ...) = NULL;
static int (*real_creat) (const char *pathname, mode_t mode) = NULL;

static void logdir(const char *pathname, int ret) {
	char buf[PATH_MAX];

	if(log_fd == -1)
		prepare();

	// a share seems to be chrooted the path strings i see
	// start all as relative path inside the share.
	if(ret == -1 || !strncmp(pathname, "/var/", 5)) {
		return;
	}

	int path_len = strlen(pathname);

	// no need for that as proftpd already includes a / in front of the directory
	// buf[0] = '/';
	// strncpy(buf + 1, pathname, path_len);
	// path_len++;
	strncpy(buf, pathname, path_len);

	// directories can have an optional / at the end. strip it
	if(buf[path_len - 1] == '/') {
		buf[path_len - 1] = '\0';
		path_len--;
	}

	// strip the last path component. we are only interested
	// in the parent hosting a modification.
	char *cursor = buf + path_len - 1;
	while(*cursor != '/') {
		cursor--;
	}
	*(cursor + 1) = '\0';
	fprintf(log_f, "%s\n", buf);
	fflush(log_f);
}

int mkdir(const char *pathname, mode_t mode) {
	if(!real_mkdir)
		real_mkdir = dlsym(RTLD_NEXT, "mkdir");

	int ret = real_mkdir(pathname, mode);
	logdir(pathname, ret);
	return ret;
}

int rename(const char *oldpath, const char *newpath) {
	if(!real_rename)
		real_rename = dlsym(RTLD_NEXT, "rename");

	int ret = real_rename(oldpath, newpath);
	logdir(oldpath, ret);
	logdir(newpath, ret);
	return ret;
}

int rmdir(const char *pathname) {
	if(!real_rmdir)
		real_rmdir = dlsym(RTLD_NEXT, "rmdir");

	int ret = real_rmdir(pathname);
	logdir(pathname,ret);
	return ret;
}

int unlink(const char *pathname) {
	if(!real_unlink)
		real_unlink = dlsym(RTLD_NEXT, "unlink");

	int ret = real_unlink(pathname);
	logdir(pathname, ret);
	return ret;
}

int open64(const char *pathname, int flags, ...) {
	if(flags & O_CREAT) {
		va_list ap;
		va_start(ap, flags);
		mode_t mode = va_arg(ap, mode_t);
		va_end(ap);
		return open(pathname, flags, mode);
	}
	else {
		return open(pathname, flags);
	}
}

int open(const char *pathname, int flags, ...) {
	if(!real_open)
		real_open = dlsym(RTLD_NEXT, "open");

	int ret;
	if(flags & O_CREAT) {
		va_list ap;
		va_start(ap, flags);
		mode_t mode = va_arg(ap, mode_t);
		va_end(ap);
		ret = real_open(pathname, flags, mode);
	} else {
		ret = real_open(pathname, flags);
	}

	if((flags & O_RDWR) || (flags & O_WRONLY)) {
		logdir(pathname, ret);
	}
	return ret;
}

int creat(const char *pathname, mode_t mode) {
	if(!real_creat)
		real_creat = dlsym(RTLD_NEXT, "creat");

	int ret = real_creat(pathname, mode);
	logdir(pathname, ret);
	return ret;
}

static int prepare() {
	if(log_fd == -1) {
		if(!real_open)
			real_open = dlsym(RTLD_NEXT, "open");

		log_fd = real_open(LOG_FILE, O_WRONLY | O_CREAT | O_APPEND, S_IRUSR | S_IRGRP | S_IWUSR | S_IWGRP );
		if(log_fd == -1) {
			printf("Opening " LOG_FILE " failed!\n");
		} else {
			log_f = fdopen(log_fd, "a");
			if(!log_f) {
				printf("Unable to fdopen (%s)\n", strerror(errno));
				exit(42);
			}
		}

	}

	return 0;
}
