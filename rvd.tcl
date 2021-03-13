package require pipe

proc cmp-nbits { a b } {
    expr { [nbits $a] - [nbits $b] }
}

proc disassemble_init { args } {
    dict for {op opcode} $::opcode {                            ; # 2 level lookup table  mask --> bits --> opcode
        dict with opcode {
            if { ($bits & 0x00003) == 0x0003 } {
                dict lappend ::decode4 $mask $bits $opcode
            } else {
                if { [iset c] } {
                    dict lappend ::decode2 $mask $bits $opcode
                }
            }
        }
    }
    set ::decode4 [lsort -decreasing -integer -stride 2 -index 0  -command cmp-nbits $::decode4]
    if { [iset c] } {
        set ::decode2 [lsort -decreasing -integer -stride 2 -index 0 -command cmp-nbits $::decode2]
    }
}

proc disassemble_op { word } {
    if { ($op & 0x00003) == 0x0003 } {
        disassemble_decode $op $::decode4
    } else {
        if { ![iset c] } {
            error "compact instructions not enabled : $op"
        } 
        disassemble_decode $op $::decode2
    }
}
proc disassemble_op4 { op } {
    disassemble_decode $op $::decode4
}
proc disassemble_op2 { op } {
    if { ![iset c] } {
        error "compact instructions not enabled : $op"
    } 
    disassemble_decode $op $::decode2
}
proc disassemble_decode { word decode } {
    set word [format 0x%08x $word]

    dict for {mask opcodes} $decode {                     ; # foreach major opcode mask
        set bits [format 0x%08X [expr { $word & $mask }]]   ; # compute the significant bits in the op

        if { [dict exists $opcodes $bits] } {
            set disa [eval [dict get $opcodes $bits disa]]
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
    }
    return  "unknown instruction $word"
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
            set disa [disassemble_op4 [format 0x%08x $word]]
            set dargs [lassign $disa dop]
            print [format %08x $addr] [format %08x $word] "        " [format %-10s $dop] $dargs 
            incr addr 4
        } else {

            set data [lassign $data b1]
            set word [expr { $b1 << 8 | $byte }]
            set disa [disassemble_op2 [format 0x%08x $word]]
            set dargs [lassign $disa dop]
            print [format %08x $addr] [format "%04x    " $word] "        " [format %-10s $dop] $dargs 
            incr addr 2
        }
        set data [lassign $data byte]
    }
}

proc disassemble { args } {

    set file [lindex $args 0]

    set e [elf::elf create e $file]


    disa_section $e .plt
    disa_section $e .text
}
