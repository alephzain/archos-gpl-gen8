#ifndef _NO_GLIB_H_
#define _NO_GLIB_H_


#define	FALSE	(0)
#define	TRUE	(!FALSE)

typedef struct {
	unsigned long size;
	char *str;
} NGString;

typedef int ngint;
typedef unsigned int nguint;
typedef int ngboolean;
typedef const void *ngconstpointer;
typedef unsigned int ngsize;
char* ng_strdup (const char *str);
char *ng_strndup (const char *str, int n);

void *ng_malloc0 ( unsigned long size);
void ng_free( void *mem );

#define ng_new0(struct_type, n_structs)          \
    ((struct_type *) ng_malloc0 (((ngsize) sizeof (struct_type)) * ((ngsize) (n_structs))))

#define ng_return_if_fail(expr) {            \
     if (expr) { } else                     \
     {                                      \
         return;                            \
};                             }

#define ng_return_val_if_fail(expr,val)  {   \
     if (expr) { } else                     \
     {                                      \
       return (val);                        \
};                                      }

NGString *ng_string_sized_new(unsigned long size);
void ng_string_free(NGString *s, int del_data);

int ng_string_sprintfa(NGString *s, const char *fmt, ...);
NGString *ng_string_append(NGString *dest, const char *src);
NGString *ng_string_append_c(NGString *dest, const char src);


#endif
