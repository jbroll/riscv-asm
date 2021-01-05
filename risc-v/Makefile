
all : test32 test64

clean:
	rm test/*


W32_INSTRUCTIONS = 	opcodes/opcodes-rv32i 	\
 					opcodes/opcodes-rv32m	\
					opcodes/opcodes-rv32a	\
					opcodes/opcodes-rv32f  \
					opcodes/opcodes-rv32d	\
					opcodes/opcodes-zifencei
H32_INSTRUCTIONS = 	opcodes/opcodes-rvc	\
					opcodes/opcodes-rvdc	\
					opcodes/opcodes-rv32c	\
					opcodes/opcodes-rv32fc

test32: $(W32_INSTRUCTIONS) $(H32_INSTRUCTIONS)
	./asm-test w32 		 rv32g   $(W32_INSTRUCTIONS)
	./asm-test h32 		 rv32gc  $(H32_INSTRUCTIONS)
	./asm-test w32-short rv32gc  $(W32_INSTRUCTIONS)


W64_INSTRUCTIONS = 	opcodes/opcodes-rv32i 	\
 					opcodes/opcodes-rv32m	\
 					opcodes/opcodes-rv64m	\
					opcodes/opcodes-rv32a	\
					opcodes/opcodes-rv64a	\
					opcodes/opcodes-rv32f  	\
					opcodes/opcodes-rv64f  	\
					opcodes/opcodes-rv32d	\
					opcodes/opcodes-rv64d	\
					opcodes/opcodes-rv32q	\
					opcodes/opcodes-rv64q	\
					opcodes/opcodes-zifencei
H64_INSTRUCTIONS = 	opcodes/opcodes-rvc		\
					opcodes/opcodes-rvdc	\
					opcodes/opcodes-rv64c

test64: $(W64_INSTRUCTIONS) $(H64_INSTRUCTIONS)
	./asm-test w64 rv64gq  $(W64_INSTRUCTIONS)
	./asm-test h64 rv64gqc $(H64_INSTRUCTIONS)
