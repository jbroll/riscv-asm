
namespace eval ::tcl::mathfunc {
    proc sign { value } {
        if { $value >= 0 } { return 1 } else { return -1 } 
    }
    proc label { value } {
        if { [info exists ::LABEL($value)] } {
            return [expr { $::LABEL($value) - $::LABEL(.) }]
        }
        return $value
    }

    proc msk2 { hi lo } { 0x [expr { (exp2($hi+1) - 1) ^ (exp2($lo) - 1) }] }
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

    # Match functions for well known default values in alias and compact
    # definitions.
    #  
    proc match_x0   rd { expr { $rd eq "x0" || $rd eq "zero" } }
    proc match_zero rd { expr { $rd eq "x0" || $rd eq "zero" } }
    proc match_x1   rd { expr { $rd eq "x1" || $rd eq "ra"   } }
    proc match_ra   rd { expr { $rd eq "x1" || $rd eq "ra"   } }
    proc match_x2   rd { expr { $rd eq "x2" || $rd eq "sp"   } }
    proc match_sp   rd { expr { $rd eq "x2" || $rd eq "sp"   } }
    proc match_0    vx { expr { $vx ==   0 } }
    proc match_iorw vx { expr { $vx eq "iorw" } }

    proc signed { value bits } {
        expr { ($value & msk2($bits-1, 0)) - (($value & exp2($bits-1)) == 0 ? 0 : exp2($bits)) }
    }

    namespace export msk2 exp2
}
