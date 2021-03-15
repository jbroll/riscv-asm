
namespace eval rva {}                   ; # Someday everything will live here
namespace eval rva::registers {}

set LABEL(.) 0

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

proc _enum { func name bits message args } {
    set registers [concat {*}$args]
    set ::rva::registers::$name $registers
    set ::rva::registers::${name}_rev [lreverse $registers]
    lassign [regsub -all {[=._]} $bits " "] fr to

    proc ::tcl::mathfunc::$name { value } [% { return [expr { ${func}(%value, %::rva::registers::$name, "$message") * exp2($to) }] }]

    set mask [msk2 $fr $to]
    if { $func eq "enum" } {
        proc dis_$name { value } [% {
            dict get %::rva::registers::${name}_rev [expr { ( %value & $mask ) >> $to }]
        }]
    } else {
        proc dis_$name { value } [% {
            set flags ""
            foreach {flag bits} %::rva::registers::$name {
                if { %value & %bits } {
                    append flags %flag
                }
            }
            return %flags
        }]
    }
}
interp alias {} flag {} _enum flag

proc rva-enum { args } {
    _enum enum {*}$args
}

# Convert a list of valid register names into a dict for reg -> value map.
#
proc reg-names { names } {
    zip $names [iota 0 [llength $names]-1]
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
    proc match_iorw vx { expr { $vx eq "iorw" } }

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
set alias {}
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

    if { $::unalias } {
        set match {}
        set pars  $top
        foreach n [iota 1 [llength $to]] arg $to {
            if { $arg in $fr } { 
                lappend pars $arg
                continue 
            }
            lappend pars $n
            lappend match "match_${arg}(\$$n)"
        }
        set ff [concat {*}[lmap arg $fr { I "\$$arg" }]]

        dict lappend ::alias $top [dict create fr [list $op {*}$ff] pars $pars match [join $match " && "]]
    }
}

proc dis_0  { word } { return  0 }
proc dis_x0 { word } { return x0 }
proc dis_x1 { word } { return x1 }
proc dis_x2 { word } { return x2 }

lappend ::optable { op mask bits pars vars }

proc opcode { op args } {
    lsplit $args args mapp ->
    lsplit $args pars Bits :
    lsplit $mapp mapp code |

    set bits [0x [fold { apply { { x y } { expr { $x | bits($y) } } } } 0 $Bits]]    ; # reduce Bits with bits() function
    set mask [0x [fold { apply { { x y } { expr { $x | mask($y) } } } } 0 $Bits]]    ; # reduce Bits with mask() function
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
    dict set ::opcode $op code $code

    lappend ::optable [list $op $mask $bits $pars $vars]

    compact      $op $pars $mapp
    execution    $op $mapp $mask $bits
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

proc macro { name args body } {
    foreach arg $args {
        set body [regsub -all "\\m$arg\\M" $body "\$$arg"]
    }
    proc $name $args $body
}

