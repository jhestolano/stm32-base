PROJ_NAME=base

# Path to dependencies.
LIBS_DIR=${HOME}/opt

# Path to LIBC.
#LIBC_DIR=$(LIBS_DIR)

# Link to ST Drivers. Using version 1.10.0
# STM_DIR=$(LIBS_DIR)/STM32CubeF3

# Link to FreeRTOS. Using version 10.2.1
RTOS_DIR=./rtos

SRCS=fw/src/main.c
SRCS+=sys/src/system_stm32f3xx.c
SRCS+=sys/src/startup_stm32f302x8.s

HAL_SRCS=hal/src/stm32f3xx_hal_gpio.c
HAL_SRCS+=hal/src/stm32f3xx_hal.c
HAL_SRCS+=hal/src/stm32f3xx_hal_cortex.c
HAL_SRCS+=hal/src/stm32f3xx_hal_rcc.c
HAL_SRCS+=hal/src/stm32f3xx_hal_rcc_ex.c

# This is the location of port.c file.
# SRCS+=$(RTOS_DIR)/portable/GCC/ARM_CM4F/port.c
# SRCS+=$(RTOS_DIR)/portable/MemMang/heap_2.c

# This is where the actual implementation of FreeRTOS is.
#SRCS+=$(RTOS_DIR)/tasks.c
#SRCS+=$(RTOS_DIR)/timers.c
#SRCS+=$(RTOS_DIR)/queue.c
#SRCS+=$(RTOS_DIR)/list.c
#SRCS+=$(RTOS_DIR)/stream_buffer.c

# Drivers section.
# INC_DIRS=$(STM_DIR)/Drivers/CMSIS/Device/ST/STM32F3xx/Include
# INC_DIRS+=$(STM_DIR)/Drivers/STM32F3xx_HAL_Driver/Inc
# INC_DIRS+=$(STM_DIR)/Drivers/CMSIS/Include
# INC_DIRS+=$(RTOS_DIR)/include
# INC_DIRS+=$(RTOS_DIR)/portable/GCC/ARM_CM4F

# Project section.
INC_DIRS+=./sys/inc
INC_DIRS+=./hw/inc
INC_DIRS+=./fw/inc
INC_DIRS+=./hal/inc
INC_DIRS+=.

# Use a specific GCC version as follows: CC=$(GCC_PATH)/arm-none-eabi-gcc
# Where GCC_PATH points to the installation path:
# GCC_PATH=$(LIBS_DIR)/gcc-arm-none-eabi-8.2.1.1.4/bin/
CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump
GDB=arm-none-eabi-gdb-py
SZ=arm-none-eabi-size
BUILD_DIR=./build

TARGET_FLAGS=-mcpu=cortex-m4 \
						 -mthumb \
						 -mfpu=fpv4-sp-d16 \
						 -mfloat-abi=hard \

LIB_FLAGS=$(TARGET_FLAGS) \
			-Os \
			-Wall \
			--specs=nosys.specs \
			-fdata-sections \
			-ffunction-sections \

CFLAGS=$(TARGET_FLAGS) \
			-g \
			-Og \
			-Wall \
			-lc \
			--specs=nosys.specs \
			-fsingle-precision-constant \
			-fdata-sections \
			-ffunction-sections \
			-fno-math-errno \

HFLAGS=$(TARGET_FLAGS) \
			-Os \
			-Wall \
			-lc \
			--specs=nosys.specs \
			-fsingle-precision-constant \
			-fdata-sections \
			-ffunction-sections \
			-fno-math-errno \

LINKER_FILE=./linker/stm32f30_flash.ld

LFLAGS=$(TARGET_FLAGS) \
			 -Wl,-Map,$(BUILD_DIR)/$(PROJ_NAME).map -T$(LINKER_FILE) \
			 -Wl,--gc-sections \
			 -Wl,--print-memory-usage \
			 -lc \


# Dependencies and object file definitions,
HAL_OBJS=$(subst .c,.o,$(HAL_SRCS))

RTOS_OBJS=$(subst .c,.o,$(HAL_SRCS))

INCLUDE=$(addprefix -I,$(INC_DIRS))

# Obj files are outputt to BUILD_DIR directory:
HAL_OBJS_OUT=$(addprefix $(BUILD_DIR)/out/,$(notdir $(HAL_OBJS)))

RTOS_OBJS_OUT=$(addprefix $(BUILD_DIR)/out/,$(notdir $(RTOS_OBJS)))

# Rules:
DEFS=-DSTM32F302x8

$(PROJ_NAME): $(PROJ_NAME).elf

%.o: %.c
	$(CC) $(INCLUDE) $(DEFS) -c -o $@ $< $(CFLAGS) $(EXTRA_FLAGS)
	mkdir -p $(BUILD_DIR)/out && mv $@ $(BUILD_DIR)/out

# Use compiler flags w/ optimizations turned for libraries, as it most likely
# this will not need to be debugged.
$(HAL_OBJS): CFLAGS:=$(LIB_FLAGS)

$(RTOS_OBJS):  CFLAGS:=$(LIB_FLAGS)

$(PROJ_NAME).elf: $(SRCS) $(HAL_OBJS) $(RTOS_OBJS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(INCLUDE) $(DEFS) $(CFLAGS) $(LFLAGS) $(SRCS) $(HAL_OBJS_OUT) -o $(BUILD_DIR)/$@
	$(OBJCOPY) -O ihex $(BUILD_DIR)/$(PROJ_NAME).elf   $(BUILD_DIR)/$(PROJ_NAME).hex
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(PROJ_NAME).elf $(BUILD_DIR)/$(PROJ_NAME).bin
	$(SZ) $(BUILD_DIR)/$(PROJ_NAME).elf

hal: $(HAL_OBJS)

rtos: $(RTOS_OBJS)

dump:
	$(OBJDUMP) -D --source $(BUILD_DIR)/$(PROJ_NAME).elf > $(BUILD_DIR)/$(PROJ_NAME).dump
	
clean:
	rm -f *.o $(BUILD_DIR)/$(PROJ_NAME).elf $(BUILD_DIR)/$(PROJ_NAME).hex $(BUILD_DIR)/$(PROJ_NAME).bin $(BUILD_DIR)/$(PROJ_NAME).map $(BUILD_DIR)/$(PROJ_NAME).dump $(BUILD_DIR)/$(PROJ_NAME).d
	rm -rf $(BUILD_DIR)

flash:
	st-flash write $(BUILD_DIR)/$(PROJ_NAME).bin 0x8000000

stlink:
	st-util -p4242

all:
	make clean && make && make flash

# before you start gdb, you must start st-util
debug:
	st-util &
	#$(GDB) $(BUILD_DIR)/$(PROJ_NAME).elf --command=./debug/cmd.gdb
	$(GDB) $(BUILD_DIR)/$(PROJ_NAME).elf
	killall st-util

.PHONY: dump clean flash stlink all debug hal $(PROJ_NAME)
