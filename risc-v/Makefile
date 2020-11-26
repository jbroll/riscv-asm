
all : instr.tab exec.awk

instr.tab : extract.awk opcodes/opcodes-rv32i
	./extract.awk < opcodes/opcodes-rv32i > instr.tab

exec.awk : mkexec.awk  opcodes/opcodes-rv32i exprs.tab
	./mkexec.awk <  opcodes/opcodes-rv32i  > exec.awk
