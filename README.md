# Super simple microcodedd RISCV32I cpu.

 - 3(LUI/AUIPC/JAL), 4(ALU/BRANCH/JALR), 6(STORE/LOAD) clocks cycles per instrution.
 - No fence or CSR instructions.
 - No MMU.
 - Uses APB bus.

```
git submodule update --init --recursive
make run_tests
```
