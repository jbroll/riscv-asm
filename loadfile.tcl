
proc elf_load_file { file } {

    set e [elf::elf create e $file]

    set segments [list [load_syms $e]]

    table foreachrow [pipe { $e get segments | table sort ~ p_paddr -integer }] {
        if { $p_type eq "PT_LOAD" } {
            lappend segments $p_flags $p_paddr [$e getSegmentDataByIndex $p_index]
        }
    }

    return $segments
}

proc load { fname } {

    switch [file extension $fname] {
        .lst { 
            set formats { 2 s 4 i }
            with file = [open $fname r] { set lines [read $file] }

            set segments { {} }
            set here 0
            set data ""
            set start 0
            foreach line [split $lines \n] {
                if { [llength $line] < 3 } { continue }

                set addr [expr { "0x[lindex $line 1]" & 0x7FFFFFFF }]
                set opco [lindex $line 2]
                set size [expr { [string length $opco] / 2 }]
                
                if { $addr != $here } {
                    set start $addr
                    set here $addr
                    if { [string length $data] > 0 } {
                        lappend segments 5 $start $data
                        set data ""
                    }
                }
                set here [expr { $here + $size }]
                append data [binary format [dict get $formats $size] 0x$opco]
            }
            if { [string length $data] > 0 } {
                lappend segments 5 $start $data
                set data ""
            }
            return $segments
        }
        .bin {
            with file = [open $fname r] { set text [read $file] }
            return [list $text {}]
        }
        .elf -
        default {
            return [elf_load_file $fname]
        }
    }
}

