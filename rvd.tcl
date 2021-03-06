package require pipe

proc disassemble_init { args } {
    dict for {op opcode} $::opcode {                            ; # 2 level lookup table  mask --> bits --> opcode
        dict with opcode {
            if { ($bits & 0x00003) == 0x0003 } {
                dict lappend ::decode4 $mask $bits $opcode
            } else {
                dict lappend ::decode2 $mask $bits $opcode
            }
        }
    }
    set ::decode4 [lsort -decreasing -integer -stride 2 -index 0 $::decode4]
    set ::decode2 [lsort -decreasing -integer -stride 2 -index 0 $::decode2]
}

proc disassemble_op { word } {
    if { ($op & 0x00003) == 0x0003 } {
        disassemble_decode $op $::decode4
    } else {
        disassemble_decode $op $::decode2
    }
}
proc disassemble_op4 { op } {
    disassemble_decode $op $::decode4
}
proc disassemble_op2 { op } {
    disassemble_decode $op $::decode2
}
proc disassemble_decode { word decode } {
    set word [format 0x%08x $word]

    dict for {mask opcodes} $decode {                     ; # foreach major opcode mask
        set bits [format 0x%08X [expr { $word & $mask }]]   ; # compute the significant bits in the op

        if { [dict exists $opcodes $bits] } {
            return [eval [dict get $opcodes $bits disa]]
        }
    }
    return  "unknown instruction $op"
}
proc disassemble { args } {

    set file [lindex $args 0]

    set e [elf::elf create e $file]
    set head [$e getSectionHeaderByName .text]
    set syms [pipe { $e get .symtab | 
                     table row ~ { $st_name != "" && $st_shnm == ".text" } |
                     table col ~ st_name st_value |
                     table todict |
                     lreverse ~
    }]
    set data [$e getSectionDataByName .text]
    set addr [dict get $head sh_addr]
    binary scan $data cu* data
    #set data [map d $data { format %02x $d }]

    print $syms
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
            print [format %08x $addr] [format %08x $word] [disassemble_op4 [format 0x%08x $word]] 
            incr addr 4
        } else {
            set data [lassign $data b1]
            set word [expr { $b1 << 8 | $byte }]
            print [format %08x $addr] [format "%04x    "  $word] [disassemble_op2 [format 0x%08x $word]]
            incr addr 2
        }
        set data [lassign $data byte]
    }
}
