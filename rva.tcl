#!/usr/bin/env tclkit8.6
#
set root [file dirname [file normalize [info script]]]

package require jbr::dict
package require jbr::func
package require jbr::list
package require jbr::print
package require jbr::shim
package require jbr::unix
package require jbr::stack
package require jbr::string

source $root/elf/elf.tcl
source $root/rvd.tcl

namespace eval rva {}                   ; # Someday everything will live here
namespace eval rva::registers {}

proc % { body } {
    string map { % $ } [uplevel subst -nocommands [list $body]] 
}

proc assert-eq { a b msg } {
    set va [uplevel $a]
    set vb [uplevel $b]
    if { $va ne $vb } {
        error "failed assert $va != $vb : $a :: $b ::: $msg"
    }
}

set LABEL(.) 0

proc _enum { func name bits message args } {
    set ::rva::registers::$name [concat {*}$args]
    lassign [regsub -all {[=._]} $bits " "] fr to

    proc ::tcl::mathfunc::$name { value } [% { return [expr { ${func}(%value, %::rva::registers::$name, "$message") * exp2($to) }] }]

    set mask [msk2 $fr $to]
    proc dis_$name { value } [% {
        lindex [dict keys %::rva::registers::$name] [expr { ( %value & $mask ) >> $to }]
    }]
}
interp alias {} flag {} _enum flag

proc rva-enum { args } {
    _enum enum {*}$args
}

proc register { name bits reg api } {
    rva-enum $name $bits "expected register name found" $reg $api

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
        set mask [format 0x%08X [expr { msk2($hi, $lo) }]]
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
    set size [expr { exp2($hi) }]
    proc tcl::mathfunc::match_$name v [% { expr { label(%v) < $size } }]
}

namespace eval ::tcl::mathfunc {
    proc label { value } {
        if { [info exists ::LABEL($value)] } {
            return [expr { $::LABEL($value) - $::LABEL(.) }]
        }
        return $value
    }

    proc msk2 { hi lo } { format 0x%08X [expr { 0xffffffff & ((exp2($hi) - 1) ^ (exp2($lo) - 1)) }] }
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

    proc match_x0 rd { expr { $rd eq "x0" || $rd eq "zero" } }
    proc match_x1 rd { expr { $rd eq "x1" || $rd eq "ra"   } }
    proc match_x2 rd { expr { $rd eq "x2" || $rd eq "sp"   } }
    proc match_0  vx { expr { $vx ==   0 } }

    proc signed { value bits } {
        expr { $value - (($value & exp2($bits-1)) == 0 ? 0 : exp2($bits)) }
    }

    namespace export msk2
}
namespace import ::tcl::mathfunc::msk2

# Add a curry for the op, allowing defaults in at any arg position
#
proc alias { op args } {
    rename $op _$op
    lsplit $args fr to
    set tt {}
    foreach arg $to {
        if { $arg in $fr } { lappend tt \$$arg
        } else {             lappend tt $arg    }
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

proc dis_0  { word } { return  0 }
proc dis_x0 { word } { return x0 }
proc dis_x1 { word } { return x1 }
proc dis_x2 { word } { return x2 }

lappend ::optable { op mask bits pars vars }

proc opcode { op args } {
    lsplit $args args mapp
    set Bits [pick { apply { x { expr { [string first = $x] != -1 } } } } $args]    ; # Choose the bit def args : x..y=k
    set bits [fold { apply { { x y } { expr { $x | bits($y) } } } } 0 $Bits]        ; # Reduce bits with bits() function
    set bits [format 0x%08X $bits]                                                  ; # Format as 0x0Hex
    set mask [fold { apply { { x y } { expr { $x | mask($y) } } } } 0 $Bits]        ; # Reduce bits with bits() function
    set mask [format 0x%08X $mask]                                                  ; # Format as 0x0Hex
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

    dict set ::opcode $op op   $op                                                 ; # Save some info about op
    dict set ::opcode $op mask $mask
    dict set ::opcode $op bits $bits                                               ; # Save some info about op
    dict set ::opcode $op pars $pars
    dict set ::opcode $op vars $vars

    lappend ::optable [list $op $mask $bits $pars $vars]

    if { $mapp ne {} } {                                                            ; # Build a short op map?
        set mvals [lassign $mapp mop]                                               ; # Split mop and mvals
        set mpars [dict get $::opcode $mop pars]
        set mvars [dict get $::opcode $mop vars]

        # Map the passed args from the op to the mop - adding $ expansion.
        #
        set vvv  [join [map p [string map [zip $mvals $mpars] $pars] { I "\$$p" }] " "]

        if { [llength $mpars] } {                                                   ; # If there are args
            # Create an expression to check the validity of the args for mop
            #
            set expr [join [map m $mpars p $mvals { concat match_${p}(\$$m) }] " && "]
            if { [lindex $mvals 0] == [lindex $mvals 1] } {                         ; # Special case arg1 == arg2
                append expr " && \$[lindex $mpars 0] eq \$[lindex $mpars 1]"
            }
        } else {
            set expr 1 
        }

        # Shim out the implementation of .mop to check if op is applicable and use that instead
        #
        shim .$mop $mpars [% {
            if { $expr } {
                return [.$op $vvv]
            } 
            return [shim:next .$mop $mvars]
        }]

        # generate a disassembler that maps to the mopp code.
        #
        set body [join [list list $mop {*}[map p $mvals { I "\[dis_${p} \$word]" }]] " "]
        if { [info procs dis_${mask}_${bits}] != "" } {
            error "duplicate opcode decodes: $op - $bit"
        }
    } else {
        # generate the disassembler for this opcode
        #
        set body [join [list list $op {*}[map p $pars { I "\[dis_${p} \$word]" }]] " "]
        if { [info procs dis_${mask}_${bits}] != "" } {
            error "duplicate opcode decodes: $op - $bits"
        }
    }
    dict set ::opcode $op disa $body
}

proc assemble { opcode instr } {
    print assemble
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
    set showtable no
    set disassemble no
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        switch $arg {
            -t      { set showtable   yes }
            -d      { set disassemble yes }
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

    if { $disassemble } {
        disassemble_init
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
