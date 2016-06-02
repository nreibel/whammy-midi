# Path to build tools
CC=avr-gcc
OBJCOPY=avr-objcopy
SIZE=avr-size
UPLOAD=avrdude

# Output files
OBJ=_obj
OUT=out
FNAME=out_$(ARCH)

# Compilation options and flags
ARCH=atmega88
WARNINGS=all extra undef
CFLAGS=-O2 -g0 -mmcu=$(ARCH) -ffunction-sections -fdata-sections
LDFLAGS=-Wl,-gc-sections -Wl,--relax

# Serial config
SERIAL_TTY=/dev/ttyACM0
SERIAL_MONITOR=screen
SERIAL_BAUD_RATE=9600

# avrisp  : use arduino as ISP to flash another chip
# arduino : usual Arduino flash process
PROGRAMMER=avrisp

INCLUDES=\
	src/comp/timer/api \
	src/comp/os/api \
	src/comp/serial/api \
	src/comp/port/api \
	src/comp/eeprom/api \
	src/comp/keys/api \
	src/comp/app/api \
	src/config/timer \
	src/config/os \
	src/config/serial \
	src/config/port \
	src/config/eeprom \
	src/config/keys \
	src/config/app

all: prepare hex

hex: timer os serial port eeprom keys app
	@echo "Linking object files..."
	@$(CC) $(LDFLAGS) $(CFLAGS) $(OBJ)/$(ARCH)/*.o -o $(OUT)/$(FNAME).elf
	@echo "Creating HEX file..."
	@$(OBJCOPY) -O ihex $(OUT)/$(FNAME).elf $(OUT)/$(FNAME).hex
	@echo "=================================="
	@$(SIZE) -C --mcu=$(ARCH) $(OUT)/$(FNAME).elf
	@echo "Done"

clean:
	@echo "Cleaning workspace"
	@rm -Rf $(OBJ)
	@rm -Rf $(OUT)

prepare:
	@echo "Preparing workspace"
	@mkdir -p $(OBJ)/$(ARCH) $(OUT)
	
fuses:
	@$(UPLOAD) -b 19200 -c $(PROGRAMMER) -p $(ARCH) -P $(SERIAL_TTY) -U lfuse:w:0x5e:m -U hfuse:w:0xdf:m -U efuse:w:0xf9:m

upload:
	@$(UPLOAD) -b 19200 -c $(PROGRAMMER) -p $(ARCH) -P $(SERIAL_TTY) -U flash:w:$(OUT)/$(FNAME).hex

# Each software component must be created here
app:    src/comp/app/src/app.o src/config/app/app_cfg.o
timer:  src/comp/timer/src/timer.o
os:     src/comp/os/src/os.o src/config/os/os_cfg.o
serial: src/comp/serial/src/serial.o
port:   src/comp/port/src/port.o src/config/port/port_cfg.o
eeprom: src/comp/eeprom/src/eeprom.o
keys:   src/comp/keys/src/keys.o src/config/keys/keys_cfg.o

# Generic rules for compiling objects
%.o: %.c
	@echo "Compiling $<"
	@$(CC) $(addprefix -I,$(INCLUDES)) $(addprefix -W,$(WARNINGS)) $(CFLAGS) -c -o $(OBJ)/$(ARCH)/$(@F) $<

# Serial monitor
monitor: stop
	@xterm -e "$(SERIAL_MONITOR) $(SERIAL_TTY) $(SERIAL_BAUD_RATE)" &

stop:
	@-killall -q $(SERIAL_MONITOR) 2>/dev/null; true
