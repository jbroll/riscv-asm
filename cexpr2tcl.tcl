
package require sugar

# Expand all the special tokens to access registers and well known values.
#
proc expr-regsub { expr { dollar \$ } } {
    set expr [regsub -all -- {\Mra\m} $expr x1]
    set expr [regsub -all -- ${::reg-regexp} "$expr" "${dollar}R(\$&)"]
    set expr [regsub -all -- ${::pcx-regexp} "$expr" "${dollar}R(&)"]
    set expr [regsub -all -- ${::fpx-regexp} "$expr" "${dollar}R(&)"]
    set expr [regsub -all -- ${::enu-regexp} "$expr" "${dollar}C(\$&)"]
    set expr [regsub -all -- ${::csr-regexp} "$expr" "${dollar}C(&)"]
    set expr [regsub -all -- ${::imm-regexp} "$expr" "${dollar}&"]
    set expr [regsub -all -- ${::var-regexp} "$expr" "${dollar}&"]
}

sugar::syntaxmacro sugarmath { args } {

    # rx = some math expr
    #
    if { [lindex $args 1] eq "=" } {
        set yy [lindex $args 0]
        set xx [expr-regsub $yy ""]
        set expr [lrange $args 2 end]
        set expr [expr-regsub $expr]
        if { [string index $yy 0] eq f } {
            return [list set $xx "\[expr { $expr }]"]
        } else {
            return [list set $xx "\[expr { signed(($expr), [xlen]) }]"]
        }
    }

    # rx += some math expr
    #
    if { [lindex $args 1] in { += -= *= /= } } {
        set xx [lindex $args 0]
        set op [string index [lindex $args 1] 0]
        set expr "$xx $op [join [lrange $args 2 end]]"
        set expr [expr-regsub $expr]
        set xx [expr-regsub $xx ""]
        return [list set $xx "\[expr { signed(($expr), [xlen]) }]"]
    }

    # some math function call (with side effects) on a line by itself.
    #
    if { [regexp {^ *[a-zA-Z_][a-zA-Z_0-9]*\(.*\) *$} $args] } {
        set expr [expr-regsub $args]
        return [list "expr { $expr }"]
    }

    # Some tcl code - possiblly expand well known tokens.
    #
    if { [string first \$ $args] == -1 } {
        return [expr-regsub $args]
    }
    return $args
}

# Support expansion of 'if'
#
sugar::macro if args {
    lappend newargs [lindex $args 0]
    set expr [lindex $args 1]
    if { [string first \$ $expr] == -1 } {
        set expr [expr-regsub $expr]
    }
    lappend newargs [sugar::expandExprToken $expr]
    set args [lrange $args 2 end]
    foreach a $args {
	switch -- $a {
	    else - elseif {
		lappend newargs $a
	    }
	    default {
            lappend newargs [sugar::expandScriptToken $a]
	    }
	}
    }
    return $newargs
}

# Expand opcode eval mini language
#
proc cexpr2tcl { script locals } {
    set script [sugar::expand $script]
    dict for {name value} $locals {
        set script [regsub -all "\\m${name}\\M" $script $value]
    }
    return $script
}

