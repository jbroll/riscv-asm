package require jbr::with
package require jbr::term
package require jbr::stack

source $root/cexpr2tcl.tcl

set ::mem [lrepeat 65192 0]

namespace eval ::tcl::mathfunc {
    proc ldb { addr } {
        if { $addr < 0 || $addr >= [llength $::mem] } {
            error "segv : $addr"
        }
        set value [lindex $::mem $addr]
        #print ldb $addr $value
        return $value
    }

    proc ld_sbyte { addr } { expr { signed(ldb($addr), 8) } }
    proc ld_shalf { addr } { expr { signed(ldb($addr) + (ldb($addr+1) << 8), 16) } }
    proc ld_sword { addr } { expr { signed(ldb($addr) + (ldb($addr+1) << 8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24), 32) } }
    proc ld_sdble { addr } { expr { signed(
        (ldb($addr  )      ) + (ldb($addr+1) <<  8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24) +
        (ldb($addr+4) << 32) + (ldb($addr+5) << 40)  + (ldb($addr+6) << 48) + (ldb($addr+7) << 56), 64) } }
    proc ld_ubyte { addr } { expr { ldb($addr) & 0xFF } }
    proc ld_uhalf { addr } { expr { (ldb($addr) + (ldb($addr+1) << 8)) & 0xFFFF } }
    proc ld_uword { addr } { expr { (ldb($addr) + (ldb($addr+1) << 8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24)) & 0xFFFFFFFF } }

    proc stb { value addr } {
        if { $addr < 0 || $addr >= [llength $::mem] } {
            error "segv : $addr"
        }
        set value [expr { $value & 0xFF }]
        #print stb $addr $value
        lset ::mem $addr $value
    }
    proc st_byte { value addr } { expr { stb($value, $addr) } }
    proc st_half { value addr } { expr { stb($value, $addr) }
                                  expr { stb($value >> 8, $addr+1) } }
    proc st_word { value addr } { expr { stb($value,       $addr)   }
                                  expr { stb($value >>  8, $addr+1) }
                                  expr { stb($value >> 16, $addr+2) }
                                  expr { stb($value >> 24, $addr+3) }
                                } 
    proc st_dble { value addr } { expr { stb($value,       $addr)   }
                                  expr { stb($value >>  8, $addr+1) }
                                  expr { stb($value >> 16, $addr+2) }
                                  expr { stb($value >> 24, $addr+3) }
                                  expr { stb($value >> 32, $addr+4) }
                                  expr { stb($value >> 40, $addr+5) }
                                  expr { stb($value >> 48, $addr+6) }
                                  expr { stb($value >> 56, $addr+7) }
                                } 

    proc unsigned { value { from 31 } } {
        expr { $value & msk2($from, 0) }
    }

    namespace export ld_uword
}
namespace import ::tcl::mathfunc::ld_uword

proc execut_init {} {
    set ::reg-regexp \\m([join $::rclasses |])\\M
    set ::imm-regexp \\m([join $::iclasses |])\\M
    set ::enu-regexp \\m([join $::eclasses |])\\M
    set ::csr-regexp \\m([join [dict keys $::rva::registers::csr] |])\\M
    set ::pcx-regexp \\m([join [list pc {*}$::regNames] |])\\M
    set ::var-regexp \\m(size|tmp|xlen)\\M

    upvar ::R R
    upvar ::C C
    set R(pc) 0
    foreach reg $::regNames {
        set R($reg) 0
    }
    foreach reg [dict keys $::rva::registers::csr] {
        set C($reg) 0
    }

    dict for {op opcode} $::opcode {
        dict with opcode {
            if { $mapp eq {} } {
                set Code $code
                set Pars $pars
            } else {
                set mop [lindex $mapp 0]                    ; # For compact opcodes that map to another instruction. 
                set Code [dict get $::opcode $mop code]
                set Pars [dict get $::opcode $mop pars]
            }

            if { $Code eq "" } {
                set Code [list "print \"        \" no code for this op : $op $pars"]
            }

            if { ![regexp {pc [+-]?= } $Code] } {
                set Code [list "[lindex $Code 0]; pc += $size"]
            }
            set Code [cexpr2tcl [join $Code]]
            set decode decode$size

            proc exec_${mask}_${bits} { word } [% {
                set size $size ; set xlen [xlen] ; upvar ::R R ; upvar ::C C
                set disa [[dict get %::$decode $mask $bits disa] %word]
                lassign %disa op $Pars
                $Code
            }]
            dict set ::opcode $op exec exec_${mask}_${bits}
        }
    }
}

proc elf_load_file { file } {

    set e [elf::elf create e $file]

    set text ""
    table foreachrow [pipe { $e get segments | table sort ~ p_paddr -integer }] {
        set p_paddr [expr { $p_paddr & 0xFFFFF }]
        if { $p_type eq "PT_LOAD" } {
            set here [string length $text]
            if { $p_paddr != 0 } {
                append text [binary format @[expr { $p_paddr - $here -1 }]c 0]
            }
            append text [$e getSegmentDataByIndex $p_index]
        }
    }
    set syms [load_syms $e]

    return [list $text $syms]
}

proc load { fname } {

    switch [file extension $fname] {
        .lst { 
            set formats { 4 s 8 i }
            with file = [open $fname r] {
                gets $file
                set lines [read $file]
            }

            set data ""
            foreach line [split $lines \n] {
                set op [lindex $line 2]
                if { $op eq "" } { continue }
                append data [binary format [dict get $formats [string length $op]] 0x$op]
            }
            return [list $data {}]
        }
        .bin {
            with file = [open $fname r] { set text [read $file] }
            return [list $text {}]
        }
        .elf -
        default {
            return [elf_load_file $fname]
        }
    }
}

proc format-regs { regs format } {
    lsort [lmap { name value } $regs { format "% 4s: $format" $name $value }]
}

proc write_state { file state } {
    with f = [open $file w] {
        puts $f $state
    }
}

proc read_state { file array } {
    upvar $array R
    with f = [open $file] {
        array set R [read $f]
    }
}


proc execute { verbose args } {
    set file [lindex $args 0]
    lassign [load $file] text syms

    binary scan $text cu* bytes 
    set i 0
    foreach byte $bytes {
        lset ::mem $i $byte
        incr i
    }

    set ::R(pc) 0
    set next 0
    set prev [clock micro]
    set expr ""
    set eval ""
    if { [xlen] == 32 } {
        set hex_format "         %08x"
        set dec_format " % 16d"
    } else {
        set hex_format " %016x"
        set dec_format " % 16d"
    }
    set format $dec_format

    lpush rstack [array get ::R *]
    set prevcmd "n"

    upvar ::R R
    upvar ::C C

    while { $R(pc) < [string length $text] && $R(pc) >= 0 } {
        set word [ld_uword $R(pc)]

        set cycle [expr [clock micro] - $prev]
        set prev [clock micro]
        if { $verbose } {  
            term clear

            set pc $R(pc)
            set disa [disa_block $pc $pc [expr $pc + 16*4] $syms $text]
            lappend disa {} {} {} {} {} 

            set dargs [lassign [decode_op disa [0x $word]] dop]
            lappend disa {*}[split [dict get $::opcode $dop code] \n]
            set code [dict get $::opcode $dop exec]
            lappend disa {*}[split  "$code {} [info body $code]" \n] 

            foreach b [format-regs [array get R *] $format] c $disa {
                if { [string index $c 0] == "0" && "0x0[lindex $c 0]" == $pc } {
                    print $b "     --> " $c
                } else {
                    print $b "         " $c
                }
            }

            set next [expr [clock milliseconds] + 100]
            print $expr = $eval
            puts -nonewline " : " ; flush stdout

            gets stdin in
            if { $in eq "" } { set in $prevcmd }
            set prevcmd $in

            switch -- [lindex $in 0] {
                w { write_state .state [array get R *] ; continue }
                r { read_state  .state R               ; continue }
                d { set format $dec_format             ; continue}
                x { set format $hex_format             ; continue}
                q { write_state .state [array get R *] ; exit }
                n { }
                m { set expr $in
                    set eval [lrange $::mem {*}[lrange $in 1 end]] 
                    continue
                }
                p { array set R [lpop rstack]          ; continue }
                default {
                    try {
                        set eval [eval $in]
                    } on error e { }

                    #set expr $in
                    #set eval [expr [cexpr2tcl $in]]
                    continue
                }
            }

            lpush rstack [array get R *]
        }

        decode_op exec $word
        set R(x0) 0
    }

    error "execution loop falls through : $R(pc)"
}
