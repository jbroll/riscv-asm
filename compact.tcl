
proc compact { op mask bits mapp pars } {
    if { $mapp eq {} } { return }                                               ; # Build a short op map?

    set mvals [lassign $mapp mop]                                               ; # Split mop and mvals
    set mpars [dict get $::opcode $mop pars]
    set mvars [dict get $::opcode $mop vars]

    # Map the passed args from the op to the mop - adding $ expansion.
    #
    set vvv  [join [lmap p [string map [zip $mvals $mpars] $pars] { I "\$$p" }] " "]

    if { [llength $mpars] } {                                                   ; # If there are args
        # Create an expression to check the validity of the args for mop
        #
        set expr [join [lmap m $mpars p $mvals { concat match_${p}(\$$m) }] " && "]
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
}
