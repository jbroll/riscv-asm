.text
.org 0x0000
.global here
here:
c.nop        # c.nop 
c.addi16sp sp,16       # c.addi16sp 16
c.jr x27       # c.jr x27
c.jalr x27       # c.jalr x27
c.ebreak        # c.ebreak 
c.addi4spn x12,sp,16       # c.addi4spn x12 16
c.lw x12,16(x13)       # c.lw x12 x13 16
c.sw x12,16(x13)       # c.sw x12 x13 16
c.addi x27,16       # c.addi x27 16
c.li x27,16       # c.li x27 16
c.lui x27,16       # c.lui x27 16
c.andi x12,16       # c.andi x12 16
c.sub x12,x13       # c.sub x12 x13
c.xor x12,x13       # c.xor x12 x13
c.or x12,x13       # c.or x12 x13
c.and x12,x13       # c.and x12 x13
c.beqz x12,here       # c.beqz x12 here
c.bnez x12,here       # c.bnez x12 here
c.j here       # c.j here
c.lwsp x27,16(sp)       # c.lwsp x27 16
c.swsp x27,16(sp)       # c.swsp x27 16
c.mv x27,x28       # c.mv x27 x28
c.add x27,x28       # c.add x27 x28
c.fld f12,16(x13)       # c.fld f12 x13 16
c.fsd f12,16(x13)       # c.fsd f12 x13 16
c.fldsp f27,16(sp)       # c.fldsp f27 16
c.fsdsp f27,16(sp)       # c.fsdsp f27 16
c.jal here       # c.jal here
c.slli x27,16       # c.slli x27 16
c.srli x12,16       # c.srli x12 16
c.srai x12,16       # c.srai x12 16
c.flw f12,16(x13)       # c.flw f12 x13 16
c.fsw f12,16(x13)       # c.fsw f12 x13 16
c.flwsp f27,16(sp)       # c.flwsp f27 16
c.fswsp f27,16(sp)       # c.fswsp f27 16
