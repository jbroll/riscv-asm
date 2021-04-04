
namespace eval rva {}                   ; # Someday everything will live here
namespace eval rva::registers {}

proc _enum { func name bits message args } {
    set registers [concat {*}$args]
    set ::rva::registers::$name [lmap x $registers { expr { [string first 0x $x] == 0 ? $x : [I $x] } }]
    set ::rva::registers::${name}_rev [lreverse [set ::rva::registers::$name]]
    lassign [regsub -all {[=._]} $bits " "] fr to

    proc ::tcl::mathfunc::$name { value } [% { return [expr { ${func}(%value, %::rva::registers::$name, "$message") * exp2($to) }] }]
    proc ::tcl::mathfunc::match_${name} { value } [% { expr { %value in [dict keys %::rva::registers::$name] } }]
    foreach enum [dict keys $registers] {
        proc ::tcl::mathfunc::match_$enum { value } [% { expr { %value == "$enum" } }]
    }

    set mask [msk2 $fr $to]
    if { $func eq "enum" } {
        proc dis_$name { value } [% {
            try {
                dict get %::rva::registers::${name}_rev [expr { ( %value & $mask ) >> $to }]
            } on error e {
                error "enum $name %value : %e : %::rva::registers::${name}_rev"
            }
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

proc rva-control { name args } {
    lappend ::eclasses $name
    _enum enum $name {*}$args
}

proc rva-enum { name args } {
    _enum enum $name {*}$args
}

# Convert a list of valid register names into a dict for reg -> value map.
#
proc reg-names { names } {
    zip $names [iota 0 [llength $names]-1]
}

# Create a register place holder represented by the bit range bits in the instruciton word
# reg gives the list of machine register names and api gives the list of api alias names.
#
proc register { name bits reg api } {
    lappend ::rclasses $name

    if { $::preferApi } {                                               ; # The registers that appear first are used in disassembly
        rva-enum $name $bits "expected register name found" $api $reg
    } else {
        rva-enum $name $bits "expected register name found" $reg $api
    }
}

# Parse an immediate value place holder and create assembler parts for it
#
proc immediate { name Bits width } {
    lappend ::iclasses $name

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
    set expr [join $expr |]         ; # An expression to convert an immediate value to its in instruction representation
    set disa [join $disa |]         ; # An expression to extract an immediate value from its instruction representation

    # Create a function that computes the instruction bits of an immediate
    # using the above expression
    # 
    proc ::tcl::mathfunc::$name { value } [% {
        set value [::tcl::mathfunc::label %value $name]
        return [expr { $expr }]
    }]

    # Create a function that computes the value of an immediate from an
    # instruction using the above expression.  Most immedaites are wrapped
    # in 'signed' to sign extend the value after extraction.
    # 
    if { $width == "unsigned" } {
        proc dis_$name { value } [% {
            expr { $disa }
        }]
    } else {
        proc dis_$name { value } [% {
            expr { signed($disa, $width) }
        }]
    }

    # Check the reversability of the immediate function
    #
    #assert-eq [::tcl::mathfunc::$name 0xffffffff]  \
    #          [::tcl::mathfunc::$name [dis_$name [::tcl::mathfunc::$name 0xffffffff]]] "\n\t$expr\n\t$disa"

    # Create a function that checks the validity of an immediate for use in
    # mapping alias and compact instructions.  
    # TODO: Check sign/unsigned value and use abs().
    #
    set size [exp2 $hi]
    proc tcl::mathfunc::match_$name v [% { expr { abs(match_label(%v)) < $size } }]
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

# Define an opcode.
#
# Two manditory and two optional parts
#
# mnumonic args...   :  bit definition  -> compact to rv32i mapping | { semanitcs in instruciton mini language }
#  
proc opcode { op args } {
    lsplit $args args code |
    lsplit $args args mapp ->
    lsplit $args pars Bits :

    set bits [0x [fold { apply { { x y } { expr { $x | bits($y) } } } } 0 $Bits]]    ; # reduce Bits with bits() function
    set mask [0x [fold { apply { { x y } { expr { $x | mask($y) } } } } 0 $Bits]]    ; # reduce Bits with mask() function
    set vars [join [lmap p $pars { I \$$p }] " "]                                    ; # variable expansion for assemble comment
    set expr [join [list $bits {*}[lmap p $pars { I "${p}(\$$p)" }]] |]              ; # build bits expression to assemble the opcode 
                                                                                     ; # and its args into an instruciton word
    foreach arg $pars {                                                     ; # Check that each param place holder has a conversion .
        if { [info procs ::tcl::mathfunc::$arg] == "" } {                   ; # function 
            eprint "missing argument type in op $op : $arg"
        }
    }

    if { [info proc $op] ne "" } {                                          ; # Warn if the mnumonic is already defined
        eprint redefine $op $args
        eprint existing op $op [dict get ::opcode $op]
    }
    proc .$op $pars "expr { $expr }"                                                ; # a proc to compute the opcode instruction value
    proc  $op $pars "assemble \[.$op $vars] \"[concat $op {*}$vars]\""              ; # a proc to assmeble the opcode at .

    dict set ::opcode $op op   $op                                                  ; # save some info about op
    dict set ::opcode $op mask $mask
    dict set ::opcode $op bits $bits
    dict set ::opcode $op pars $pars
    dict set ::opcode $op vars $vars
    dict set ::opcode $op code $code
    dict set ::opcode $op mapp $mapp
    dict set ::opcode $op size [expr { ( $bits & 0x03 ) == 0x3 ? 4 : 2 }]

    lappend ::optable [list $op $mask $bits $pars $vars]                    ; # Make a table to output on request

    # Build the compact and disassembler parts of opcode translation
    #
    compact      $op $mask $bits $mapp $pars
    disassembler $op $mask $bits $mapp $pars
}

proc line { addr source } {
    set line 0
    try { set line [dict get [info frame 3] line] } on error e {}

    dict set ::LINES $addr [list $line $source]
}

proc assemble { opcode instr } {
    set dot [dot]
    line $dot $instr

    if { ($opcode & 0x00000003) == 0x00000003 } { 
        st_word $dot $opcode
        incrdot 4
    } else {
        st_half $dot $opcode
        incrdot 2
    }
}

proc macro { name args body } {
    foreach arg $args {
        set body [regsub -all "\\m$arg\\M" $body "\$$arg"]
    }
    proc $name $args $body
}

