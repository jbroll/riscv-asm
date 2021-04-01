
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

    proc stb { addr value } {
        set addr [expr { $addr & 0x7FFFFFFF }]
        if { $addr < 0 || $addr >= [llength $::mem] } {
            error "segv : $addr"
        }
        lset ::mem $addr [expr { $value & 0xFF }]
    }
    proc st_byte { addr value } { expr { stb($addr,   $value)      } }
    proc st_half { addr value } { expr { stb($addr,   $value)      }
                                  expr { stb($addr+1, $value >> 8) } }
    proc st_word { addr value } { expr { stb($addr,   $value      ) }
                                  expr { stb($addr+1, $value >>  8) }
                                  expr { stb($addr+2, $value >> 16) }
                                  expr { stb($addr+3, $value >> 24) }
                                } 
    proc st_dble { addr value } { expr { stb($addr,   $value)       }
                                  expr { stb($addr+1, $value >>  8) }
                                  expr { stb($addr+2, $value >> 16) }
                                  expr { stb($addr+3, $value >> 24) }
                                  expr { stb($addr+4, $value >> 32) }
                                  expr { stb($addr+5, $value >> 40) }
                                  expr { stb($addr+6, $value >> 48) }
                                  expr { stb($addr+7, $value >> 56) }
                                } 

    proc unsigned { value { from 31 } } {
        expr { $value & msk2($from, 0) }
    }

    namespace export ld_uword ld_uhalf st_byte st_half st_word st_dble
}
namespace import ::tcl::mathfunc::ld_uword
namespace import ::tcl::mathfunc::ld_uhalf
namespace import ::tcl::mathfunc::st_byte
namespace import ::tcl::mathfunc::st_half
namespace import ::tcl::mathfunc::st_word
namespace import ::tcl::mathfunc::st_dble

proc memory { start end } {
    binary format c* [lrange $::mem $start $end]
}
