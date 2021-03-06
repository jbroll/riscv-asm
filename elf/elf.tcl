
package require Tcl 8.6
package require jbr::dict
package require jbr::enum
package require jbr::func
package require jbr::list
package require jbr::pipe
package require jbr::print
package require jbr::table
package require jbr::with

proc % { body } {
    string map { % $ } [uplevel subst -nocommands [list $body]] 
}

namespace eval ::elf {
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

    enum create CPU_TYPE [concat {*}[map { v s } {  
                             0x00 None        0x01 WE32100     0x02 SPARC       0x03 x86
                             0x04 M68k        0x05 M88k        0x06 IMCU        0x07 IA-80860
                             0x08 MIPS        0x09 IBM370      0x0A RS3000      0x0E PA-RISC
                             0x13 IA-80960    0x14 PowerPC     0x15 PowerPC64   0x16 S390
                             0x28 ARM7        0x2A SuperH      0x32 IA-64       0x3E amd64
                             0x8C TMS320C6000 0xB7 ARM8        0xF3 RISC-V      0xF7 BPF
                            0x101 WDC65C816
    } { concat [expr { $v }] $s }]]

    enum create DT_TAG [concat {*}[map { v s } {  
        0          DT_NULL		1  DT_NEEDED	2  DT_PLTRELSZ	3  DT_PLTGOT	
        4          DT_HASH		5  DT_STRTAB	6  DT_SYMTAB	7  DT_RELA		
        8          DT_RELASZ	9  DT_RELAENT	10 DT_STRSZ	    11 DT_SYMENT	
        12         DT_INIT		13 DT_FINI		14 DT_SONAME	15 DT_RPATH 	
        16         DT_SYMBOLIC	17 DT_REL	    18 DT_RELSZ	    19 DT_RELENT	
        20         DT_PLTREL	21 DT_DEBUG	    22 DT_TEXTREL	23 DT_JMPREL	
        32         DT_ENCODING			
        0x6ffffd00 DT_VALRNGLO	0x6ffffdff DT_VALRNGHI	0x6ffffe00 DT_ADDRRNGLO 0x6ffffeff DT_ADDRRNGHI
        0x6ffffff0 DT_VERSYM	0x6ffffff9 DT_RELACOUNT 0x6ffffffa DT_RELCOUNT	0x6ffffffb DT_FLAGS_1	
        0x6ffffffc DT_VERDEF	0x6ffffffd DT_VERDEFNUM 0x6ffffffe DT_VERNEED	0x6fffffff DT_VERNEEDNUM
    } { concat [expr { $v }] $s }]]
        
    
    set v_ident { elfmag0 elfmagName ei_class ei_data ei_version ei_osabi ei_abiversion ei_pad }
    set v_hdr   { e_type e_machine e_version e_entry e_phoff e_shoff e_flags e_ehsize e_phentsize e_phnum e_shentsize e_shnum e_shstrndx }
    set v_sec   { sh_name sh_type sh_flags sh_addr sh_offset sh_size sh_link sh_info sh_addralign sh_entsize }
    set v_prg   { p_type p_offset p_vaddr p_paddr p_filesz p_memsz p_flags p_align }
    set v_sym32 { st_name st_value st_size st_info st_other st_shndx }
    set v_sym64 { st_name st_info st_other st_shndx st_value st_size }
    set v_rel   { r_offset r_info }
    set v_rela  { r_offset r_info r_addend }
    set v_note  { n_name n_desc n_type }
    set v_dyn   { d_tag d_value }

    set sectionHeaders [% {
        section { { sh_index $::elf::v_sec                            } }
        segment { {  p_index $::elf::v_prg                            } }
        rel     { { r_index  $::elf::v_rel   r_sym r_type             } }
        rela    { { r_index  $::elf::v_rela  r_sym r_type             } }
        note    { { n_index  $::elf::v_note                           } }
        dynamic { { d_index  $::elf::v_dyn                            } }

        ELFCLASS32-symtab  { { st_index $::elf::v_sym32 st_shnm st_bind st_type  } }
        ELFCLASS64-symtab  { { st_index $::elf::v_sym64 st_shnm st_bind st_type  } }
    }]

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

        ELFCLASS32-ELFDATA2LSB-symtab  { size 16   names {$v_sym32} scan {iu iu iu cu cu su} }
        ELFCLASS32-ELFDATA2MSB-symtab  { size 16   names {$v_sym32} scan {Iu Iu Iu cu cu Su} }
        ELFCLASS64-ELFDATA2LSB-symtab  { size 24   names {$v_sym64} scan {iu cu cu su wu wu} }
        ELFCLASS64-ELFDATA2MSB-symtab  { size 24   names {$v_sym64} scan {Iu cu cu Su Wu Wu} }

        ELFCLASS32-ELFDATA2LSB-rel     { size  8   names {$v_rel}   scan {iu iu} }
        ELFCLASS32-ELFDATA2MSB-rel     { size  8   names {$v_rel}   scan {Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-rel     { size 16   names {$v_rel}   scan {wu wu} }
        ELFCLASS64-ELFDATA2MSB-rel     { size 16   names {$v_rel}   scan {Wu Wu} }
        ELFCLASS32-ELFDATA2LSB-rela    { size 12   names {$v_rela}  scan {iu iu iu} }
        ELFCLASS32-ELFDATA2MSB-rela    { size 12   names {$v_rela}  scan {Iu Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-rela    { size 24   names {$v_rela}  scan {wu wu wu} }
        ELFCLASS64-ELFDATA2MSB-rela    { size 24   names {$v_rela}  scan {Wu Wu Wu} }

        ELFCLASS32-ELFDATA2LSB-note    { size 16   names {$v_note}  scan {iu iu iu} }
        ELFCLASS32-ELFDATA2MSB-note    { size 16   names {$v_note}  scan {Iu Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-note    { size 24   names {$v_note}  scan {wu wu wu} }
        ELFCLASS64-ELFDATA2MSB-note    { size 24   names {$v_note}  scan {Wu Wu Wu} }
        
        ELFCLASS32-ELFDATA2LSB-dynamic { size  8   names {$v_dyn}   scan {iu iu} }
        ELFCLASS32-ELFDATA2MSB-dynamic { size  8   names {$v_dyn}   scan {Iu Iu} }
        ELFCLASS64-ELFDATA2LSB-dynamic { size 16   names {$v_dyn}   scan {wu wu} }
        ELFCLASS64-ELFDATA2MSB-dynamic { size 16   names {$v_dyn}   scan {Wu Wu} }
    }]

    set sectionTypes { symtab rel rela note dynamic }
    set sectionDecode {
        symtab {
            dict import symtab st_name st_info st_shndx
            if { $st_shndx == 0 } {
                continue
            }
            dict set symtab st_shnm [table get $S(sections) $st_shndx 1]
            dict set symtab st_bind [ST_BIND toSym [expr { $st_info >>   4 }]]
            dict set symtab st_name [my getString $S(strings) $st_name]
            dict set symtab st_type [ST_TYPE toSym [expr { $st_info &  0xf }]]
        }
        ELFCLASS32-rel    {
               set r_info [dict get $rel r_info]
               dict set rel r_sym   [expr { $r_info >> 8    }]
               dict set rel r_type  [expr { $r_info  & 0xFF }]
        }
        ELFCLASS64-rel    {
               set r_info [dict get $rel r_info]
               dict set rel r_sym   [expr { $r_info >> 32         }]
               dict set rel r_type  [expr { $r_info  & 0xFFFFFFFF }]
        }
        ELFCLASS32-rela    {
               set r_info [dict get $rela r_info]
               dict set rel r_sym   [expr { $r_info >> 8    }]
               dict set rel r_type  [expr { $r_info  & 0xFF }]
        }
        ELFCLASS64-rela    {
               set r_info [dict get $rela r_info]
               dict set rela r_sym   [expr { $r_info >> 32         }]
               dict set rela r_type  [expr { $r_info  & 0xFFFFFFFF }]
        }
        note    { }
        dynamic { 
            dict update dynamic d_tag d_tag {
                set d_tag [DT_TAG toSym $d_tag]
            }
        }
    }
}

::oo::class create ::elf::elf {

    constructor { { file {} } } {
        namespace eval [self namespace] { namespace path [list ::elf [namespace path]] }
        my variable my_class ;  set my_class ""
        my variable my_data  ;  set my_data  ""

        if { $file ne {} } {
            my readFile $file
        }
    }
    method header {} { my variable elfheader;  set elfheader}
    method get { what } { my variable S ;  set S($what) }

    method readFile {fname} {
        with file = [::open $fname rb] {
            return [my readChan $file]
        }
    }
    method readChan {chan} {
        return [my decodeData [chan read $chan]]
    }
    method decodeData {data} {
        variable S
        variable elfdata  $data
        variable position 0
        variable elfheader [my readElfHeader]
        dict with elfheader {
            my readSectionHeaders $e_shoff [expr { $e_shnum * $e_shentsize }] $e_shstrndx
            my readSegmentHeaders $e_phoff [expr { $e_phnum * $e_phentsize }] 
            set S(strings)   [my readStringTable]

            table foreachrow $S(sections) {
                set type [string range [string tolower $sh_type] 4 end]
                if { $type in $::elf::sectionTypes } {
                    my readHeaders $sh_name $type $sh_offset $sh_size n_index [my getSectionDecode $type]
                }
            }
        }
        return $elfheader
    }

    method getSectionDecode { type } {
        my variable my_class
        if { [dict exists $::elf::sectionDecode $type] } {
            return [dict get $::elf::sectionDecode $type]
        }

        dict get $::elf::sectionDecode $my_class-$type
    }
    method getSectionHeader { type } {
        my variable my_class
        if { [dict exists $::elf::sectionHeaders $type] } {
            return [dict get $::elf::sectionHeaders $type]
        }

        dict get $::elf::sectionHeaders $my_class-$type
    }

    method getHeader { item type expr } {
        variable S
        pipe {
            set S($type) |
            table row ~ item $expr |
            table rowdict ~
        }
    }
    method getSectionHeaderByName  { item } { my getHeader $item sections { $sh_name  eq $item } }
    method getSectionHeaderByIndex { item } { my getHeader $item sections { $sh_index == $item } }
    method getSegmentHeaderByIndex { item } { my getHeader $item segments {  $p_index == $item } }
    method getSymbolByName         { item } { my getHeader $item symtab  { $st_name  eq $item } }
    method getSymbolByIndex        { item } { my getHeader $item symtab  { $st_index == $item } }

    method getSectionData { header offsetName sizeName } {
        dict update header $offsetName offset $sizeName size {}
        my readDataAt $offset $size
    }
    method getSectionDataByIndex { index } { my getSectionData [my getSectionHeaderByIndex $index] sh_offset sh_size   }
    method getSegmentDataByIndex { index } { my getSectionData [my getSectionHeaderByIndex $index]  p_offset  p_filesz }
    method getSectionDataByName  { name  } { my getSectionData [my getSectionHeaderByName $name]   sh_offset sh_size   }

    method readElfHeader {} {
        set ident [my scanDataWithFormat ident]                 ; # Read the 16 byte identifier field check  for an ELF file. 
    
        dict import ident elfmag0 elfmagName ei_class ei_data
        if {$elfmag0 != 0x7f || $elfmagName ne "ELF"} {
            error "bad ELF magic number, [format %#x $elfmag0] $elfmagName"
        }

        dict update ident ei_class ei_class ei_data ei_data {
            set ei_class [::elf::EI_CLASS toSym $ei_class]
            set ei_data  [::elf::EI_DATA  toSym $ei_data]
        }

        my variable my_class my_data
        set my_class $ei_class
        set my_data  $ei_data

        set other [my scanDataWithFormat header]                ; # Convert the remainder of the header.
        dict update other e_type e_type e_version e_version e_machine e_machine {
            set e_machine [::elf::CPU_TYPE  toSym $e_machine]
            set e_type    [::elf::E_TYPE    toSym $e_type]
            set e_version [::elf::E_VERSION toSym $e_version]
        }
    
        dict merge $ident $other
    }

    method readStringsFromSection { header } {
        dict import header sh_type sh_offset sh_size

        if { $sh_type ne "SHT_STRTAB" } {
            error "expected symbol table section type of SHT_STRTAB, got $sh_type"
        }
        my readStrings $sh_offset $sh_size
    }
    method readSectionNames { sh_index } { my readStringsFromSection [my getSectionHeaderByIndex $sh_index] }
    method readStringTable  {}           { my readStringsFromSection [my getSectionHeaderByName .strtab] }

    method readHeaders { type format offset size indexName update } {
        variable S
        set S($type) [my getSectionHeader $format]
        set here [my seekData $offset]                          ; # Seek to where the section header table is located.
        set end [expr { $here + $size }]

        upvar $format header
        for { set i 0 } { $here < $end } { incr i } {                      ; # Read and convert the entire array of section headers.
            set header [my scanDataWithFormat $format]
            uplevel $update
    
            lappend S($type) [dict values [dict merge [list $indexName $i] $header]]
            set here [my tellData]
        }
    }
    method readSectionHeaders { offset size e_shstrndx } {
        my variable S
        my readHeaders sections section $offset $size sh_index {
            dict update section sh_type sh_type {
                set sh_type [SH_TYPE toSym $sh_type]
            }
        }

        set shstrings [my readSectionNames $e_shstrndx]
        set sh_nameCol [table colnum $S(sections) sh_name]
        set n 0
        table foreachrow $S(sections) {
            table set S(sections) $n $sh_nameCol [my getString $shstrings $sh_name]
            incr n
        }
    }
    method readSegmentHeaders { offset size } {
        my readHeaders segments segment $offset $size p_index {
            dict update segment p_type p_type p_flags p_flags {
                set p_type   [PR_TYPE  toSym $p_type]
                #set p_flags [P_FLAGS toSym $p_flags]
            }
        }
    }

    method readStrings { sh_offset sh_size } {
        set data [my readDataAt $sh_offset $sh_size]
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
    method tellData { } {
        my variable position
        set position
    }
    method seekData { here } {
        my variable elfdata position
        set position [expr { min(max($here, 0), [string length $elfdata]) }]
    }
    method readDataAt { offset count } {
        my seekData $offset
        my readData $count
    }
    method readData { count } {
        my variable elfdata position
    
        set end [expr {$position + $count - 1}]
        if {$end >= [string length $elfdata]} {
            error "attempt to read beyond end of ELF data"
        }
        set data [string range $elfdata $position $end]
        set position [expr {$end + 1}]
        return $data
    }
    method getScan { fmt } {
        my variable my_class my_data
        dict values [dict get $::elf::formats $my_class-$my_data-$fmt]
    }
    method scanDataWithFormat { fmt } {
        my scanData {*}[my getScan $fmt]
    }
    method scanData { size names scan } {
        my variable elfdata position

        set cvtd [binary scan $elfdata "@$position $scan" {*}$names]
        if {$cvtd != [llength $names]} {
            error "expected to scanData [llength $names] values, actually converted $cvtd"
        }
        set position [expr { min(max($position + $size, 0), [string length $elfdata]) }]

        zip $names [map name $names { set $name }]
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

