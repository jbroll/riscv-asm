#!/usr/bin/env tclkit8.6
#
source elf.tcl

set e [elf::elf create e [lindex $argv 0]]

print $argv
print [join [$e header] \n]
print
print [table justify [$e sections]]
print
print [table justify [$e segments]]
print
print [table justify [$e symbols]]
