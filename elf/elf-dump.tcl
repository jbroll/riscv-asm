#!/usr/bin/env tclkit8.6
#
set root [file dirname [file normalize [info script]]]
source $root/elf.tcl

proc dump { args } {
    set e [elf::elf create e [lindex $args 0]]

    set header [$e header]
    dict with header {
        print [subst {
        $args : $ei_class $ei_data v$ei_version type $e_type
            $e_machine
            Entry: [format 0x%08X $e_entry]
            phoff: [format 0x%08X $e_phoff] phentsize: [format %4d $e_phentsize] phnum: [format %4d $e_phnum]  ehsize: $e_ehsize flags: $e_flags
            shoff: [format 0x%08X $e_shoff] shentsize: [format %4d $e_shentsize] shnum: [format %4d $e_shnum] strindx: $e_shstrndx
        }]
    }
    print [table justify [$e get sections]]
    print
    print [table justify [$e get segments]]
    print
    print [table justify [$e get .dynsym]]
    print
    print [table justify [$e get .dynamic]]
    print
    print [table justify [$e get .rela.plt]]
    print
    print [table justify [$e get .symtab]]
    print 
}

dump {*}$argv
