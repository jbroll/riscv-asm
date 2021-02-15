#!/usr/bin/env tclkit8.6
#
source $::env(HOME)/src/jbr.tcl/func.tcl
source $::env(HOME)/src/jbr.tcl/list.tcl
source $::env(HOME)/src/jbr.tcl/shim.tcl
source $::env(HOME)/src/jbr.tcl/unix.tcl

namespace eval rva {}
namespace eval rva::registers {}

proc % { body } {
    string map { % $ } [uplevel subst -nocommands [list $body]] 
}

proc  print { args } { puts [join $args " "] }
proc eprint { args } { puts stderr $args }

set LABEL(.) 0

proc _enum { func name bits message args } {
    set ::rva::registers::$name [concat {*}$args]
    lassign [regsub -all {[=._]} $bits " "] fr to

    proc ::tcl::mathfunc::$name { value } [% { return [expr { ${func}(%value, %::rva::registers::$name, "$message") * exp2($to) }] }]
}
interp alias {} enum {} _enum enum
interp alias {} flag {} _enum flag

proc register { name bits args } {
    enum $name $bits "expected register name found" {*}$args

    proc tcl::mathfunc::match_${name} { value } [% { expr { %value in [dict keys %::rva::registers::$name] } }]
}

proc immediate { name Bits } {
    set bits [lreverse [split $Bits |]]
    set lo 0
    foreach bit $bits {
        switch -regex $bit {
            x+ {
                incr lo [string length $bit]
                continue
            }
            {[0-9]+\.\.[0-9]+} {
                lassign [regsub -all {[=._]} $bit " "] fr to

                set size [expr { $fr - $to + 1}]
                set pos $to
            }
            {[0-9]+} {
                set size 1
                set pos $bit
            }
        }
        set hi [expr { $lo + $size }]
        set mask [expr { msk2($hi, $lo) }]
        set shift [expr { $pos - $lo }]
        set sop [expr { $shift < 0 ? ">>" : "<<" }]
        lappend expr "((\$value & [expr { msk2($hi, $lo) }]) $sop [expr { abs($shift) }])"
        set lo $hi
    }
    set expr [join $expr |]

    proc ::tcl::mathfunc::$name { value } [% {
        if { [info exists ::LABEL(%value)] } {
            set value [expr { %::LABEL(%value) - %::LABEL(.) }]
        }
        return [expr { $expr }]
    }]

    set size [expr { exp2($hi) }]
    proc tcl::mathfunc::match_$name v [% { expr { %v < $size } }]
}

namespace eval ::tcl::mathfunc {
    proc msk2 { hi lo } { format 0x%08x [expr { 0xffffffff & ((exp2($hi) - 1) ^ (exp2($lo) - 1)) }] }
    proc exp2 { n } { return [expr { 1 << $n }] }

    proc enum { name names message } { 
        if { [dict exists $names $name] } {
            return [dict get $names $name]
        } else {
            error "$message : $name"
        }
    }

    proc flag { flag flags message } { 
        set value 0
        foreach f [split $flag ""] {
            if { [dict exists $flags $f] } {
                set value [expr { $value | [dict get $flags $f] }]
            } else {
                error "$message : $f not in $flags"
            }
        }
        return $value
    }

    proc bits { bits } {
        lassign [lreverse [regsub -all {[=._]} $bits " "]] b2 n2
        expr { $b2 << $n2 }
    }
    proc mask { bits } {
        lassign [lreverse [regsub -all {[=._]} $bits " "]] b2 n2 n1
        expr { msk2($n1 eq "" ? $n2 + 1 : $n1 + 1, $n2) }
    }

    proc match_x0 rd { expr { $rd eq "x0" } }
    proc match_x1 rd { expr { $rd eq "x1" } }
    proc match_x2 rd { expr { $rd eq "x2" } }
    proc match_0  vx { expr { $vx ==   0 } }
}

proc alias { op args } {
    rename $op _$op
    lsplit $args fr to
    set tt {}
    foreach arg $to {
        if { $arg in $fr } { lappend tt \$$arg
        } else {             lappend tt $arg
        }
    }
    proc $op { args } [subst {
        if { \[llength \$args] == [llength $fr] } {
            lassign \$args $fr
            tailcall [join _$tt]
        }
        if { \[llength \$args] == [llength [info args _$op]] } {
            tailcall _$op {*}\$args
        }
    }]
}

proc opcode { op args } {
    lsplit $args args mapp
    set bits [pick { apply { x { expr { [string first = $x] != -1 } } } } $args]    ; # Choose the bit def args : x..y=k
    set bits [fold { apply { { x y } { expr { $x | bits($y) } } } } 0 $bits]        ; # Reduce bits with bits() function
    set bits [format 0x%08x $bits]                                                  ; # Format as 0x0Hex
    set pars [pick { apply { x { expr { [string first = $x] == -1 } } } } $args]    ; # Choose the proper args
    set vars [join [map p $pars { I \$$p }] " "]                                    ; # variable expansion for assemble comment
    set expr [join [list $bits {*}[map p $pars { I "${p}(\$$p)" }]] |]              ; # build bits expression
    foreach arg $pars {
        if { [info procs ::tcl::mathfunc::$arg] == "" } {
            eprint "missing argument type in op $op : $arg"
        }
    }

    if { [info proc $op] ne "" } {
        eprint redefine $op $args
        eprint existing op $op [dict get ::opcode $op]
    }
    proc .$op $pars "expr { $expr }"                                                ; # A proc to compute the opcode value
    proc  $op $pars "assemble \[.$op $vars] \"[concat $op {*}$vars]\""              ; # A proc to assmeble the opcode at .

    dict set ::opcode $op bits $bits                                                ; # Save some info about op
    dict set ::opcode $op pars $pars
    dict set ::opcode $op vars $vars

    if { $mapp ne {} } {                                                            ; # Build a short op map?
        set mvals [lassign $mapp mop]
        set mpars [dict get $::opcode $mop pars]
        set mvars [dict get $::opcode $mop vars]
        set vvv   [join [map p [string map [zip $mvals $mpars] $pars] { I "\$$p" }] " "]

        if { [llength $mpars] } {
            set expr [join [map m $mpars p $mvals { concat match_${p}(\$$m) }] " && "]
            if { [lindex $mvals 0] == [lindex $mvals 1] } {
                append expr " && \$[lindex $mpars 0] eq \$[lindex $mpars 1]"
            }
        } else {
            set expr 1 
        }

        shim .$mop $mpars [% {
            if { $expr } {
                return [.$op $vvv]
            } 
            return [shim:next .$mop $mvars]
        }]
    }
}

proc assemble { opcode instr } {
    set line [dict get [info frame -2] line]

    if { ($opcode & 0x00000003) == 0x00000003 } { 
        print [format " %05d %04X %08X   %s"     $line $::LABEL(.) [expr { $opcode & 0xffffffff }] $instr]
        incr ::LABEL(.) 4
    } else {
        print [format " %05d %04X %04X       %s" $line $::LABEL(.) [expr { $opcode & 0x0000ffff }] $instr]
        incr ::LABEL(.) 2
    }
}

proc include { file } {
    source $file
}

proc macro { name args body } {
    foreach arg $args {
        set body [regsub -all "\\m$arg\\M" $body "\$$arg"]
    }
    proc $name $args $body
}

proc .org { org } { set ::LABEL(.) $org }
proc .global { args } {}
proc .text { args } {}

proc unknown { args } {
    switch -regex -- $args {
        {[0-9a-zA-Z_]+:} { : [string range $args 0 end-1] }
        default {
            error "unknown command : $args"
        }
    }   
}

proc : { name args } {
    set ::LABEL($name) $::LABEL(.)
    if { [llength $args] } {
        {*}$args
    }
}

proc iset { iset } {
    expr { [dict exists $::iset $iset] && [dict get $::iset $iset] eq $iset }
}

proc reg-names { names } {
    zip $names [iota 0 [llength $names]-1]
}


proc main { args } {

    set March rv32IMAFDZicsr_Zifencei
    set match {^rv(32|64)(i|e)?(m)?(a)?(f)?(d)?(q)?(c)?((z[a-y]*)?(_(z[a-y]*))*)$}

    set files {}
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        switch $arg {
            -march  { set March [lindex $args [incr i]] }
            default { lappend files $arg }
        }
    }

    set march [string tolower $March]

    if { [string index $march 4] eq "g" } {
        set march [string replace $march 4 4 "imafd"]
        append march _zicsr_zifencei
    }

    if { [regexp -- $match $march -> XLEN I M A F D Q C Z] <= 0 } {
        error "incorrect march string $March --> $march"
    }
    set ::iset [dict create xlen $XLEN i $I m $M a $A f $F d $D q $Q c $C]
    if { [dict get $::iset i] eq "e" } {
        dict set ::iset i i
        dict set ::iset e e
    }
    foreach i [split $Z _] { dict set ::iset $i $i }
    if { [iset e] } {
        dict set ::iset i i
    }

    source registers.tcl

    include opcodes/opcodes-rv32i                           ; # Always include rv32i

    if { [iset m] } { include opcodes/opcodes-rv32m }
    if { [iset a] } { include opcodes/opcodes-rv32a }
    if { [iset h] } { include opcodes/opcodes-rv32h }
    if { [iset f] } { include opcodes/opcodes-rv32f }
    if { [iset d] } { include opcodes/opcodes-rv32d }
    if { [iset q] } { include opcodes/opcodes-rv32q }

    if { [iset c] } { include opcodes/opcodes-rvc }
    if { [dict get $::iset xlen] == 32 } {
        if { [iset c] }               { include opcodes/opcodes-rv32c }
        if { [iset c] && [iset f]   } { include opcodes/opcodes-rv32fc }
    }

    if { [iset f] && [iset zfh] } { include opcodes/opcodes-rv32f-zfh }
    if { [iset d] && [iset zfh] } { include opcodes/opcodes-rv32d-zfh }
    if { [iset q] && [iset zfh] } { include opcodes/opcodes-rv32q-zfh }

    if { [dict get $::iset xlen] == 64 } {
        include opcodes/opcodes-rv64i                       ; # Always.

        if { [iset m] } { include opcodes/opcodes-rv64m }
        if { [iset a] } { include opcodes/opcodes-rv64a }
        if { [iset f] } { include opcodes/opcodes-rv64f }
        if { [iset d] } { include opcodes/opcodes-rv64d }
        if { [iset q] } { include opcodes/opcodes-rv64q }
        if { [iset c] } { include opcodes/opcodes-rv64c }

        if { [iset f] && [iset zfh] } { include opcodes/opcodes-rv64f-zfh }
    }
    if { [iset c] && [iset d]   } { include opcodes/opcodes-rvdc }


    if { [iset zicsr] }    { include opcodes/opcodes-zicsr      }
    if { [iset zifencei] } { include opcodes/opcodes-zifencei   }

    set zextn { zfh zicsr zifencei zfinx }                  ; # Standard Z extensions
    set uextn [dict keys [dict remove $::iset {*}$zextn] z*]

    foreach extn $uextn {
        include extension/opcodes-$extn
    }

    include macros.rva

    foreach file $files {
        if { $file eq "-" } {
            eval [read stdin]
        } else {
            include $file
        }
    }
}

main {*}$argv
