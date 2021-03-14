package require pipe

proc disassembler { op pars mask bits mapp } {
    # generate the disassembler for this opcode
    #
    set body [join [list list $op {*}[lmap p $pars { I "\[dis_${p} \$word]" }]] " "]

    if { $mapp ne {} } {                                                            ; # Build a short op map?
        set mvals [lassign $mapp mop]                                               ; # Split mop and mvals

        if { $::disassemble ne "compact" } {
            # generate a disassembler that maps to the mopp code.
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
    if { ($op & 0x00003) == 0x0003 } {
        unalias {*}[decode disa $op $::decode4]
    } else {
        if { ![iset c] } {
            error "compact instructions not enabled : $op"
        } 
        unalias {*}[decode disa $op $::decode2]
    }
}
proc unalias { args } {
    set disa $args
    set dop [lindex $disa 0]
    while { [dict exists $::alias $dop] } {
        set dxx [dict get $::alias $dop]
        foreach fr [dict get $dxx fr] to [dict get $dxx to] match [dict get $dxx match] {
            lassign $disa {*}$to
            if $match {
                set disa [eval list {*}$fr]
            }
        }
        if { $dop eq [lindex $disa 0] } { break }
        set dop [lindex $disa 0]
    }
    return $disa
}

proc disa_section { elf section } {
    set syms [pipe { $elf get .symtab | 
                     table row ~ section section { $st_name != "" && $st_shnm == $section } |
                     table col ~ st_name st_value |
                     table todict |
                     lreverse ~
    }]
    set dsym [pipe { $elf get .dynsym |
                     table col ~ st_name st_value |
                     table todict |
                     lreverse ~
    }]
    lappend syms {*}$dsym

    set head [$elf getSectionHeaderByName $section]
    set addr [dict get $head sh_addr]
    set data [$elf getSectionDataByName $section]
    binary scan $data cu* data
    set data [lassign $data byte]
    while { [llength $data] } {
        set symbol ""
        if { [dict exists $syms $addr] } {
            print
            print "        " [dict get $syms $addr] :
        }
        if { ($byte & 0x03) == 0x03 } {
            set data [lassign $data b1 b2 b3]
            set word [expr { $b3 << 24 | $b2 << 16 | $b1 << 8 | $byte }]
            set disa [decode_op4 disa [0x $word]]
            set dargs [lassign $disa dop]
            set wide 8
            set skip 4
            set size 4
        } else {

            set data [lassign $data b1]
            set word [expr { $b1 << 8 | $byte }]
            set disa [decode_op2 disa [0x $word]]
            set dargs [lassign $disa dop]
            set wide 4
            set skip 8
            set size 2
        }

        print [format "%04x %0-*x %*s     %-8s" $addr $wide $word $skip "" $dop] $dargs 

        incr addr $size
        set data [lassign $data byte]
    }
}

proc disassemble { args } {

    set file [lindex $args 0]

    set e [elf::elf create e $file]

    disa_section $e .plt
    disa_section $e .text
}
