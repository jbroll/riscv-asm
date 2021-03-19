#!/usr/bin/env tclkit8.6
#
set root [file dirname [file normalize [info script]]]

package require jbr::assert
package require jbr::dict
package require jbr::func
package require jbr::list
package require jbr::print
package require jbr::shim
package require jbr::unix
package require jbr::stack
package require jbr::string
package require jbr::template

source $root/elf/elf.tcl
source $root/compact.tcl
source $root/decode.tcl

source $root/assemble.tcl
source $root/execution.tcl
source $root/disassemble.tcl

# Source a file with the script instlled directory prefix
#
proc include { file } {
    source $::root/$file
}

proc .org { org } { set ::LABEL(.) $org }
proc .global { args } {}
proc .text { args } {}

# A convenience proc to check an instruction set request.
#
proc iset { iset } {
    expr { [dict exists $::iset $iset] && [dict get $::iset $iset] eq $iset }
}

proc 0x { value { width 8 } } { format 0x%0*X $width $value }

proc main { args } {

    set March rv32IMAFDZicsr_Zifencei                           ; # The default march

    # A regex to extract the march definition and check the order (somewhat).
    #
    set match {^rv(32|64)(i|e)?(m)?(a)?(f)?(d)?(q)?(c)?((z[a-z]*)?(_(z[a-z]*))*)((_x[a-z]+)*)$}

    set ::preferApi   no
    set showtable     no
    set showalias     no
    set execute       no
    set verbose       no
    set ::disassemble no
    set ::unalias     yes

    set files {}
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        switch $arg {
            -reg     { set ::preferApi no  }
            -api     { set ::preferApi yes }
            -t       { set showtable   yes }
            -a       { set showalias   yes }
            -dc      { set ::disassemble compact }
            -d       { set ::disassemble yes }
            -march   { set March [lindex $args [incr i]] }
            -unalias { set ::unalias no }
            -v       { set verbose yes  }
            -x       { set execute yes  }
            default  { lappend files $arg }
        }
    }

    set march [string tolower $March]

    if { [string index $march 4] eq "g" } {
        set march [string replace $march 4 4 "imafd"]
        set x [string first _x $march]                          ; # _Z must come before _X.
        if { $x == -1 } {
            set x end
        }
        set march [string insert $march $x "_zicsr_zifencei"]
    }

    if { [regexp -- $match $march -> XLEN I M A F D Q C Z - - - X] <= 0 } {
        error "incorrect march string $March --> $march"
    }
    set ::iset [dict create rlen $XLEN i $I m $M a $A f $F d $D q $Q c $C]
    if { [dict get $::iset i] eq "e" } {        # ; The base arch is either I or E.
        dict set ::iset i i                     # ; E means I instructions w/ 16 registers
        dict set ::iset e e
    }
    foreach z [split $Z _] { dict set ::iset $z $z }
    foreach x [split $X _] { dict set ::iset $x $x }

    include registers.tcl                                   ; # Register definitions for standard extensions.

    include opcodes/opcodes-rv32i                           ; # Always include rv32i

    if { [iset m] } { include opcodes/opcodes-rv32m }
    if { [iset a] } { include opcodes/opcodes-rv32a }
    if { [iset h] } { include opcodes/opcodes-rv32h }
    if { [iset f] } { include opcodes/opcodes-rv32f }
    if { [iset d] } { include opcodes/opcodes-rv32d }
    if { [iset q] } { include opcodes/opcodes-rv32q }

    if { [iset c] } { include opcodes/opcodes-rvc }
    if { [dict get $::iset rlen] == 32 } {
        if { [iset c] }               { include opcodes/opcodes-rv32c }
        if { [iset c] && [iset f]   } { include opcodes/opcodes-rv32fc }
    }

    if { [iset f] && [iset zfh] } { include opcodes/opcodes-rv32f-zfh }
    if { [iset d] && [iset zfh] } { include opcodes/opcodes-rv32d-zfh }
    if { [iset q] && [iset zfh] } { include opcodes/opcodes-rv32q-zfh }

    if { [dict get $::iset rlen] == 64 } {
        include opcodes/opcodes-rv64i                       ; # Always.

        if { [iset m] } { include opcodes/opcodes-rv64m }
        if { [iset a] } { include opcodes/opcodes-rv64a }
        if { [iset f] } { include opcodes/opcodes-rv64f }
        if { [iset d] } { include opcodes/opcodes-rv64d }
        if { [iset q] } { include opcodes/opcodes-rv64q }
        if { [iset c] } { include opcodes/opcodes-rv64c }

        if { [iset f] && [iset zfh] } { include opcodes/opcodes-rv64f-zfh }
    }
    if { [iset c] && [iset d]   } { include opcodes/opcodes-rvdc }


    if { [iset zicsr] }    { include opcodes/opcodes-zicsr      }
    if { [iset zifencei] } { include opcodes/opcodes-zifencei   }

    foreach extn [dict keys $::iset x*] {
        include extension/opcodes-$extn
    }

    include macros.rva

    if { $showtable } {
        print [table justify $::optable]
        exit
    }
    if { $showalias } {
        print $::alias
        exit
    }
    if { $execute eq yes } {
        set ::unalias no
        execut_init
        decode_init
        execute $verbose {*}$files
        exit
    }
    if { $::disassemble ne no } {
        decode_init
        disassemble {*}$files
        exit
    }

    foreach file $files {
        if { $file eq "-" } {
            eval [read stdin]
        } else {
            source $file
        }
    }
}

main {*}$argv
