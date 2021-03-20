package require jbr::with
package require jbr::term
package require jbr::stack

source $root/cexpr2tcl.tcl

namespace eval ::tcl::mathfunc {
    proc ld_sbyte { addr } { return 0 }
    proc ld_shalf { addr } { return 0 }
    proc ld_sword { addr } { return 0 }
    proc ld_ubyte { addr } { return 0 }
    proc ld_uhalf { addr } { return 0 }

    proc st_byte { value addr } { return 0 }
    proc st_half { value addr } { return 0 }
    proc st_word { value addr } { return 0 }

    proc unsigned { value { from 31 } } {
        expr { $value & msk2($from, 0) }
    }
}

proc execut_init {} {
    set ::reg-regexp \\m([join $::rclasses |])\\M
    set ::imm-regexp \\m([join $::iclasses |])\\M
    set ::enu-regexp \\m([join $::eclasses |])\\M
    set ::csr-regexp \\m([join [dict keys $::rva::registers::csr] |])\\M
    set ::pcx-regexp \\m([join [list pc {*}$::regNames] |])\\M
    set ::var-regexp \\m(size|tmp)\\M

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
                set size $size ; upvar ::R R ; upvar ::C C
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
        .bin {}
        .elf -
        default {
            return [elf_load_file $fname]
        }
    }
}

proc format-regs { regs } {
    lsort [lmap { name value } $regs { format "% 4s: % 10s" $name $value }]
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

    set ::R(pc) 0
    set next 0
    set prev [clock micro]
    set expr ""
    set eval ""

    lpush rstack [array get ::R *]
    set prevcmd "n"

    upvar ::R R
    upvar ::C C

    while { $R(pc) < [string length $text] && $R(pc) >= 0 } {
        binary scan $text @${::R(pc)}i word

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

            foreach b [format-regs [array get R *]] c $disa {
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

            switch -- $in {
                w { write_state .state [array get R *] ; continue }
                r { read_state  .state R               ; continue }
                q { exit }
                n { }
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
        }

        #print $word [decode_op disa [0x $word]]

        lpush rstack [array get R *]
        decode_op exec $word
        #print $word end
        set R(x0) 0

    }

    error "execution loop falls through : $::R(pc)"
}
