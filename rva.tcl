#!/usr/bin/env tclkit8.6
#
set root [file dirname [file normalize [info script]]]

package require jbr::assert
package require jbr::dict
package require jbr::func
package require jbr::list
package require jbr::print
package require jbr::shim
package require jbr::unix
package require jbr::stack
package require jbr::string
package require jbr::template

source $root/elf/elf.tcl
source $root/compact.tcl
source $root/decode.tcl
source $root/rvd.tcl

namespace eval rva {}                   ; # Someday everything will live here
namespace eval rva::registers {}

set LABEL(.) 0

proc _enum { func name bits message args } {
    set registers [concat {*}$args]
    set ::rva::registers::$name $registers
    set ::rva::registers::${name}_rev [lreverse $registers]
    lassign [regsub -all {[=._]} $bits " "] fr to

    proc ::tcl::mathfunc::$name { value } [% { return [expr { ${func}(%value, %::rva::registers::$name, "$message") * exp2($to) }] }]

    set mask [msk2 $fr $to]
    proc dis_$name { value } [% {
        dict get %::rva::registers::${name}_rev [expr { ( %value & $mask ) >> $to }]
    }]
}
interp alias {} flag {} _enum flag

proc rva-enum { args } {
    _enum enum {*}$args
}

proc register { name bits reg api } {
    if { $::preferApi } {
        rva-enum $name $bits "expected register name found" $api $reg
    } else {
        rva-enum $name $bits "expected register name found" $reg $api
    }

    proc tcl::mathfunc::match_${name} { value } [% { expr { %value in [dict keys %::rva::registers::$name] } }]
}

proc immediate { name Bits width } {
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
        set mask [0x [expr { msk2($hi-1, $lo) }]]
        set shift [expr { $pos - $lo }]
        set sop [expr { $shift < 0 ? ">>" : "<<" }]
        set dop [expr { $shift > 0 ? ">>" : "<<" }]
        lappend expr "((\$value & $mask) $sop [expr { abs($shift) }])"
        lappend disa "((\$value $dop [expr { abs($shift) }]) & $mask)"
        set lo $hi
    }
    set expr [join $expr |]
    set disa [join $disa |]

    # Create a function that computes the bits of an immediate.
    # 
    proc ::tcl::mathfunc::$name { value } [% {
        set value [::tcl::mathfunc::label %value]
        return [expr { $expr }]
    }]

    if { $width == "unsigned" } {
        proc dis_$name { value } [% {
            expr { $disa }
        }]
    } else {
        proc dis_$name { value } [% {
            expr { signed($disa, $width) }
        }]
    }

    assert-eq [% { ::tcl::mathfunc::$name 0xffffffff }]  \
              [% { ::tcl::mathfunc::$name [dis_$name [::tcl::mathfunc::$name 0xffffffff]] }] "\n\t$expr\n\t$disa"

    # Create a function that checks the validity of an immediate.
    # TODO: Check sign/unsigned value and use abs().
    set size [exp2 $hi]
    proc tcl::mathfunc::match_$name v [% { expr { label(%v) < $size } }]
}

proc nbits { word } {
    expr [join [split [format %b $word] {}] +]
}

namespace eval ::tcl::mathfunc {
    proc label { value } {
        if { [info exists ::LABEL($value)] } {
            return [expr { $::LABEL($value) - $::LABEL(.) }]
        }
        return $value
    }

    proc msk2 { hi lo } { 0x [expr { 0xffffffff & ((exp2($hi+1) - 1) ^ (exp2($lo) - 1)) }] }
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
        expr { msk2($n1 eq "" ? $n2 : $n1, $n2) }
    }

    proc match_x0   rd { expr { $rd eq "x0" || $rd eq "zero" } }
    proc match_zero rd { expr { $rd eq "x0" || $rd eq "zero" } }
    proc match_x1   rd { expr { $rd eq "x1" || $rd eq "ra"   } }
    proc match_ra   rd { expr { $rd eq "x1" || $rd eq "ra"   } }
    proc match_x2   rd { expr { $rd eq "x2" || $rd eq "sp"   } }
    proc match_sp   rd { expr { $rd eq "x2" || $rd eq "sp"   } }
    proc match_0    vx { expr { $vx ==   0 } }

    proc signed { value bits } {
        expr { $value - (($value & exp2($bits-1)) == 0 ? 0 : exp2($bits)) }
    }

    namespace export msk2 exp2
}
namespace import ::tcl::mathfunc::msk2
namespace import ::tcl::mathfunc::exp2

proc prefer { reg } {
    if { $::preferApi } {
        return [dict get@ $::reg2api $reg $reg]
    }

    return [dict get@ $::api2reg $reg $reg]
}

# Add an alias for the op, allowing defaults in at any arg position
#
proc alias { op args } {
    lsplit $args fr to ->
    set to [lassign $to top]
    set tt [concat {*}[lmap arg $to { expr { $arg in $fr ? "\$$arg" : [prefer "$arg"] } }]]

    if { [info procs $op] ne "" } {
        set fr_count [llength $fr]
        shim $op { args } [% {
            if { [llength %args] == $fr_count } {
                lassign %args $fr
                tailcall $top $tt
            }
            shim:next $op {*}%args
        }]
    } else {
        proc $op {*}[list $fr] "$top $tt"
    }

    set match_to [list "( \$$top eq \"$top\" )"]
    lappend match_to {*}[lmap arg $to { 
        if { $arg in $fr } { continue } 
        I "match_${arg}(\$$arg)" 
    }]
    set match_to [join $match_to " && "]
    set ff [concat {*}[lmap arg $fr { I "\$$arg" }]]

    dict lappend ::alias $top fr [list [list $op  {*}$ff]]
    dict lappend ::alias $top to [list [list $top {*}$to]]
    dict lappend ::alias $top match [list $match_to ]
}

proc dis_0  { word } { return  0 }
proc dis_x0 { word } { return x0 }
proc dis_x1 { word } { return x1 }
proc dis_x2 { word } { return x2 }

lappend ::optable { op mask bits pars vars }

proc 0x { value { width 8 } } { format 0x%0*X $width $value }

proc opcode { op args } {
    lsplit $args args mapp ->
    lsplit $args pars Bits :

    set bits [0x [fold { apply { { x y } { expr { $x | bits($y) } } } } 0 $Bits]]   ; # reduce bits with bits() function
    set mask [0x [fold { apply { { x y } { expr { $x | mask($y) } } } } 0 $Bits]]   ; # reduce bits with mask() function
    set vars [join [lmap p $pars { I \$$p }] " "]                                    ; # variable expansion for assemble comment
    set expr [join [list $bits {*}[lmap p $pars { I "${p}(\$$p)" }]] |]              ; # build bits expression
    foreach arg $pars {
        if { [info procs ::tcl::mathfunc::$arg] == "" } {
            eprint "missing argument type in op $op : $arg"
        }
    }

    if { [info proc $op] ne "" } {
        eprint redefine $op $args
        eprint existing op $op [dict get ::opcode $op]
    }
    proc .$op $pars "expr { $expr }"                                                ; # a proc to compute the opcode value
    proc  $op $pars "assemble \[.$op $vars] \"[concat $op {*}$vars]\""              ; # a proc to assmeble the opcode at .

    dict set ::opcode $op op   $op                                                  ; # save some info about op
    dict set ::opcode $op mask $mask
    dict set ::opcode $op bits $bits
    dict set ::opcode $op pars $pars
    dict set ::opcode $op vars $vars

    lappend ::optable [list $op $mask $bits $pars $vars]

    compact $op $pars $mapp
    disassembler $op $pars $mask $bits $mapp
}

proc assemble { opcode instr } {
    set line [dict get [info frame 3] line]

    if { ($opcode & 0x00000003) == 0x00000003 } { 
        print [format " %05d %04X %08X   %s"     $line $::LABEL(.) [expr { $opcode & 0xffffffff }] $instr]
        incr ::LABEL(.) 4
    } else {
        print [format " %05d %04X %04X       %s" $line $::LABEL(.) [expr { $opcode & 0x0000ffff }] $instr]
        incr ::LABEL(.) 2
    }
}

# Source a file with the script instlled directory prefix
#
proc include { file } {
    source $::root/$file
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

# Catch unknown commands in the .rva file and treat them as labels is they end in ':'
#
proc unknown { args } {
    switch -regex -- $args {
        {[0-9a-zA-Z_]+:} { : [string range $args 0 end-1] }
        default {
            error "unknown command : $args"
        }
    }   
}

# Introduce a label in the .rva file
#
proc : { name args } {
    set ::LABEL($name) $::LABEL(.)
    if { [llength $args] } {
        {*}$args
    }
}

# A convenience proc to check an instruction set request.
#
proc iset { iset } {
    expr { [dict exists $::iset $iset] && [dict get $::iset $iset] eq $iset }
}

# Convert a list of valid register names into a dict for reg -> value map.
#
proc reg-names { names } {
    zip $names [iota 0 [llength $names]-1]
}


proc main { args } {

    set March rv32IMAFDZicsr_Zifencei                           ; # The default march

    # A regex to extract the march definition and check the order (somewhat).
    #
    set match {^rv(32|64)(i|e)?(m)?(a)?(f)?(d)?(q)?(c)?((z[a-z]*)?(_(z[a-z]*))*)((_x[a-z]+)*)$}

    set files {}
    set ::preferApi no
    set   showtable no
    set ::disassemble no
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        switch $arg {
            -reg    { set ::preferApi no  }
            -api    { set ::preferApi yes }
            -t      { set showtable   yes }
            -dc     { set ::disassemble compact }
            -d      { set ::disassemble yes }
            -march  { set March [lindex $args [incr i]] }
            default { lappend files $arg }
        }
    }

    set march [string tolower $March]

    if { [string index $march 4] eq "g" } {
        set march [string replace $march 4 4 "imafd"]
        set x [string first _x $march]                          ; # _Z must come before _X.
        if { $x == -1 } {
            set x end
        }
        set march [string insert $march $x "_zicsr_zifencei"]
    }

    if { [regexp -- $match $march -> XLEN I M A F D Q C Z - - - X] <= 0 } {
        error "incorrect march string $March --> $march"
    }
    set ::iset [dict create rlen $XLEN i $I m $M a $A f $F d $D q $Q c $C]
    if { [dict get $::iset i] eq "e" } {        # ; The base arch is either I or E.
        dict set ::iset i i                     # ; E means I instructions w/ 16 registers
        dict set ::iset e e
    }
    foreach z [split $Z _] { dict set ::iset $z $z }
    foreach x [split $X _] { dict set ::iset $x $x }

    include registers.tcl                                   ; # Register definitions for standard extensions.

    include opcodes/opcodes-rv32i                           ; # Always include rv32i

    if { [iset m] } { include opcodes/opcodes-rv32m }
    if { [iset a] } { include opcodes/opcodes-rv32a }
    if { [iset h] } { include opcodes/opcodes-rv32h }
    if { [iset f] } { include opcodes/opcodes-rv32f }
    if { [iset d] } { include opcodes/opcodes-rv32d }
    if { [iset q] } { include opcodes/opcodes-rv32q }

    if { [iset c] } { include opcodes/opcodes-rvc }
    if { [dict get $::iset rlen] == 32 } {
        if { [iset c] }               { include opcodes/opcodes-rv32c }
        if { [iset c] && [iset f]   } { include opcodes/opcodes-rv32fc }
    }

    if { [iset f] && [iset zfh] } { include opcodes/opcodes-rv32f-zfh }
    if { [iset d] && [iset zfh] } { include opcodes/opcodes-rv32d-zfh }
    if { [iset q] && [iset zfh] } { include opcodes/opcodes-rv32q-zfh }

    if { [dict get $::iset rlen] == 64 } {
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

    foreach extn [dict keys $::iset x*] {
        include extension/opcodes-$extn
    }

    include macros.rva

    if { $::disassemble ne no } {
        decode_init
        disassemble {*}$files
        exit
    }
    if { $showtable } {
        print [table justify $::optable]
    }

    foreach file $files {
        if { $file eq "-" } {
            eval [read stdin]
        } else {
            source $file
        }
    }
}

main {*}$argv
