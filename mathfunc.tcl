
namespace eval ::tcl::mathfunc {
    proc sign { value } {
        if { $value >= 0 } { return 1 } else { return -1 } 
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

    proc match_0    vx { expr { $vx ==   0 } }
    proc match_iorw vx { expr { $vx eq "iorw" } }

    proc signed { value bits } {
        expr { ($value & msk2($bits-1, 0)) - (($value & exp2($bits-1)) == 0 ? 0 : exp2($bits)) }
    }

    proc fbits { v } {
        binary scan [binary format r $v] i result
        return $result
    }
    proc ibits { v } {
        binary scan [binary format i $v] r result
        return $result
    }

    namespace export msk2 exp2
}
