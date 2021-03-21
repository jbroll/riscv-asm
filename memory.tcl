
set ::mem [lrepeat 32768 0]

namespace eval ::tcl::mathfunc {
    proc ldb { addr } {
        set addr [expr { $addr & 0x7FFFFFFF }]
        if { $addr < 0 || $addr >= [llength $::mem] } {
            error "segv : $addr"
        }
        set value [lindex $::mem $addr]
        return $value
    }

    proc ld_sbyte { addr } { expr { signed(ldb($addr), 8) } }
    proc ld_shalf { addr } { expr { signed(ldb($addr) + (ldb($addr+1) << 8), 16) } }
    proc ld_sword { addr } { expr { signed(ldb($addr) + (ldb($addr+1) << 8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24), 32) } }
    proc ld_sdble { addr } { expr { signed(
        (ldb($addr  )      ) + (ldb($addr+1) <<  8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24) +
        (ldb($addr+4) << 32) + (ldb($addr+5) << 40)  + (ldb($addr+6) << 48) + (ldb($addr+7) << 56), 64) } }
    proc ld_ubyte { addr } { expr { ldb($addr) & 0xFF } }
    proc ld_uhalf { addr } { expr { (ldb($addr) + (ldb($addr+1) << 8)) & 0xFFFF } }
    proc ld_uword { addr } { expr { (ldb($addr) + (ldb($addr+1) << 8)  + (ldb($addr+2) << 16) + (ldb($addr+3) << 24)) & 0xFFFFFFFF } }

    proc stb { value addr } {
        set addr [expr { $addr & 0x7FFFFFFF }]
        if { $addr < 0 || $addr >= [llength $::mem] } {
            error "segv : $addr"
        }
        set value [expr { $value & 0xFF }]
        lset ::mem $addr $value
    }
    proc st_byte { value addr } { expr { stb($value, $addr) } }
    proc st_half { value addr } { expr { stb($value, $addr) }
                                  expr { stb($value >> 8, $addr+1) } }
    proc st_word { value addr } { expr { stb($value,       $addr)   }
                                  expr { stb($value >>  8, $addr+1) }
                                  expr { stb($value >> 16, $addr+2) }
                                  expr { stb($value >> 24, $addr+3) }
                                } 
    proc st_dble { value addr } { expr { stb($value,       $addr)   }
                                  expr { stb($value >>  8, $addr+1) }
                                  expr { stb($value >> 16, $addr+2) }
                                  expr { stb($value >> 24, $addr+3) }
                                  expr { stb($value >> 32, $addr+4) }
                                  expr { stb($value >> 40, $addr+5) }
                                  expr { stb($value >> 48, $addr+6) }
                                  expr { stb($value >> 56, $addr+7) }
                                } 

    proc unsigned { value { from 31 } } {
        expr { $value & msk2($from, 0) }
    }

    namespace export ld_uword
}
namespace import ::tcl::mathfunc::ld_uword

