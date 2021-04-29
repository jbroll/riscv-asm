# Look here!
#
# https://float.exposed/0x7fc00000
# https://floating-point-gui.de/
# https://github.com/LiraNuna/soft-ieee754

package require jbr::print

oo::class create ieee754 {
    constructor { e m } {
        variable E $e
        variable M $m

        variable BITS [expr { 1 + $E + $M }]
        variable BIAS [expr { (1 << ($E - 1)) - 1 }]

        variable MANTISSA_MASK  [expr { (1 << $M) - 1 }]
        variable MANTISSA_MAX   [expr { (1 << ($M+1)) - 1 }]
        variable EXPONENT_BITS  [expr { (1 << $E) - 1 }]
        variable EXPONENT_MASK  [expr { $EXPONENT_BITS<< $M }]
        variable MIN_EXPONENT   [expr { -$BIAS + 2 }]
        variable MAX_EXPONENT   [expr {  $BIAS + 1 }]

        variable MAX [expr { pow(2, $MAX_EXPONENT) }]
    }

    method unpack { v } {
        my variable MANTISSA_MASK EXPONENT_MASK BITS M

        list [expr { $v >> ($BITS-1) }] [expr { ($v & $EXPONENT_MASK) >> $M }] [expr { $v & $MANTISSA_MASK }]
    }
    method pack { s e m } {
        my variable MANTISSA_MASK EXPONENT_MASK BITS M
        #print pack $s [0x $e] [0x [expr { int($m)}]]

        expr { $s << ($BITS-1) | ((int($e) << $M) & $EXPONENT_MASK) | (int($m) & $MANTISSA_MASK) }
    }

    method nan { { sign 0 } { m 1 } } {
        my variable EXPONENT_BITS 

        my pack $sign $EXPONENT_BITS $m
    }
    method inf { { sign 0 } } {
        my nan $sign 0
    }

    method isnan { value } {
        my variable MANTISSA_MASK EXPONENT_MASK

        if { ($value & $EXPONENT_MASK) == $EXPONENT_MASK && ($value & $MANTISSA_MASK) != 0 } {
            return true
        }

        return false
    }

    method isinf { value } {
        my variable MANTISSA_MASK EXPONENT_MASK

        if { ($value & $EXPONENT_MASK) == $EXPONENT_MASK && ($value & $MANTISSA_MASK) == 0 } {
            return true
        }

        return false
    }

    method sign { value } {
        my variable BITS

        if { $value & (1 << ($BITS-1)) } {
            return -1
        } else {
            return  1
        }
    }

    method shift { v shift } {
        if { $shift < 0 } {
            return [expr { $v / (1 << -$shift) }]
        } else {
            return [expr { $v * (1 <<  $shift) }]
        }
    }

    method to-ieee754 { v { point 0 } } {
        my variable MAX EXPONENT_BITS MIN_EXPONENT BIAS M E

        if { $v == 0 } {
            return [my pack 0 $point $v]
        }

        set sign [expr $v < 0 ? 1 : 0]
        set v [expr { abs($v) }]

        if { $v > $MAX } {
            #print Over $v $MAX
            
            # Overflow -- NaN
            #
            return [my pack $sign $EXPONENT_BITS 0]
        } else {
            set log2 [expr { entier(log($v)/log(2)) }]

            #print $v $log2 [expr { log($v)/log(2) }]

            if { $point + $log2 + 1 < $MIN_EXPONENT } {
                #print Under

                # Underflow -- Subnormal
                #
                return [my pack $sign 0 [my shift $v [expr { $M - (MIN_EXPONENT - $point - 1)) }]]]
            } else {

                #print $v [expr { $v ? $log2 + $point + $BIAS : 0 }]
                #print $v [my shift $v [expr { $M - $log2 }]]
                #print [0x [my pack $sign [expr { $v ? $log2 + $point + $BIAS : 0 }] [my shift $v [expr { $M - $log2 }]]]]
                # Build a number
                #
                return [my pack $sign [expr { $v ? $log2 + $point + $BIAS : 0 }] [my shift $v [expr { $M - $log2 }]]]
            }
        }
    }
    method to-float { v } {
        my variable M BIAS

        lassign [my unpack $v] s e m

        set m [expr { $e != 0 ? double($m | (1 << $M)) : 0 }]
        expr { ($s ? -1 : 1) * [my shift [expr { $m/(1 << $M) }] [expr { ($e - $BIAS) }]] }
    }
    method to-entier { v } {
        expr { entier([my to-float($v)]) }
    }

    method add { a b } {

        my to-ieee754 [expr { [my to-float $a] + [my to-float $b] }]
    }
    method sub { a b } {
        my to-ieee754 [expr { [my to-float $a] - [my to-float $b] }]
    }
    method mul { a b } {
        my variable M BIAS BITS

        lassign [my unpack $a] as ae am
        lassign [my unpack $b] bs be bm

        set am [expr { $ae != 0 ? ($am | (1 << $M)) : 0 }]
        set bm [expr { $be != 0 ? ($bm | (1 << $M)) : 0 }]

        set as [expr { $as ^ $bs }]
        set ae [expr { $ae + $be - $BIAS*2 }]
        set am [expr { $am * $bm }]

        expr { [my to-ieee754 $am [expr { -2*$M+$ae }]] | ($as ? (1 << ($BITS-1)) : 0) }
    }
    method div { a b } {
        my to-ieee754 [expr { [my to-float $a] / [my to-float $b] }]
    }
}

