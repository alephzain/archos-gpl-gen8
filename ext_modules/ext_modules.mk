EXT_MODULES_BUILD_DIR = $(shell pwd)
EXT_MODULES_DIR       = ext_modules
KERNEL_SOURCE         = ../linux

.PHONY: ext_modules

$(EXT_MODULES_BUILD_DIR)/$(EXT_MODULES_DIR):
	@mkdir -p $(EXT_MODULES_BUILD_DIR)/$(EXT_MODULES_DIR)	

ext_modules: $(EXT_MODULES_BUILD_DIR)/$(EXT_MODULES_DIR)
	@(PATH=$(shell pwd)/$(TOOLCHAIN_PATH):$(PATH) ARCH=arm $(MAKE) -C $(KERNEL_SOURCE) O=$(EXT_MODULES_BUILD_DIR)/linux  M=../$(EXT_MODULES_DIR) $(MAKE_J) modules)

ext_modules-clean: 
	- rm -rf  $(EXT_MODULES_BUILD_DIR)/$(EXT_MODULES_DIR)
