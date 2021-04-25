#!/usr/bin/env tclkit8.6
#
package require jbr::print
package require jbr::test

test::suite riscv-asm {
    test labels {
        setup {
            source labels.tcl
        }
        case-dot {
            eq {dot} 0                      "dot not initialized to 0"
            eq {getlabel .} 0               "getlabel . --> 0"
            incrdot 4
            eq {dot} 4                      "dot not increemnted to 4"
            eq {getlabel .} 4               "getlabel . --> 4"

            setlabel label wink
            eq {getlabel label} wink        "set label to string"
            setlabel label 3422
            eq {getlabel label} 3422        "set label to value"
        }
        case-named {
            dot 14
            : here
            eq {getlabel here} 14           "check that the label 'here' is defined"
        }
        case-unknown {
            dot 14
            here:
            eq {getlabel here} 14           "check that the label 'here' is defined"
        }
    }

    test memory {
        setup {
            source memory.tcl
        }
        case-word {
            st_word 0 0x12345678
            eq {ld_uword 0} 0x12345678     "read word back from memory"
            binary scan [memory 0 3] i word
            eq {I $word} 0x12345678            "format and scan memory"
        }
        case-half {
            st_half 6 0x5678
            eq {ld_uhalf 6} 0x5678          "read half back from memory"
            eq {ld_uhalf 4} 0x0             "read half back from memory 0 before"
            eq {ld_uhalf 8} 0x0             "read half back from memory 0 after"

        }
    }
 
    test assemble {
        setup {
            source memory.tcl
            source labels.tcl
            source assemble.tcl
        }
        case {
            assemble 0x12345673 "some instrucitons"
            eq {dot} 4                      "check that dot advances on 4 byte"
            assemble 0x1234     "some other instrucitons"
            eq {dot} 6                      "check that dot advances on 2 byte"
        }
    }
}
