PROJ_NAME=base

# Path to dependencies.
LIBS_DIR=${HOME}/opt

# Path to LIBC.
#LIBC_DIR=$(LIBS_DIR)

# Link to ST Drivers. Using version 1.10.0
STM_DIR=$(LIBS_DIR)/STM32CubeF3
STM_SRC+=$(STM_DIR)/Drivers/STM32F3xx_HAL_Driver/Src

# Link to FreeRTOS. Using version 10.2.1
RTOS_DIR=$(LIBS_DIR)/FreeRTOS

SRCS=fw/src/main.c
SRCS+=hw/src/stm32f3xx_it.c
SRCS+=sys/src/system_stm32f3xx.c
SRCS+=$(STM_DIR)/Drivers/CMSIS/Device/ST/STM32F3xx/Source/Templates/gcc/startup_stm32f302x8.s
SRCS+=$(STM_SRC)/stm32f3xx_hal_gpio.c
SRCS+=$(STM_SRC)/stm32f3xx_hal.c
SRCS+=$(STM_SRC)/stm32f3xx_hal_cortex.c
SRCS+=$(STM_SRC)/stm32f3xx_hal_rcc.c
SRCS+=$(STM_SRC)/stm32f3xx_hal_rcc_ex.c

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
INC_DIRS=$(STM_DIR)/Drivers/CMSIS/Device/ST/STM32F3xx/Include
INC_DIRS+=$(STM_DIR)/Drivers/STM32F3xx_HAL_Driver/Inc
INC_DIRS+=$(STM_DIR)/Drivers/CMSIS/Include
INC_DIRS+=$(RTOS_DIR)/include
INC_DIRS+=$(RTOS_DIR)/portable/GCC/ARM_CM4F

# Project section.
INC_DIRS+=./sys/inc
INC_DIRS+=./hw/inc
INC_DIRS+=./fw/inc
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

LINKER_FILE=./linker/stm32f30_flash.ld

LFLAGS=$(TARGET_FLAGS) \
			 -Wl,-Map,$(BUILD_DIR)/$(PROJ_NAME).map -T$(LINKER_FILE) \
			 -Wl,--gc-sections \
			 -Wl,--print-memory-usage \
			 -lc \

INCLUDE=$(addprefix -I,$(INC_DIRS))

DEFS=-DSTM32F302x8

$(PROJ_NAME): $(PROJ_NAME).elf

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

$(PROJ_NAME).elf: $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(INCLUDE) $(DEFS) $(CFLAGS) $(LFLAGS) $^ -o $(BUILD_DIR)/$@
	$(OBJCOPY) -O ihex $(BUILD_DIR)/$(PROJ_NAME).elf   $(BUILD_DIR)/$(PROJ_NAME).hex
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(PROJ_NAME).elf $(BUILD_DIR)/$(PROJ_NAME).bin
	$(SZ) $(BUILD_DIR)/$(PROJ_NAME).elf

dump:
	$(OBJDUMP) -D --source $(BUILD_DIR)/$(PROJ_NAME).elf > $(BUILD_DIR)/$(PROJ_NAME).dump
	
clean:
	rm -f *.o $(BUILD_DIR)/$(PROJ_NAME).elf $(BUILD_DIR)/$(PROJ_NAME).hex $(BUILD_DIR)/$(PROJ_NAME).bin $(BUILD_DIR)/$(PROJ_NAME).map $(BUILD_DIR)/$(PROJ_NAME).dump $(BUILD_DIR)/$(PROJ_NAME).d
	rmdir $(BUILD_DIR)

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

.PHONY: dump clean flash stlink all debug $(PROJ_NAME)
