TARGET_EXEC ?= loader.bin

BUILD_DIR ?= ./build
SRC_DIRS ?= ./

SRCS := $(shell find -L $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.asm)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

AS := ~/SDKs/nesasm/nesasm
ASFLAGS := -S -raw

# consts
LOADER_SKIP := 16480 #16640
LOADER_SIZE := 16288 #16128


all: $(BUILD_DIR)/$(TARGET_EXEC)

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	cat $+ > $@

$(BUILD_DIR)/%.asm.o: %.asm
	$(MKDIR_P) $(dir $@)
	ln -sf ../$< $(BUILD_DIR)/$<.s
	$(AS) $(ASFLAGS) $(BUILD_DIR)/$<.s
	dd if=$(BUILD_DIR)/$<.nes skip=$(LOADER_SKIP) bs=1 count=$(LOADER_SIZE) of=$@


.PHONY: all clean

clean:
	$(RM) -r $(BUILD_DIR)/*.o

-include $(DEPS)

MKDIR_P ?= mkdir -p
