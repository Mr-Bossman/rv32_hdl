
TESTS_PATH=riscv-tests/isa/rv32ui
BUILD_DIR = ../build
CROSS_COMPILE=riscv32-linux-
CLFAGS = -march=rv32i -mabi=ilp32 -mlittle-endian -I${TESTS_PATH}/../macros/scalar -I${TESTS_PATH}/../../env -Icustom/
#include ${TESTS_PATH}/Makefrag
rv32ui_sc_tests = \
	simple \
	add addi \
	and andi \
	auipc \
	beq bge bgeu blt bltu bne \
	jal jalr \
	lb lbu lh lhu lw \
	lui \
	or ori \
	ma_data \
	sb sh sw \
	sll slli \
	slt slti sltiu \
	sra srai \
	srl srli \
	sub \
	xor xori \

S_SOURCES = $(addprefix $(TESTS_PATH)/,$(addsuffix .S, $(rv32ui_sc_tests)))
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(S_SOURCES:.S=.o)))

vpath %.S $(sort $(dir $(S_SOURCES)))

all: tests.vh

$(BUILD_DIR)/%.o: %.S
	${CROSS_COMPILE}gcc ${CLFAGS} -c -o $@ -DTEST_FUNC_NAME=$(notdir $(<:.S=)) -DTEST_FUNC_TXT='"$(notdir $(<:.S=))"' -DTEST_FUNC_RET=$(notdir $(<:.S=))_ret $<

tests.vh: $(OBJECTS) custom/start.S custom/linker.ld
	${CROSS_COMPILE}gcc ${CLFAGS}  -c  custom/start.S -o $(BUILD_DIR)/start.o
	${CROSS_COMPILE}gcc ${CLFAGS}  -Os -ffreestanding -nostdlib -Wl,-Bstatic,-T,custom/linker.ld $(BUILD_DIR)/start.o $(OBJECTS) -lgcc -o $(BUILD_DIR)/tests.elf
	${CROSS_COMPILE}objcopy -O binary -O verilog --gap-fill 0 --verilog-data-width=4 -j .text -j .data ${BUILD_DIR}/tests.elf ../test.vh
	sed -i s/@.*//g ../test.vh

clean:
	rm $(OBJECTS) $(BUILD_DIR)/start.o $(BUILD_DIR)/tests.elf ../test.vh || true
