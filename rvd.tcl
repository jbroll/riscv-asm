
source $root/elf/elf.tcl

proc disassemble { args } {

    set file [lindex $args 0]

    set elf elf::elf $file

    foreach arg $args {
        set found no
        dict for {mask opcodes} $decode {                       ; # foreach major opcode mask
            set bits [format 0x%08X [expr { $arg & $mask }]]    ; # compute the significant bits in the code

            if { [dict exists $opcodes $bits] } {
                eprint {*}[dis_$bits $arg]                          ; # disassemle
                set found yes
                break
            }
        }
        if { ! $found } {
            error "unknown instruction $arg"
        }
    }
}

