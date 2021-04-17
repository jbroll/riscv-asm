
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

    proc fpnorm32 { value } {
        binary scan [binary format r $value] r value
        return $value
    }

    proc fpnorm64 { value } {
        binary scan [binary format q $value] q value
        return $value
    }

    proc fpcsr { value } {
        if { $value ==  inf } { return $value }
        if { $value == -inf } { return $value }

        set norm [fpnorm32 $value]
        if { $norm != $value } {
            set ::C(fflags) [expr { $::C(fflags) | 1 }]
        }
        return $value
    }

    proc fpclass { value } {
        set bits [unsigned [fbits $value]]
        print $value [format 0x%x $bits]
        set value 0
        if { $bits == 0xff800000 } { set value [expr { $value | (1 << 0) }] }
        if { $bits == 0xbf800000 } { set value [expr { $value | (1 << 1) }] }
        if { $bits == 0x807fffff } { set value [expr { $value | (1 << 2) }] }
        if { $bits == 0x80000000 } { set value [expr { $value | (1 << 3) }] }
        if { $bits == 0x00000000 } { set value [expr { $value | (1 << 4) }] }
        if { $bits == 0x007fffff } { set value [expr { $value | (1 << 5) }] }
        if { $bits == 0x3f800000 } { set value [expr { $value | (1 << 6) }] }
        if { $bits == 0x7f800000 } { set value [expr { $value | (1 << 7) }] }
        if { $bits == 0x7f800001 } { set value [expr { $value | (1 << 8) }] }
        if { $bits == 0x7fc00000 } { set value [expr { $value | (1 << 9) }] }

        return $value
    }

    namespace export msk2 exp2
}
