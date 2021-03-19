package require jbr::with
package require jbr::term

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
}

proc execut_init {} {
    set ::reg-regexp \\m([join $::rclasses |])\\M
    set ::imm-regexp \\m([join $::iclasses |])\\M
    set ::pcx-regexp \\m(pc)\\M

    upvar ::R R
    set R(pc) 0
    foreach reg $::regNames {
        set R($reg) 0
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

            set Code [cexpr2tcl [join $Code]]
            set decode decode$size

            proc exec_${mask}_${bits} { word } [% {
                upvar ::R R
                set disa [[dict get %::$decode $mask $bits disa] %word]
                lassign %disa op $Pars

                $Code
            }]
            dict set ::opcode $op exec exec_${mask}_${bits}
        }
    }
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
            return $data
        }
        .bin {}
        .elf -
        default {

        }
    }
}

proc execute { verbose args } {
    set file [lindex $args 0]
    set text [load $file]

    set ::R(pc) 0
    set next 0
    set prev [clock micro]

    while { $::R(pc) < [string length $text] && $::R(pc) >= 0 } {
        binary scan $text @${::R(pc)}i word

        if { ($word & 0x03) == 0x03 || ![iset c] } {
            set word [expr { $word & 0xFFFFFFFF }]
            decode_op4 exec [0x $word]
            incr ::R(pc) 4
        } else {
            set word [expr { $word & 0x0000FFFF }]
            decode_op2 exec [0x $word]
            incr ::R(pc) 2
        }

        set cycle [expr [clock micro] - $prev]
        set prev [clock micro]
        if { $verbose && $next < [clock milliseconds] } {  
            term clear
            puts -nonewline "cycle: [format %4s $cycle]"
            print [join [lsort [lmap { name value } [array get ::R *] { format "% 4s:  %s" $name $value }]] "\n"]
            set next [expr [clock milliseconds] + 100]
        }

    }
}
