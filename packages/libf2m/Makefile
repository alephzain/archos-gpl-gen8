ifeq ($(ARCH), arm)
CROSS = arm-linux-
else
CROSS = 
endif

TGT_PATH = $(ARCH)
INCS = -Isrc
VPATH = ./src

CC   = $(CROSS)gcc
LINK = $(CROSS)gcc
CFLAGS += -g -O2 -D_LARGEFILE_SOURCE -fPIC -D_FILE_OFFSET_BITS=64 $(INCS)
LD = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy

CMD_CC_O_C =  $(CC) $(CFLAGS) -o $@ -c $<

SRC = dcprediction.c flv2mpeg4.c flvdecoder.c m4vencode.c

OBJS = $(patsubst %,$(TGT_PATH)/%,$(SRC:.c=.o))

DEPDIR = .deps

MAKEDEPEND = $(CC) -MM $(CFLAGS) -MT $@ -o $(TGT_PATH)/$(DEPDIR)/$*.dep $<

$(TGT_PATH)/%.o : %.c
	@mkdir -p $(TGT_PATH)/$(DEPDIR)
	@$(MAKEDEPEND); 
	$(CMD_CC_O_C)

$(TGT_PATH)/libf2m.a: $(OBJS)
	$(LD) -o $(TGT_PATH)/libf2m.a -i $(OBJS)

$(TGT_PATH)/libf2m.so: $(OBJS)
	$(LINK) -shared -o $(TGT_PATH)/libf2m.so $(OBJS)

test: f2m

f2m: src/main.c src/fetch.c $(TGT_PATH)/libf2m.a
	$(CC) -o $(TGT_PATH)/f2m src/main.c src/fetch.c $(TGT_PATH)/libf2m.a
clean:
	@rm -rf $(TGT_PATH)

# include deps depending on target
ifneq (,$(TGT_PATH))
-include $(SRC:%.c=$(TGT_PATH)/$(DEPDIR)/%.dep)
endif


