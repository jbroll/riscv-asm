package require pipe

proc disassembler { op mask bits mapp pars } {
 
    # Generate the disassembler for this opcode
    #
    set body [join [list list $op {*}[lmap p $pars { I "\[dis_${p} \$word]" }]] " "]

    if { $mapp ne {} } {                                                            ; # Build a short op map?
        set mvals [lassign $mapp mop]                                               ; # Split mop and mvals

        if { $::disassemble ne "compact" } {
            # generate a disassembler that maps to the rv32i code instead of
            # the compact mnumonic.
            #
            set body [join [list list $mop {*}[lmap p $mvals { I "\[dis_${p} \$word]" }]] " "]
        }
    } 

    if { [info procs dis_${mask}_${bits}] != "" } {
        error "duplicate opcode decodes: $op - $mask $bits"
    }
    proc disa_${mask}_${bits} { word } $body
    dict set ::opcode $op disa disa_${mask}_${bits}
}

proc disassemble_op { word } {
    if { ($op & 0x00003) == 0x0003 || ![iset c]} {
        unalias {*}[decode disa $op $::decode4]
    } else {
        unalias {*}[decode disa $op $::decode2]
    }
}

# Walk the alias table backwards dropping default args as we go
#
proc unalias { args } {
    set disa $args
    set dop [lindex $disa 0]
    while { [dict exists $::alias $dop] } {
        set aliases [dict get $::alias $dop]
        foreach alias $aliases {
            dict import alias
            lassign $disa {*}$pars

            if $match {
                set disa [eval list {*}$fr]
                if { $dop ne [lindex $disa 0] } {
                    break 
                }
            }
        }
        if { $dop eq [lindex $disa 0] } { break }
        set dop [lindex $disa 0]
    }
    return $disa
}

proc load_syms { elf } {
    set syms {}
    try {
        set syms [pipe { $elf get .symtab | 
                     table col ~ st_name st_value |
                     table todict |
                     lreverse ~
        }]
    } on error e { eprint $e}
    try {
        set dsym [pipe { $elf get .dynsym |
                         table col ~ st_name st_value |
                         table todict |
                         lreverse ~
        }]
        lappend syms {*}$dsym
    } on error e {}

    return $syms
}

proc disa_block { here addr leng syms data } {
    set lines {}

    while { $here < $leng } {
        if { $here + 2 >= $leng } {
            binary scan $data @${here}s word
        } else {
            binary scan $data @${here}i word
        }

        set symbol ""
        if { [dict exists $syms $addr] } {
            lappend lines {}
            lappend lines "        [dict get $syms $addr] :"
        }
        try {
            if { ($word & 0x03) == 0x03 || ![iset c] } {
                set word [expr { $word & 0xFFFFFFFF }]
                set wide 8
                set skip 4
                set size 4

                if { $::unalias } {
                    set disa [unalias {*}[decode_op4 disa [0x $word]]]
                } else {
                    set disa [decode_op4 disa [0x $word]]
                }
                set dargs [lassign $disa dop]
            } else {
                set word [expr { $word & 0x0000FFFF }]
                set wide 4
                set skip 8
                set size 2

                if { $::unalias } {
                    set disa [unalias {*}[decode_op2 disa [0x $word]]]
                } else {
                    set disa [decode_op2 disa [0x $word]]
                }
                set dargs [lassign $disa dop]
            }
        } on error {e info} {
            eprint "$e : [dict get $info -errorinfo]"
            set dop unknown
            set dargs {}
        }

        if { [dict exists $::LINES $addr] } {
            lassign [dict get $::LINES $addr] line instr
            set line [format %05d $line]
            set instr $instr
        } else {
            set line "     "
            set instr ""
        }
        lappend lines "[format "%s %04X %0-*X %*s     %-8s %-20s" $line $addr $wide $word $skip "" $dop $dargs] : $instr"
        incr addr $size
        incr here $size
    }

    return $lines
}

proc disassemble { args } {

    set file [lindex $args 0]
    set segments [lassign [load $file] syms]

    # TODO: Only load and disassebmle the segments that are executable.
    foreach { mode addr segment } $segments {
        if { $mode & 0x01 } {
            print [join [disa_block 0 $addr [string length $segment] $syms $segment] \n]
        }
        print
    }
}
