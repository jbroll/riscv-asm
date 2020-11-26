#!/usr/bin/env tawk -f
#

{ gsub(/#.*/, "") }
/^ *$/ { next }

function exp2(n, i, r) {
    if ( n == 0 ) { return 1 }

    r = 2
    for ( i = 1; i < n; i++ ) {
        r *= 2;
    }

    return r;
}

function decode(str) {
    n = split(str, B, /=/)
    n = split(B[1], N, /\.\./)

    r = B[2] * exp2(N[2])

    return r
}

{
    nargs = 0
    bits = 0
    for ( i = 2; i <= NF; i++ ) {
        if ( $i ~ /^[0-9]+\.\.[0-9]+=/ ) {
            bits = or(bits, decode($i))
            continue
        }
        if ( $i ~ /bimm12lo/ ) { 
            args[nargs++] = "bimm12"
            continue
        }
        if ( $i ~ /imm12hi/ ) { 
            continue
        }
        if ( $i ~ /rd/ ) { 
            args[nargs++] = $i
            continue
        }
        if ( $i ~ /rs/ ) { 
            args[nargs++] = $i
            continue
        }
        if ( $i ~ /imm12lo/ ) { 
            args[nargs++] = "simm12"
            continue
        }
        if ( $i ~ /imm12/ ) { 
            args[nargs++] = "imm12"
            continue
        }
        if ( $i ~ /jimm20/ ) { 
            args[nargs++] = "jimm20"
            continue
        }
        if ( $i ~ /imm20/ ) { 
            args[nargs++] = "imm20"
            continue
        }
        if ( $i ~ /shamt/ ) { 
            args[nargs++] = "shamt"
            continue
        }

        args[nargs++] = $i
    }
    printf("0x%08x %10s", bits, $1)
    for ( i = 0; i < nargs; i++ ) {
        printf(" %8s", args[i])
    }
    print ""

}
