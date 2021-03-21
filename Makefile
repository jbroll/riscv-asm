.PHONY: all test example clean test-gas test-suite-64 test-suite-32

all : example

example:
	./rva.tcl -march rv32g example.rva

clean:
	rm test/tmp/*

test-gas: 
	cd test-gas && $(MAKE) test

test-suite-64:
	for test in `ls ../riscv-tests/isa/rv64ui-p-* | grep -v dump` ; do printf "%35s" $$test; ./rva.tcl -march rv64gc -x $$test; done

test-suite-32:
	for test in `ls ../riscv-tests/isa/rv32ui-p-* | grep -v dump` ; do printf "%35s" $$test; ./rva.tcl -march rv32gc -x $$test; done

