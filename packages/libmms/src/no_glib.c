#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include <no_glib.h>

void ng_free( void *mem )
{
	if (mem)
		free( mem );
}

void *ng_malloc0 ( unsigned long size)
{
	if (size == 0)
		return NULL;
	return calloc ( size, 1 );
}

void *ng_malloc ( unsigned long size)
{
	if (size == 0)
		return NULL;
	return malloc ( size );
}

NGString *ng_string_sized_new(unsigned long size)
{
	NGString *s = (NGString*)ng_malloc(sizeof(NGString));
	if (!s)
		return NULL;
	
	s->str = (char*)ng_malloc(size+1);
	
	if (!s->str)
	{
		ng_free(s);
		return NULL;
	}

	memset(s->str, 0, s->size+1);
	s->size = size;

	return s;	
}

void ng_string_free(NGString *s, int del_data)
{
	if (del_data)
		ng_free(s->str);
	ng_free(s);
}

#define ng_new( type, length ) (type*)malloc(length)

int ng_string_sprintfa(NGString *s, const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	i = snprintf(s->str, s->size, fmt, args);
	va_end(args);
	s->str[s->size] = 0;
	return i;
}

NGString *ng_string_append(NGString *dest, const char *src)
{
	strncat(dest->str, src, dest->size);
	dest->str[dest->size] = 0;
	
	return dest;
}

NGString *ng_string_append_c(NGString *dest, const char src)
{
	int len = strlen(dest->str);
	
	if (len >= dest->size)
		return dest;
		
	
	dest->str[len] = src;
	dest->str[dest->size] = 0;
	
	return dest;
}

char* ng_strdup (const char *str)
{
	char *new_str;
	int length;

	if (str) {
		length = strlen(str) + 1;
		new_str = ng_new (char, length);
		memcpy (new_str, str, length);
	} else {
		new_str = NULL;
	}
	return new_str;
}

char *ng_strndup (const char *str, int n)
{
	char *new_str;
 	
	if (str) {
		new_str = ng_new (char, n + 1);
		strncpy (new_str, str, n);
		new_str[n] = '\0';
	} else {
		new_str = NULL;
 	}
	return new_str;
}
