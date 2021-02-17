# These are the register definitions for standard extensions.  If you create an extension 
# that uses standard registers you can just use these register types.  If you need to 
# create additional regiters for your opcodes, you can use the `register` proc at the top of
# your opcodes-xaaa extension file.

set api [reg-names { zero  ra   sp   gp  tp  t0  t1  t2  
                       s0  s1   a0   a1  a2  a3  a4  a5  
                       a6  a7   s2   s3  s4  s5  s6  s7  
                       s8  s9  s10  s11  t3  t4  t5  t6 
}]
if { [iset e] } { set api [lrange $api 0 15] }

set reg [reg-names {  x0   x1   x2   x3  x4  x5  x6  x7  
                      x8   x9  x10  x11 x12 x13 x14 x15  
                     x16  x17  x18  x19 x20 x21 x22 x23  
                     x24  x25  x26  x27 x28 x29 x30 x31 
}]
if { [iset e] } { set reg [lrange $reg 0 15] }

set apinz [dict remove $api   zero]
set regnz [dict remove $reg   x0]
set apin2 [dict remove $apinz sp] 
set regn2 [dict remove $regnz x2] 

register  rd    11.._7    $reg   $api
register  rdnz  11.._7    $regnz $apinz
register  rdn2  11.._7    $regn2 $apin2
register  rs1   19..15    $reg   $api
register  rs1nz 19..15    $regnz $apinz
register  rs2   24..20    $reg   $api
register  rs2nz 24..20    $regnz $apinz

set flags { i 0x8 o 0x4 r 0x2 w 0x1 }

flag pred 27..24 "expected fence predecessor flags" $flags
flag succ 23..20 "expected fence successor flags"   $flags
flag aqrl 26..25 "expected aquire and release flags"  { a 2 r 1 x 0 }

if { [iset zfinx] } {
    set apifp $api
    set regfp $reg
} else {
    set apifp [reg-names { ft0  ft1  ft2  ft3  ft4  ft5  ft6  ft7   
                           fs0  fs1  fa0  fa1  fa2  fa3  fa4  fa5   
                           fa6  fa7  fs2  fs3  fs4  fs5  fs6  fs7   
                           fs8  fs9 fs10 fs11  ft8  ft9 ft10 ft11 
    }]
    if { [iset e] } { set apifp [lrange $apifp 0 15] }

    set regfp [reg-names {  f0   f1   f2   f3   f4   f5   f6   f7   
                            f8   f9  f10  f11  f12  f13  f14  f15  
                           f16  f17  f18  f19  f20  f21  f22  f23  
                           f24  f25  f26  f27  f28  f29  f30  f31 
    }]
    if { [iset e] } { set regfp [lrange $regfp 0 15] }
}
set apifpnz [dict remove $apifp zero]
set regfpnz [dict remove $regfp f0]

register  fd 11.._7  $regfp $apifp
register fs1 19..15  $regfp $apifp
register fs2 24..20  $regfp $apifp
register fs3 31..27  $regfp $apifp

enum rm 14..12 "expected rounding mode" { rne 0 rtz 1 rnd 2 rup 3 rmm 4 dyn 7 }

set apc   [reg-names [lrange [dict keys $api]   8 15]]
set rxc   [reg-names [lrange [dict keys $reg]   8 15]]
set afc   [reg-names [lrange [dict keys $apifp] 8 15]]
set rfc   [reg-names [lrange [dict keys $regfp] 8 15]]

register crd     11..7  $reg   $api
register crs1    11..7  $reg   $api
register crs2     6..2  $reg   $api
register crdnz   11..7  $regnz $apinz
register crs1nz  11..7  $regnz $apinz
register crs2nz   6..2  $regnz $apinz
register cfd     11..7  $regfp $apifp
register cfs2     6..2  $regfp $apifp

register crs1c  9..7  $rxc $apc
register crs2c  4..2  $rxc $apc
register crdhc  9..7  $rxc $apc
register crdlc  4..2  $rxc $apc

register cfdc   4..2  $rfc $afc  
register cfs1c  9..7  $rfc $afc  
register cfdhc  9..7  $rfc $afc
register cfdlc  4..2  $rfc $afc

