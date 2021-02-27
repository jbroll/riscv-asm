
package require Tcl 8.6
source ../jbr.tcl/with.tcl
source ../jbr.tcl/list.tcl
source ../jbr.tcl/dict.tcl
source ../jbr.tcl/func.tcl
source ../jbr.tcl/pipe.tcl
source ../jbr.tcl/enum.tcl
source ../jbr.tcl/table.tcl

proc  print { args } { puts [join $args " "] }
proc eprint { args } { puts stderr $args }
proc % { body } {
    string map { % $ } [uplevel subst -nocommands [list $body]] 
}

namespace eval ::elf {
    namespace export elffile
    namespace ensemble create

    variable version 1.0.1

    enum create EI_CLASS  { 1 ELFCLASS32     2 ELFCLASS64    } 
    enum create EI_DATA   { 1 ELFDATA2LSB    2 ELFDATA2MSB   } 
    enum create E_VERSION { 1 EV_CURRENT } 
    enum create E_TYPE    { 0 ET_NONE    1 ET_REL        2 ET_EXEC       3 ET_DYN     4 ET_CORE }
    enum create SH_TYPE   { 0 SHT_NULL   1 SHT_PROGBITS  2 SHT_SYMTAB    3 SHT_STRTAB    
                   4 SHT_RELA   5 SHT_HASH      6 SHT_DYNAMIC   7 SHT_NOTE      
                   8 SHT_NOBITS 9 SHT_REL      10 SHT_SHLIB    11 SHT_DYNSYM
    } 
    enum create PR_TYPE   { 0 PT_NULL    1 PT_LOAD   2 PT_DYNAMIC    3 PT_INTERP
                            4 PT_NOTE    5 PT_SHLIB  6 PT_PHDR
    }
    enum create SH_INDEX  { 0 SHN_UNDEF  0xfff1 SHN_ABS 0xfff2 SHN_COMMON }
    enum create ST_BIND   { 0 STB_LOCAL  1 STB_GLOBAL    2 STB_WEAK 10 STB_LOOS 12 STB_HIOS 13 STB_LOPROC 15 STB_HIPROC } 
    enum create ST_TYPE   { 0 STT_NOTYPE 1 STT_OBJECT    2 STT_FUNC  3 STT_SECTION   4 STT_FILE }


    set cpu_types [concat {*}[map { v s } {  
                             0x00 None        0x01 WE32100     0x02 SPARC       0x03 x86
                             0x04 M68k        0x05 M88k        0x06 IMCU        0x07 IA-80860
                             0x08 MIPS        0x09 IBM370      0x0A RS3000      0x0E PA-RISC
                             0x13 IA-80960    0x14 PowerPC     0x15 PowerPC64   0x16 S390
                             0x28 ARM7        0x2A SuperH      0x32 IA-64       0x3E amd64
                             0x8C TMS320C6000 0xB7 ARM8        0xF3 RISC-V      0xF7 BPF
                            0x101 WDC65C816
    } { concat [expr { $v }] $s }]]
    enum create CPU_TYPE $cpu_types
    
    set v_ident { elfmag0 elfmagName ei_class ei_data ei_version ei_osabi ei_abiversion ei_pad }
    set v_hdr   { e_type e_machine e_version e_entry e_phoff e_shoff e_flags e_ehsize e_phentsize e_phnum e_shentsize e_shnum e_shstrndx }
    set v_sec   { sh_name sh_type sh_flags sh_addr sh_offset sh_size sh_link sh_info sh_addralign sh_entsize }
    set v_prg   { p_type p_offset p_vaddr p_paddr p_filesz p_memsz p_flags p_align }
    set v_sym32 { st_name st_value st_size st_info st_other st_shndx }
    set v_sym64 { st_name st_info st_other st_shndx st_value st_size }

    set formats [% {
                             --ident   { size 16   names {$v_ident} scan {cu a3 cu cu cu cu cu cu7} }
        ELFCLASS32-ELFDATA2LSB-header  { size 36   names {$v_hdr}   scan {su su iu iu iu iu iu su su su su su su} }
        ELFCLASS32-ELFDATA2MSB-header  { size 36   names {$v_hdr}   scan {Su Su Iu Iu Iu Iu Iu Su Su Su Su Su Su} }
        ELFCLASS64-ELFDATA2LSB-header  { size 48   names {$v_hdr}   scan {su su iu wu wu wu iu su su su su su su} } 
        ELFCLASS64-ELFDATA2MSB-header  { size 48   names {$v_hdr}   scan {Su Su Iu Wu Wu Wu Iu Su Su Su Su Su Su} }
        ELFCLASS32-ELFDATA2LSB-section { size 40   names {$v_sec}   scan {iu iu iu iu iu iu iu iu iu iu} }
        ELFCLASS32-ELFDATA2MSB-section { size 40   names {$v_sec}   scan {Iu Iu Iu Iu Iu Iu Iu Iu Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-section { size 64   names {$v_sec}   scan {iu iu wu wu wu wu iu iu wu wu} }
        ELFCLASS64-ELFDATA2MSB-section { size 64   names {$v_sec}   scan {Iu Iu Wu Wu Wu Wu Iu Iu Wu Wu} }
        ELFCLASS32-ELFDATA2LSB-segment { size 32   names {$v_prg}   scan {iu iu iu iu iu iu iu iu} }
        ELFCLASS32-ELFDATA2MSB-segment { size 32   names {$v_prg}   scan {Iu Iu Iu Iu Iu Iu Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-segment { size 56   names {$v_prg}   scan {iu iu wu wu wu wu wu wu} }
        ELFCLASS64-ELFDATA2MSB-segment { size 56   names {$v_prg}   scan {Iu Iu Wu Wu Wu Wu Wu Wu} }
        ELFCLASS32-ELFDATA2LSB-symbol  { size 16   names {$v_sym32} scan {iu iu iu cu cu su} }
        ELFCLASS32-ELFDATA2MSB-symbol  { size 16   names {$v_sym32} scan {Iu Iu Iu cu cu Su} }
        ELFCLASS64-ELFDATA2LSB-symbol  { size 24   names {$v_sym64} scan {iu cu cu su wu wu} }
        ELFCLASS64-ELFDATA2MSB-symbol  { size 24   names {$v_sym64} scan {Iu cu cu Su Wu Wu} }
    }]
}

::oo::class create ::elf::elf {

    constructor { { file {} } } {
        my variable elfdata position
        my variable v_sec v_prg v_sym32
        my variable sections ;  set sections [list [list sh_index {*}$::elf::v_sec]]
        my variable segments ;  set segments [list [list  p_index {*}$::elf::v_prg]]
        my variable symbols  ;  set symbols  [list [list st_index {*}$::elf::v_sym32 st_shnm st_bind st_type]]
        my variable my_class ;  set my_class ""
        my variable my_data  ;  set my_data  ""

        if { $file ne {} } {
            my readFile $file
        }
    }
    method sections {} { my variable sections ;  set sections }
    method segments {} { my variable segments ;  set segments }
    method symbols  {} { my variable symbols  ;  set symbols  }
    method header   {} { my variable elfheader;  set elfheader}

    method readFile {fname} {
        with file = [::open $fname rb] {
            return [my readChan $file]
        }
    }
    method readChan {chan} {
        return [my decodeData [chan read $chan]]
    }
    method decodeData {data} {
        variable elfdata  $data
        variable position 0
        variable elfheader [my readElfHeader]
        dict with elfheader {
            my readSecHeaders  $e_shoff $e_shnum $e_shentsize $e_shstrndx
            my readSegHeaders $e_phoff $e_phnum $e_phentsize
            my readSymTable
        }
        return $elfheader
    }
    method getSectionHeaderByName {name} {
        variable sections
        pipe {
            set sections |
            table row ~ name {$sh_name eq $name} |
            table todict ~
        }
    }
    method getSectionHeaderByIndex {index} {
        variable sections
        pipe {
            set sections |
            table row ~ index { $sh_index == $index } |
            table todict ~
        }
    }
    method getSectionDataByIndex {index} {
        set header [my getSectionHeaderByIndex $index]
        dict import header sh_offset sh_size
        my Read $sh_offset $sh_size
    }
    method getSectionDataByName {name} {
        set headers [my getSectionHeaderByName $name]
        if {[llength $headers] eq {}} {
            error "cannot find unique section named, \"$name\""
        }
        set header [lindex $headers 0]
        dict import header sh_offset sh_size
        my Read $sh_offset $sh_size
    }
    method getSymbolByName {name} {
        variable symbols
        pipe { set $symbols
            table row ~ name {$st_name eq $name} |
            table todict ~
        }
    }
    method readElfHeader {} {
        # Read the 16 byte identifier field and make sure we are dealing with an ELF file. 
        #
        set ident [my scanData ident]
    
        dict with ident {
            if {$elfmag0 != 0x7f || $elfmagName ne "ELF"} {
                error "bad ELF magic number, [format %#x $elfmag0] $elfmagName"
            }
        }
        dict update ident ei_class ei_class ei_data ei_data {
            set ei_class [::elf::EI_CLASS toSym $ei_class]
            set ei_data  [::elf::EI_DATA  toSym $ei_data]
        }

        my variable my_class my_data
        set my_class $ei_class
        set my_data  $ei_data
    
        set other [my scanData header]                       ; # Convert the remainder of the header.
        dict update other e_type e_type e_version e_version {
            set e_type    [::elf::E_TYPE    toSym $e_type]
            set e_version [::elf::E_VERSION toSym $e_version]
        }
    
        dict merge $ident $other
    }

    method readSectionNames { e_shstrndx } {
        set shstrsec [my getSectionHeaderByIndex $e_shstrndx]
        if { $shstrsec eq {} } {
            error "no section name strings"
        }
        dict import shstrsec sh_type sh_offset sh_size

        if { $sh_type ne "SHT_STRTAB" } {
            error "section name string not of type SHT_STRTAB"
        }

        my readStrings $sh_offset $sh_size
    }
    method readSecHeaders {e_shoff e_shnum e_shentsize e_shstrndx} {
        variable sections
        if {$e_shnum == 0} {
            return
        }
        my seekData $e_shoff                                   ; # Seek to where the section header table is located.
    
        for {set secNo 0} {$secNo < $e_shnum} {incr secNo} {   ; # Read and convert the entire array of section headers.
            set sec_hdr [my scanData section]
            dict update sec_hdr sh_type sh_type {
                set sh_type [::elf::SH_TYPE toSym $sh_type]
            }
    
            lappend sections [dict values [dict merge [list sh_index $secNo] $sec_hdr]]
        }

        set shstrings [my readSectionNames $e_shstrndx]
        set sh_name [table colnum $sections sh_name]
        for {set secNo 0} {$secNo < $e_shnum} {incr secNo} {   ; # Set the section string names
            set offset [table get $sections $secNo $sh_name]
            table set sections $secNo $sh_name [my getString $shstrings $offset]
        }
    }
    method readSegHeaders {e_phoff e_phnum e_phentsize} {
        variable segments
        my seekData $e_phoff                                   ; # Seek to where the section header table is
    
        for {set segNo 0} {$segNo < $e_phnum} {incr segNo} {
            set seg_hdr [my scanData segment]
            dict update seg_hdr p_type p_type p_flags p_flags {
                set p_type  [::elf::PR_TYPE  toSym $p_type]
                #set p_flags [::elf::P_FLAGS toSym $p_flags]
            }

            lappend segments [dict values [dict merge [list p_index $segNo] $seg_hdr]]
        }
    }
    method readStrings {sh_offset sh_size} {
        set data [my readData $sh_offset $sh_size]
        set strOff 0
        set strings { 0 {} }
        foreach s [split $data "\0"] {           ; # The strings are just packed NUL terminated ASCII strings.
                                                 ; # Just split on the NUL character to unbundle the them.
            if {[string length $s] != 0} {
                dict set strings $strOff $s
            }
            incr strOff [expr {[string length $s] + 1}]
        }
    
        return $strings
    }
    method getString { strings offset } {
        catch { return [dict get $strings $offset] } 

        # Not all the requested indicies are at the start of a string table entry.
        #
        foreach {pos value} $strings {
            if { $pos > $offset } { break }
            set string $value
            set index  $pos
        }

        string range $string [expr { $offset - $index }] end
    }
    method readStringTable {} {
        set strheader [my getSectionHeaderByName .strtab]
        dict import strheader sh_type sh_offset sh_size

        if {$sh_type ne "SHT_STRTAB"} {
            error "expected symbol table section type of SHT_STRTAB, got $sh_type"
        }
        my readStrings $sh_offset $sh_size
    }

    method readSymTable {} {
        my variable sections symbols 
        set strings [my readStringTable]

        set symheader [my getSectionHeaderByName .symtab]

        dict with symheader {
            if {$sh_type ne "SHT_SYMTAB"} {
                error "expected symbol table section type of SHT_SYMTAB, got $sh_type\
            }
            my seekData $sh_offset
            set nSyms [expr {$sh_size / $sh_entsize}]

            for {set symindex 0} {$symindex < $nSyms} {incr symindex} {
                set sym [dict merge [list st_index $symindex] [my scanData symbol]]

                dict import sym st_name st_info st_shndx
                if { $st_shndx == 0 } {
                    continue
                }
                dict set sym st_name [my getString $strings $st_name]
                dict set sym st_shnm [table get $sections $st_shndx 1]
                dict set sym st_bind [::elf::ST_BIND toSym [expr { $st_info >>   4 }]]
                dict set sym st_type [::elf::ST_TYPE toSym [expr { $st_info &  0xf }]]
    
                lappend symbols [dict values $sym]
            }
        }
    }
    method seekData { here } {
        my variable elfdata position
        set position [expr { min(max($here, 0), [string length $elfdata]) }]
    }
    method readData {offset count} {
        my variable elfdata position
    
        my seekData $offset
        set end [expr {$position + $count - 1}]
        if {$end >= [string length $elfdata]} {
            error "attempt to read beyond end of ELF data"
        }
        set data [string range $elfdata $position $end]
        set position [expr {$end + 1}]
        return $data
    }
    method getScan { fmt args } {
        my variable my_class my_data
        dict get $::elf::formats $my_class-$my_data-$fmt {*}$args
    }
    method scanData { fmt } {
        my variable elfdata position

        set names  [my getScan $fmt names]
        set format [my getScan $fmt scan]
        set size   [my getScan $fmt size]

        set cvtd [binary scan $elfdata "@$position $format" {*}$names]
        if {$cvtd != [llength $names]} {
            error "expected to scanData [llength $names] values, actually converted $cvtd"
        }
        set position [expr { min(max($position + $size, 0), [string length $elfdata]) }]

        return [zip $names [map name $names { set $name }]]
    }

    set et_range { ET_LOOS { 0xfe00 0xfeff } ET_LOPROC { 0xff00 0xffff } }
    set sh_range { SHT_LOOS { 0x60000000 0x6fffffff } SHT_LOPROC { 0x70000000 0x7fffffff } }
                
    set si_range { SHN_LOPROC { 0xff00 0xff1f } SHT_LOOS { 0xff20 0xff3f } }
    set pr_range { PT_LOOS { 0x60000000 0x6fffffff } PT_LOPROC { 0x70000000 0x7fffffff } }
    set sb_range { STB_LOOS { 10 12 } STB_LOPROC { 13 15 } }
    set st_range { STB_LOOS { 10 12 } STB_LOPROC { 13 15 } }

    set sh_flags { SHF_WRITE    1  SHF_ALLOC 2     SHF_EXECINST 4 SHF_MASKPROC 28:4     }
    set p_flags  { PF_X 1   PF_W 2  PF_R 4         PF_MASKOS 12:8 PF_MASKPROC  28:4     }
}

package provide elf $::elf::version

