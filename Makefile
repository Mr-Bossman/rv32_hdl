BUILD_DIR = build
PREFIX_NAME = RV32emu
CC = gcc
CXX = g++
CPPFLAGS = -DVPREFIX=${PREFIX_NAME} -Og
LDFLAGS =
CPP_SOURCES = src/test.cpp
V_SOURCES = hdl/sram.v hdl/prog_counter.v hdl/alu.v hdl/APB.v hdl/uart.v
INCV_SOURCES = 
INCLUDES = $(addprefix --include ${PREFIX_NAME}_,$(notdir $(INCV_SOURCES:.v=.h))) -include ${PREFIX_NAME}.h -include ${PREFIX_NAME}___024root.h
CPPFLAGS += ${INCLUDES}
CROSS_COMPILE=~/linux/buildroot/output/host/bin/riscv32-linux-

.PHONY: tests

all: ${PREFIX_NAME}

${PREFIX_NAME} : ${V_SOURCES} ${CPP_SOURCES}
	verilator -Wall --Mdir ${BUILD_DIR} -cc ${V_SOURCES} -prefix ${PREFIX_NAME} -CFLAGS "${CPPFLAGS}" ${CPP_SOURCES} --exe --top-module prog_counter
	$(MAKE) -C ${BUILD_DIR} -f ${PREFIX_NAME}.mk ${PREFIX_NAME}
	cp ${BUILD_DIR}/${PREFIX_NAME} .

run: ${PREFIX_NAME}
	./${PREFIX_NAME}

tests:
	rm test.vh || true
	$(MAKE) -C tests CROSS_COMPILE=$(CROSS_COMPILE)

run_tests: all tests
	./${PREFIX_NAME}

rv32asm: src/rv32.s src/rv32.lds
	${CROSS_COMPILE}as src/rv32.s -o ${BUILD_DIR}/example.o
	${CROSS_COMPILE}ld --gc-sections -T src/rv32.lds ${BUILD_DIR}/example.o -o ${BUILD_DIR}/example.elf
	${CROSS_COMPILE}objcopy -O verilog --verilog-data-width=4 --reverse-bytes=4 -j .text ${BUILD_DIR}/example.elf test.vh

clean_exe:
	rm -rf ${PREFIX_NAME}

clean :
	rm -rf ${PREFIX_NAME} ${BUILD_DIR}
