.PHONY: all test example clean

all : example

example:
	./rva.tcl -march rv32gc example.rva

clean:
	rm test/tmp/*

test: 
	cd test && $(MAKE) test

