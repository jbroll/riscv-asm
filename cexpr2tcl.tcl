
package require sugar

proc expr-regsub { expr { dollar \$ } } {
    set expr [regsub -all -- {\Mra\m} $expr x1]
    set expr [regsub -all -- ${::reg-regexp} "$expr" "${dollar}R(\$&)"]
    set expr [regsub -all -- ${::pcx-regexp} "$expr" "${dollar}R(&)"]
    set expr [regsub -all -- ${::enu-regexp} "$expr" "${dollar}C(\$&)"]
    set expr [regsub -all -- ${::csr-regexp} "$expr" "${dollar}C(&)"]
    set expr [regsub -all -- ${::imm-regexp} "$expr" "${dollar}&"]
    set expr [regsub -all -- ${::var-regexp} "$expr" "${dollar}&"]
}

sugar::syntaxmacro sugarmath { args } {
    if { [lindex $args 1] eq "=" } {
        set xx [lindex $args 0]
        set xx [expr-regsub $xx ""]
        set expr [lrange $args 2 end]
        set expr [expr-regsub $expr]
        return [list set $xx "\[expr { signed(($expr) & msk2([xlen]-1, 0), [xlen]) }]"]
    }
    if { [lindex $args 1] in { += -= *= /= } } {
        set xx [lindex $args 0]
        set op [string index [lindex $args 1] 0]
        set expr "$xx $op [join [lrange $args 2 end]]"
        set expr [expr-regsub $expr]
        set xx [expr-regsub $xx ""]
        return [list set $xx "\[expr { $expr }]"]
    }
    if { [regexp {^ *[a-zA-Z_][a-zA-Z_0-9]*\(.*\) *$} $args] } {
        set expr [expr-regsub $args]
        return [list "expr { $expr }"]
    }
    if { [string first \$ $args] == -1 } {
        return [expr-regsub $args]
    }
    return $args
}

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

proc cexpr2tcl { script } {
    sugar::expand $script
}

