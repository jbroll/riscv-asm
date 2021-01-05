
proc  rd_decode(value) { return and(0x1f, value / exp2( 7)) }
proc rs1_decode(value) { return and(0x1f, value / exp2(15)) }
proc rs2_decode(value) { return and(0x1f, value / exp2(20)) }

proc imm12_decode(value) { return value * exp2(20) }
proc bimm12_decode(value) {
    return  or(     and(0x1000, value) * exp2(19),
            or(     and(0x0800, value) / exp2( 4),
            or(     and(0x07E0, value) * exp2(20), 
                    and(0x001E, value) * exp2( 7))))
}
proc simm12_decode(value) {
    return or(      and(0x0FE0, value) * exp2(20), 
                    and(0x001F, value) * exp2( 7))
}

proc imm20_decode(value) { return value * exp2(12) }
proc jimm20_decode(value) {
    return  or(     and(0x100000, value) * exp2(11),
            or(     and(0x0ff000, value) / exp2(0), 
            or(     and(0x000800, value) * exp2(9), 
                    and(0x0007fe, value) * exp2(20))))
}

procargs main { args } {
    foreach file $args {
        source $file
    }
}

