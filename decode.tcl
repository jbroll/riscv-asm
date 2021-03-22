
# Count the number of set bits in a word
#
proc nbits { word } {
    expr [join [split [format %b $word] {}] +]
}

# Compare the number of bits set in two words
#
proc cmp-nbits { a b } {
    expr { [nbits $a] - [nbits $b] }
}

proc decode_init { args } {
    
    # Create 2 and 4 byte opcode decode tables
    #
    dict for {op opcode} $::opcode {                            ; # 2 level lookup table  mask --> bits --> opcode
        dict with opcode {
            if { ($bits & 0x00003) == 0x0003 } {
                dict lappend ::decode4 $mask $bits $opcode
            } else {
                if { [iset c] } {
                    dict lappend ::decode2 $mask $bits $opcode
                } else {
                    error "2 byte opcode definition but compressed instrucitons are not enabled"
                }
            }
        }
    }

    # Sort the table in increasing order of selectivity (nbits set in op code mask)
    #
    set ::decode4 [lsort -decreasing -integer -stride 2 -index 0  -command cmp-nbits $::decode4]
    if { [iset c] } {
        set ::decode2 [lsort -decreasing -integer -stride 2 -index 0 -command cmp-nbits $::decode2]
    }
}

proc decode { type word decode } {
    set word [0x $word]

    dict for {mask opcodes} $decode {                           ; # foreach major opcode mask
        set bits [0x [expr { $word & $mask }]]                  ; # compute the significant bits in the op

        if { [dict exists $opcodes $bits] } {                   ; # Look up the op in the mask subtable
            return [[dict get $opcodes $bits $type] $word]
        }
    }
    return  unimp
}

proc decode_op { type word } {
    if { ($word & 0x03) == 0x03 || ![iset c] } {
        set word [expr { $word & 0xFFFFFFFF }]
        decode $type $word $::decode4
    } else {
        if { ![iset c] } {
            error "compact instructions not enabled : $word"
        } 
        set word [expr { $word & 0x0000FFFF }]
        decode $type $word $::decode2
    }
}

proc decode_op4 { type word } {
    unalias {*}[decode $type $word $::decode4]
}

proc decode_op2 { type word } {
    if { ![iset c] } {
        error "compact instructions not enabled : $word"
    } 
    unalias {*}[decode $type $word $::decode2]
}

