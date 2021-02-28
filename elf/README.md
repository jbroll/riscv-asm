
This is a pure Tcl rewrite of 
[elfdecode](http://repos.modelrealization.com/cgi-bin/fossil/mrtools/wiki?name=ELF+decode)
originally written by G. Andrew Mangogna.o

<pre><code>
./elf-dump test/hello-rv64

    test/hello-rv64 : ELFCLASS64 ELFDATA2LSB v1 type ET_EXEC
        RISC-V
        Entry: 0x000103A0
        phoff: 0x00000040 phentsize:   56 phnum:    8  ehsize: 64 flags: 5
        shoff: 0x000018C8 shentsize:   64 shnum:   26 strindx: 25
    

sh_index        sh_name      sh_type sh_flags sh_addr sh_offset sh_size sh_link sh_info sh_addralign sh_entsize
       0                    SHT_NULL        0       0         0       0       0       0            0          0
       1        .interp SHT_PROGBITS        2   66048       512      33       0       0            1          0
       2  .note.ABI-tag     SHT_NOTE        2   66084       548      32       0       0            4          0
       ...
       ...
      22       .comment SHT_PROGBITS       48       0      4152      61       0       0            1          1
      23        .symtab   SHT_SYMTAB        0       0      4216    1416      24      44            8         24
      24        .strtab   SHT_STRTAB        0       0      5632     486       0       0            1          0
      25      .shstrtab   SHT_STRTAB        0       0      6118     225       0       0            1          0

p_index     p_type p_offset p_vaddr p_paddr p_filesz p_memsz p_flags p_align
      0    PT_PHDR        4      64   65600    65600     448     448       8
      1  PT_INTERP        4     512   66048    66048      33      33       1
      2    PT_LOAD        5       0   65536    65536    1300    1300    4096
      3    PT_LOAD        6    3592   73224    73224     560     568    4096
      ...

st_index                                st_name st_value st_size st_info st_other st_shndx        st_shnm    st_bind     st_type
      ...
      23                                 init.c        4       0   65521        0        0                 STB_LOCAL    STT_FILE
      24                         static-reloc.c        4       0   65521        0        0                 STB_LOCAL    STT_FILE
      25                             crtstuff.c        4       0   65521        0        0                 STB_LOCAL    STT_FILE
      26                   deregister_tm_clones        2       0      11    66518        0          .text  STB_LOCAL    STT_FUNC
      27                     register_tm_clones        2       0      11    66554        0          .text  STB_LOCAL    STT_FUNC
      28                  __do_global_dtors_aux        2       0      11    66598        0          .text  STB_LOCAL    STT_FUNC
      29                         completed.5836        1       0      21    73784        1           .bss  STB_LOCAL  STT_OBJECT
      ...
</pre></code>


<pre><code>
./elf-dump test/hello-rv64

    test/hello-i586 : ELFCLASS32 ELFDATA2LSB v1 type ET_DYN
        x86
        Entry: 0x00001068
        phoff: 0x00000034 phentsize:   32 phnum:   10  ehsize: 52 flags: 0
        shoff: 0x00004244 shentsize:   40 shnum:   33 strindx: 32
    

sh_index        sh_name      sh_type sh_flags sh_addr sh_offset sh_size sh_link sh_info sh_addralign sh_entsize
       0                    SHT_NULL        0       0         0       0       0       0            0          0
       1        .interp SHT_PROGBITS        2     372       372      23       0       0            1          0
       2      .gnu.hash   1879048182        2     396       396      36       3       0            4          4
       3        .dynsym   SHT_DYNSYM        2     432       432     160       4       1            4         16
      ...
      ...
      30        .symtab   SHT_SYMTAB        0       0     14960    1152      31      51            4         16
      31        .strtab   SHT_STRTAB        0       0     16112     569       0       0            1          0
      32      .shstrtab   SHT_STRTAB        0       0     16681     283       0       0            1          0

p_index     p_type p_offset p_vaddr p_paddr p_filesz p_memsz p_flags p_align
      0    PT_PHDR       52      52      52      320     320       4       4
      1  PT_INTERP      372     372     372       23      23       4       1
      2    PT_LOAD        0       0       0      864     864       4    4096
      3    PT_LOAD     4096    4096    4096      644     644       5    4096
      ...

st_index               st_name   st_value    st_size st_info st_other st_shndx        st_shnm    st_bind     st_type
       1                              372          0       3        0        1        .interp  STB_LOCAL STT_SECTION
       2                              396          0       3        0        2      .gnu.hash  STB_LOCAL STT_SECTION
      ...
      ...
      30               Scrt1.c          0          0       4        0    65521                 STB_LOCAL    STT_FILE
      31            crtstuff.c          0          0       4        0    65521                 STB_LOCAL    STT_FILE
      32         __CTOR_LIST__      16124          0       1        0       15         .ctors  STB_LOCAL  STT_OBJECT
      33         __DTOR_LIST__      16132          0       1        0       16         .dtors  STB_LOCAL  STT_OBJECT
      34    __EH_FRAME_BEGIN__       8320          0       1        0       14      .eh_frame  STB_LOCAL  STT_OBJECT
      35  deregister_tm_clones       4286          0       2        0       10          .text  STB_LOCAL    STT_FUNC
      36    register_tm_clones       4337          0       2        0       10          .text  STB_LOCAL    STT_FUNC
      37 __do_global_dtors_aux       4408          0       2        0       10          .text  STB_LOCAL    STT_FUNC
      38        completed.5807      16388          1       1        0       20           .bss  STB_LOCAL  STT_OBJECT
      39         dtor_idx.5809      16392          4       1        0       20           .bss  STB_LOCAL  STT_OBJECT
      40           frame_dummy       4550          0       2        0       10          .text  STB_LOCAL    STT_FUNC
</pre></code>
