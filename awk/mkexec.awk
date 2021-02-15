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

function mkmask(str) {
    n = split(str, B, /=/)
    n = split(B[1], N, /\.\./)

    r = xor(exp2(N[1]+1)-1, exp2(N[2])-1)

    return r
}

function replace(expr) 
{
    gsub(/\(/, " ( ")
    gsub(/ rd / , " R[rd_decode(instr)] ",  expr)
    gsub(/ rs1 /, " R[rs1_decode(instr)] ", expr)
    gsub(/ rs2 /, " R[rs2_decode(instr)] ", expr)
    gsub(/ jimm12 /, " jimm12_decode(instr) ", expr)
    gsub(/ simm12 /, " simm12_decode(instr) ", expr)
    gsub(/ bimm12 /, " bimm12_decode(instr) ", expr)
    gsub(/ imm12 /, " imm12_decode(instr) ", expr)
    gsub(/ imm20 /, " imm12_decode(instr) ", expr)
    gsub(/ shamt /, " shamt_decode(instr) ", expr)

    return expr
}

function ltrim(str) { gsub(/^ */, "", str); return str; }
function rtrim(str) { gsub(/ *$/, "", str); return str; }
function trim(str) { return ltrim(rtrim(str)) }

function readExprs(                    i) {
    while ( (getline < "exprs.tab") > 0 ) {
        instr = trim($1)
        $1 = ""
        EXPRS[instr] = $0
    }
}

BEGIN {
    readExprs()
    print "function exec(instr) {"

}
{
    aaa = ""
    nargs = 0
    bits = 0
    printf("    if (")

    for ( i = NF; i >= 2; i-- ) {
        if ( $i ~ /^[0-9]+\.\.[0-9]+=/ ) {
            bits = decode($i)
            mask = mkmask($i)

            printf("%s 0x%x == and(instr, 0x%x)", aaa, bits, mask)
            aaa = " &&"
        }
    }
    print " ) {"
    printf("        # %s\n", $1)
    printf("        %s\n", replace(EXPRS[$1]))
    print "    }"
}
END {
    print "}"
}
