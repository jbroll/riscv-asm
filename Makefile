.PHONY: all test example clean test-gas test-suite-64 test-suite-32

all : example

test:
	$(MAKE) test-suite-32
	$(MAKE) test-suite-64
	$(MAKE) test-gas

example:
	./rva.tcl -march rv32gc example.rva | tee example.lst

clean:
	rm test/tmp/*

test-gas: 
	cd test-gas && $(MAKE) test

test-suite-32:
	for test in `ls ../riscv-tests/isa/rv32u[ic]-p-* | grep -v dump` ; do printf "%35s" $$test; ./rva.tcl -march rv32gc -x $$test; done

test-suite-64:
	for test in `ls ../riscv-tests/isa/rv64u[ic]-p-* | grep -v dump` ; do printf "%35s" $$test; ./rva.tcl -march rv64gc -x $$test; done
