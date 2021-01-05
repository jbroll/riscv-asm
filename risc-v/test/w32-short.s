.text
.org 0x0000
.global here
here:
beq x27,x28,here       # beq x27 x28 here
bne x27,x28,here       # bne x27 x28 here
blt x27,x28,here       # blt x27 x28 here
bge x27,x28,here       # bge x27 x28 here
bltu x27,x28,here       # bltu x27 x28 here
bgeu x27,x28,here       # bgeu x27 x28 here
jalr x27,x28,16       # jalr x27 x28 16
jal x27,here       # jal x27 here
lui x27,16       # lui x27 16
auipc x27,16       # auipc x27 16
nop        # nop 
addi x27,x28,16       # addi x27 x28 16
slli x27,x28,16       # slli x27 x28 16
slti x27,x28,16       # slti x27 x28 16
sltiu x27,x28,16       # sltiu x27 x28 16
xori x27,x28,16       # xori x27 x28 16
ori x27,x28,16       # ori x27 x28 16
andi x27,x28,16       # andi x27 x28 16
srli x27,x28,16       # srli x27 x28 16
srai x27,x28,16       # srai x27 x28 16
add x27,x28,x29       # add x27 x28 x29
sub x27,x28,x29       # sub x27 x28 x29
sll x27,x28,x29       # sll x27 x28 x29
slt x27,x28,x29       # slt x27 x28 x29
sltu x27,x28,x29       # sltu x27 x28 x29
xor x27,x28,x29       # xor x27 x28 x29
srl x27,x28,x29       # srl x27 x28 x29
sra x27,x28,x29       # sra x27 x28 x29
or x27,x28,x29       # or x27 x28 x29
and x27,x28,x29       # and x27 x28 x29
lb x27,16(x28)       # lb x27 x28 16
lh x27,16(x28)       # lh x27 x28 16
lw x27,16(x28)       # lw x27 x28 16
lbu x27,16(x28)       # lbu x27 x28 16
lhu x27,16(x28)       # lhu x27 x28 16
sb x27,16(x28)       # sb x27 x28 16
sh x27,16(x28)       # sh x27 x28 16
sw x27,16(x28)       # sw x27 x28 16
fence        # fence 
fence.tso        # fence.tso 
ecall        # ecall 
ebreak        # ebreak 
uret        # uret 
sret        # sret 
mret        # mret 
dret        # dret 
sfence.vma x28,x29       # sfence.vma x28 x29
wfi        # wfi 
mul x27,x28,x29       # mul x27 x28 x29
mulh x27,x28,x29       # mulh x27 x28 x29
mulhsu x27,x28,x29       # mulhsu x27 x28 x29
mulhu x27,x28,x29       # mulhu x27 x28 x29
div x27,x28,x29       # div x27 x28 x29
divu x27,x28,x29       # divu x27 x28 x29
rem x27,x28,x29       # rem x27 x28 x29
remu x27,x28,x29       # remu x27 x28 x29
amoadd.w x27,x28,(x29)       # amoadd.w x27 x28 x29
amoxor.w x27,x28,(x29)       # amoxor.w x27 x28 x29
amoor.w x27,x28,(x29)       # amoor.w x27 x28 x29
amoand.w x27,x28,(x29)       # amoand.w x27 x28 x29
amomin.w x27,x28,(x29)       # amomin.w x27 x28 x29
amomax.w x27,x28,(x29)       # amomax.w x27 x28 x29
amominu.w x27,x28,(x29)       # amominu.w x27 x28 x29
amomaxu.w x27,x28,(x29)       # amomaxu.w x27 x28 x29
amoswap.w x27,x28,(x29)       # amoswap.w x27 x28 x29
lr.w x27,(x28)       # lr.w x27 x28
sc.w x27,x28,(x29)       # sc.w x27 x28 x29
fadd.s f27,f28,f29,dyn       # fadd.s f27 f28 f29 dyn
fsub.s f27,f28,f29,dyn       # fsub.s f27 f28 f29 dyn
fmul.s f27,f28,f29,dyn       # fmul.s f27 f28 f29 dyn
fdiv.s f27,f28,f29,dyn       # fdiv.s f27 f28 f29 dyn
fsgnj.s f27,f28,f29       # fsgnj.s f27 f28 f29
fsgnjn.s f27,f28,f29       # fsgnjn.s f27 f28 f29
fsgnjx.s f27,f28,f29       # fsgnjx.s f27 f28 f29
fmin.s f27,f28,f29       # fmin.s f27 f28 f29
fmax.s f27,f28,f29       # fmax.s f27 f28 f29
fsqrt.s f27,f28,dyn       # fsqrt.s f27 f28 dyn
fle.s x27,f28,f29       # fle.s x27 f28 f29
flt.s x27,f28,f29       # flt.s x27 f28 f29
feq.s x27,f28,f29       # feq.s x27 f28 f29
fcvt.w.s x27,f28,dyn       # fcvt.w.s x27 f28 dyn
fcvt.wu.s x27,f28,dyn       # fcvt.wu.s x27 f28 dyn
fclass.s x27,f28       # fclass.s x27 f28
fcvt.s.w f27,x28,dyn       # fcvt.s.w f27 x28 dyn
fcvt.s.wu f27,x28,dyn       # fcvt.s.wu f27 x28 dyn
fmv.x.w x27,f28       # fmv.x.w x27 f28
fmv.w.x f27,x28       # fmv.w.x f27 x28
flw f27,16(x28)       # flw f27 x28 16
fsw f27,16(x28)       # fsw f27 x28 16
fmadd.s f27,f28,f29,f30,dyn       # fmadd.s f27 f28 f29 f30 dyn
fmsub.s f27,f28,f29,f30,dyn       # fmsub.s f27 f28 f29 f30 dyn
fnmsub.s f27,f28,f29,f30,dyn       # fnmsub.s f27 f28 f29 f30 dyn
fnmadd.s f27,f28,f29,f30,dyn       # fnmadd.s f27 f28 f29 f30 dyn
fadd.d f27,f28,f29,dyn       # fadd.d f27 f28 f29 dyn
fsub.d f27,f28,f29,dyn       # fsub.d f27 f28 f29 dyn
fmul.d f27,f28,f29,dyn       # fmul.d f27 f28 f29 dyn
fdiv.d f27,f28,f29,dyn       # fdiv.d f27 f28 f29 dyn
fsgnj.d f27,f28,f29       # fsgnj.d f27 f28 f29
fsgnjn.d f27,f28,f29       # fsgnjn.d f27 f28 f29
fsgnjx.d f27,f28,f29       # fsgnjx.d f27 f28 f29
fmin.d f27,f28,f29       # fmin.d f27 f28 f29
fmax.d f27,f28,f29       # fmax.d f27 f28 f29
fsqrt.d f27,f28,dyn       # fsqrt.d f27 f28 dyn
fle.d x27,f28,f29       # fle.d x27 f28 f29
flt.d x27,f28,f29       # flt.d x27 f28 f29
feq.d x27,f28,f29       # feq.d x27 f28 f29
fcvt.s.d f27,f28,dyn       # fcvt.s.d f27 f28 dyn
fcvt.d.s f27,f28       # fcvt.d.s f27 f28
fcvt.w.d x27,f28,dyn       # fcvt.w.d x27 f28 dyn
fcvt.wu.d x27,f28,dyn       # fcvt.wu.d x27 f28 dyn
fclass.d x27,f28       # fclass.d x27 f28
fcvt.d.w f27,x28       # fcvt.d.w f27 x28
fcvt.d.wu f27,x28       # fcvt.d.wu f27 x28
fld f27,16(x28)       # fld f27 x28 16
fsd f27,16(x28)       # fsd f27 x28 16
fmadd.d f27,f28,f29,f30,dyn       # fmadd.d f27 f28 f29 f30 dyn
fmsub.d f27,f28,f29,f30,dyn       # fmsub.d f27 f28 f29 f30 dyn
fnmsub.d f27,f28,f29,f30,dyn       # fnmsub.d f27 f28 f29 f30 dyn
fnmadd.d f27,f28,f29,f30,dyn       # fnmadd.d f27 f28 f29 f30 dyn
fence.i        # fence.i 
