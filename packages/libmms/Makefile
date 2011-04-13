ifeq ($(ARCH), arm)
CROSS = arm-linux-
else
CROSS = 
endif

INCS = -Isrc
VPATH = ./src

CC   = $(CROSS)gcc
LINK = $(CROSS)gcc
CFLAGS += -g -O2 -D_LARGEFILE_SOURCE -fPIC -D_FILE_OFFSET_BITS=64 $(INCS)
AR = $(CROSS)ar
OBJCOPY = $(CROSS)objcopy

CMD_CC_O_C =  $(CC) $(CFLAGS) -o $@ -c $<

SRC = mms.c mmsh.c mms_io.c no_glib.c uri.c asf.c

OBJS = $(patsubst %,$(ARCH)/%,$(SRC:.c=.o))

DEPDIR = .deps

MAKEDEPEND = $(CC) -MM $(CFLAGS) -MT $@ -o $(ARCH)/$(DEPDIR)/$*.dep $<

$(ARCH)/%.o : %.c
	@mkdir -p $(ARCH)/$(DEPDIR)
	@$(MAKEDEPEND);
	$(CMD_CC_O_C)

$(ARCH)/libmms.a: $(OBJS)
	$(AR) r $(ARCH)/libmms.a $(OBJS)

$(ARCH)/libmms.so: $(OBJS)
	$(LINK) -shared -o $(ARCH)/libmms.so $(OBJS)

clean:
	@rm -rf $(ARCH)

# include deps depending on target
ifneq (,$(ARCH))
-include $(SRC:%.c=$(ARCH)/$(DEPDIR)/%.dep)
endif
