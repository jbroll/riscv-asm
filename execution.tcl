package require jbr::with

proc pseudo2tcl { code } {
    return "eprint $code"
}
proc execution { op mapp mask bits } {

    if { ($bits & 0x03) == 0x03 } {
        set decode decode4
        set size 4
    } else {
        set decode decode2
        set size 2
    }

    if { $mapp ne {} } {
        set mop [lindex $mapp 0]
        set code [dict get $::opcode $mop code]
    } else {
        set code [dict get $::opcode $op code]
    }
        
    proc exec_${mask}_${bits} { word } [% {
        set disa [[dict get %::$decode $mask $bits disa] %word]
        lassign %disa $mapp

        [!pseudo2tcl $code]
        incr ::pc $size
    }]
    dict set ::opcode $op exec exec_${mask}_${bits}
}

proc load { fname } {

    switch [file extension $fname] {
        .lst { 
            set formats { 4 s 8 i }
            with file = [open $fname r] {
                gets $file
                set lines [read $file]
            }

            set data ""
            foreach line [split $lines \n] {
                set op [lindex $line 2]
                if { $op eq "" } { continue }
                append data [binary format [dict get $formats [string length $op]] 0x$op]
            }
            return $data
        }
        .bin {}
        .elf {}
    }
}

proc execute { args } {
    set file [lindex $args 0]
    set text [load $file]

    set ::pc 0
    upvar ::pc pc

    binary scan $text @${pc}cu byte
    while { $::pc < [string length $text] } {
        if { ($byte & 0x03) == 0x03 } {
            binary scan $text @${pc}i word
            decode_op4 exec [0x $word]
        } else {
            binary scan $text @${pc}i word
            decode_op2 exec [0x $word]
        }
        binary scan $text @${pc}cu byte
    }
}

