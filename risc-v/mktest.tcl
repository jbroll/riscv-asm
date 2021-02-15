#!/usr/bin/env tclkit8.6
#
source $::env(HOME)/src/jbr.tcl/func.tcl
source $::env(HOME)/src/jbr.tcl/list.tcl

proc  print { args } { puts [join $args " "] }
proc eprint { args } { puts stderr $args }

proc iset { i } {
    return 0
}
proc reg-names { names } {
    set n [expr { [iset e] ? 31 : 63 }]

    lrange [zip $names [iota 0 31]] 0 $n
}

proc register { name bits args } {
    set ::$name [dict keys [lindex $args 0]]
    lappend ::rclasses $name
}
proc immediate { name bits } {
    lappend ::iclasses $name
}
proc flag { name bits message args } {
}
proc enum { name bits message args } {

}

proc rand { n } {
    expr { int(rand()*$n) % $n }
}
proc alias { args } {}


proc arg1 { ll } { lindex $ll 0 }
proc arg2 { ll } { lindex $ll 1 }
proc arg3 { ll } { lindex $ll 2 }

proc pickreg { $arg } { lindex [set ::$arg] [rand 20] }

proc opcode { op args } {
    lsplit $args args mapp

    set ll {}
    set n 0

    set n 2
    foreach arg $args {
        incr n
        if { $arg == "aqrl" } {
            #lappend ll x
        }
        if { $arg == "rm" } {
            lappend ll dyn
            continue
        }
        if { $arg in $::rclasses } {
            set regs [set ::$arg]
            set off [expr { [llength $regs] - 8 + $n }]
            lappend ll [lindex $regs $off]
            continue
        }
        if { $arg in $::iclasses } {
            switch $op {
                beq - bne - blt - bge - bltu - bgeu - jal - c.beqz - c.bnez - c.jal - c.j {
                    lappend ll here
                }
                default { lappend ll 16 }
            }
            continue
        }
    }

    set instr "$op [join $ll]"
    switch -glob $op {
      amo* {
          lset ll 2 "([lindex $ll 2])"
      }
      lw - lh - lhu - lb - lbu - sw - sh - sb - fsw - flw - fld - fsd - flq - fsq - c.lw - c.sw - c.flw - c.fsw - c.fld - c.fsd - c.ld - c.sd {
          set ll [lreplace $ll 1 2 [arg3 $ll]([arg2 $ll])]
      }
      c.addi16sp  {
          set ll "sp 16"
      }
      c.addi4spn {
          set ll "[lindex $ll 0] sp 16"
      }
      c.lwsp - c.swsp - c.ldsp - c.sdsp - c.flwsp - c.fswsp - c.fldsp - c.fsdsp {
          set ll [list [lindex $ll 0] 16(sp)]
      }
      lr.w - sc.w - lr.d - sc.d {
          lset ll end "([lindex $ll end])"
      }
    }
    puts "$op [join $ll ","]       # $instr"
}

proc main { org args } {
    set org $org

    puts ".text"
    puts ".org $org"
    puts ".global here"
    puts "here:"

    foreach file $args {
        uplevel source $file
    }
}

source ./registers.tcl

main {*}$argv
