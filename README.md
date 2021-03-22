
A risc-v assembler/disassembler/emulator in Tcl

## Assembler
This simple risc-v assembler supports rv32 and rv64 with several standard
extensions.  Its output is a primitive listing with source line, address and
bytes in hex.  It does not currently support writing ELF.

Instruciton sets and extensions:
  * rv32G (IMAFD_Zicsr_Zifencei)
  * rv64G (IMAFD_Zicsr_Zifencei)
  * C - Compressed instructions
  * E - 16 registers
  * Q - Quad floats
  * Zfinx - Floats in X registers

A very simple example.rva is included.  Try `make example`

    $ make example
    ./rva.tcl -march rv32gc example.rva
     00005 0100 00C58533   add a0 a1 a2
     00006 0104 FFFFC297   auipc t0 top
     00006 0108 12E1       addi t0 t0 top
     00007 010A 8282       jalr x0 t0 0

TODO: forward and local labels

The accepted instruction sets are defined in files sourced from the opcodes
directory.  These files derrive from those available in the
[riscv/riscv-opcodes](https://github.com/riscv/riscv-opcodes) repository, but
are highly edited.  Additional opcodes can be easily added by including X
entensions in the extensions directory and sourcing them by suffixing the
-march option with the extension name in the risc-v accepted usage.

For example:

    rva.tcl -march rv32gc_Xaname

An opcode mnemonic instruction is a Tcl proc that calls 'assemble'.  A few
pseudo instructions are in macros.tcl and more can easily be added.  The macro
and alias syntax are slight simplifications of standard Tcl.  More complex
pseudo instructions benifit by being defined directly as procs.

The currently supported instructions are tested against the gnu gas assembler.
The tests are run with make invoking the test scripts.

    make test

A few differences are still present with gas and rva.tcl compressing
slightly different sets of instructions and with referencing labels.

## Disassembler

All the instructions supported by the assembler are supported here.  The
disasembler can be used on elf format files and will disassemble all the
sections with PROGBITS set.

The disassembler is invoked with the -d or -dc switches.  The -dc switch allows
the display of the compact instruction mnumonics.

## Emulator

The emulator can load and run the .lst files produced by the assembler and
statically linked elf files files from the risc-v gnu tool chain.  The rv32ic
and rv64ic instruction sets are fully supported.  Most of the M instructions
are supported.  Missing are rv32 mulhsu and a few more from rv64m fail the
test.  The risc-tests/isa test suite passes for these instructions.  The only 
supported system call is 'exit'

The emulator is invoked with -x switch and has an interactive mode enabled with
the -v switch.

The emulator is tested by running the riscv-tests generated by the gnu tool chain.
The tests can be run by cloning the [riscv/riscv-tests](https://github.com/riscv/riscv-tests) repository 
in an adjacent directory and building it.  Then return here and run :

    make test-suite

All the rv32i and rv64i tests should pass, with some of the M extension tests
failing.  Tests of other instruciton sets are not invoked yet.

