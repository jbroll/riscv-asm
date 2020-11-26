function exec(instr) {
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # beq
         if ( R[rs1_decode(instr)] == R[rs2_decode(instr)] ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) ) {
        # bne
         if ( R[rs1_decode(instr)] != R[rs2_decode(instr)] ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x4000 == and(instr, 0x7000) ) {
        # blt
         if ( R[rs1_decode(instr)] < R[rs2_decode(instr)] ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) ) {
        # bge
         if ( R[rs1_decode(instr)] >= R[rs2_decode(instr)] ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x6000 == and(instr, 0x7000) ) {
        # bltu
         if ( and(0xFFFFFFFF, rs1) < and(0xFFFFFFFF, rs2) ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x60 == and(instr, 0x7c) && 0x7000 == and(instr, 0x7000) ) {
        # bgeu
         if ( and(0xFFFFFFFF, rs1) >= and(0xFFFFFFFF, rs2) ) { pc = pc + bimm12_decode(instr) }
    }
    if ( 0x3 == and(instr, 0x3) && 0x64 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # jalr
         R[rd_decode(instr)] = pc + 4; pc = jimm20
    }
    if ( 0x3 == and(instr, 0x3) && 0x6c == and(instr, 0x7c) ) {
        # jal
         ra = pc + 4; pc = jimm20
    }
    if ( 0x3 == and(instr, 0x3) && 0x34 == and(instr, 0x7c) ) {
        # lui
         R[rd_decode(instr)] = imm12_decode(instr) * exp2(12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x14 == and(instr, 0x7c) ) {
        # auipc
         pc = pc + imm20
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # addi
         R[rd_decode(instr)] = and(0xFFFFFFFF, R[rs1_decode(instr)] + imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfc000000) ) {
        # slli
         R[rd_decode(instr)] = R[rs1_decode(instr)] / expr2(imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x2000 == and(instr, 0x7000) ) {
        # slti
         R[rd_decode(instr)] = R[rs1_decode(instr)] == imm12
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x3000 == and(instr, 0x7000) ) {
        # sltiu
         R[rd_decode(instr)] = R[rs1_decode(instr)] == imm12
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x4000 == and(instr, 0x7000) ) {
        # xori
         R[rd_decode(instr)] = xor(rs1, imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfc000000) ) {
        # srli
         R[rd_decode(instr)] = R[rs1_decode(instr)] * exp2(shamt)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) && 0x40000000 == and(instr, 0xfc000000) ) {
        # srai
         R[rd_decode(instr)] = R[rs1_decode(instr)] / exp2(shamt)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x6000 == and(instr, 0x7000) ) {
        # ori
         R[rd_decode(instr)] = or(rs1, imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x10 == and(instr, 0x7c) && 0x7000 == and(instr, 0x7000) ) {
        # andi
         R[rd_decode(instr)] = and(rs1, imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # add
         R[rd_decode(instr)] = and(0xFFFFFFFF, R[rs1_decode(instr)] + rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) && 0x40000000 == and(instr, 0xfe000000) ) {
        # sub
         R[rd_decode(instr)] = and(0xFFFFFFFF, R[rs1_decode(instr)] - rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # sll
         R[rd_decode(instr)] = R[rs1_decode(instr)] * exp2(shamt)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x2000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # slt
         R[rd_decode(instr)] = R[rs1_decode(instr)] == rs2
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x3000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # sltu
         R[rd_decode(instr)] = R[rs1_decode(instr)] == rs2
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x4000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # xor
         R[rd_decode(instr)] = xor(rs1, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # srl
         R[rd_decode(instr)] = R[rs1_decode(instr)] / exp2(shamt)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) && 0x40000000 == and(instr, 0xfe000000) ) {
        # sra
         R[rd_decode(instr)] = R[rs1_decode(instr)] / exp2(shamt)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x6000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # or
         R[rd_decode(instr)] = or(rs1, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x30 == and(instr, 0x7c) && 0x7000 == and(instr, 0x7000) && 0x0 == and(instr, 0xfe000000) ) {
        # and
         R[rd_decode(instr)] = and(rs1, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x0 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # lb
         R[rd_decode(instr)] = load_byte(rs1 + imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x0 == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) ) {
        # lh
         R[rd_decode(instr)] = load_half(rs1 + imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x0 == and(instr, 0x7c) && 0x2000 == and(instr, 0x7000) ) {
        # lw
         R[rd_decode(instr)] = load_word(rs1 + imm12)
    }
    if ( 0x3 == and(instr, 0x3) && 0x0 == and(instr, 0x7c) && 0x4000 == and(instr, 0x7000) ) {
        # lbu
         R[rd_decode(instr)] = and(0x000000FF, load_byte(rs1 + imm12))
    }
    if ( 0x3 == and(instr, 0x3) && 0x0 == and(instr, 0x7c) && 0x5000 == and(instr, 0x7000) ) {
        # lhu
         R[rd_decode(instr)] = and(0x0000FFFF, load_word(rs1 + imm12))
    }
    if ( 0x3 == and(instr, 0x3) && 0x20 == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # sb
         stor_byte(rs1 + simm12, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x20 == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) ) {
        # sh
         stor_half(rs1 + simm12, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0x20 == and(instr, 0x7c) && 0x2000 == and(instr, 0x7000) ) {
        # sw
         stor_word(rs1 + simm12, rs2)
    }
    if ( 0x3 == and(instr, 0x3) && 0xc == and(instr, 0x7c) && 0x0 == and(instr, 0x7000) ) {
        # fence
        
    }
    if ( 0x3 == and(instr, 0x3) && 0xc == and(instr, 0x7c) && 0x1000 == and(instr, 0x7000) ) {
        # fence.i
        
    }
}
