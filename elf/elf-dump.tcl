#!/usr/bin/env tclkit8.6
#
source elf.tcl

set e [elf::elf create e [lindex $argv 0]]

set header [e header]
dict with header {
    print [subst {
    $argv : $ei_class $ei_data v$ei_version type $e_type
        Entry: [format %8X $e_entry]
        phoff [format %8X $e_phoff] phentsize [format %4d $e_phentsize] phnum [format %4d $e_phnum] ehsize  $e_ehsize flags $e_flags
        shoff [format %8X $e_shoff] shentsize [format %4d $e_shentsize] shnum [format %4d $e_shnum] strindx $e_shstrndx
    }]
}
print
print [table justify [$e sections]]
print
print [table justify [$e programs]]
print
print [table justify [$e symbols]]
