
A simple assembly language simulator

I wanted teach assembly language to intro CS students without worrying about
the details of real a CPU or dealing with long explainations of historical
baggage that plagues popular hardware.

## Registers:
 
   ip	- instruction pointer
   sp	- stack pointer
   bp	- frame pointer
   a	- 32 bit data register
   b	- 32 bit data register
   c	- 32 bit data register
   d	- 32 bit data register

## Flags:

   e - 1 if result of cmp is equal, 0 otherwise
 
## Instructions:
 
   mov
 
   add
   sub
   mul
   div
   inc
   dec
   cmp	- compare and set e (equal) flag
 
   push 
   pop
 
   jmp  - jump to address
   je   - jump if equal
   jne  - jump if not equal

   call
   ret

   print - print a regiser or immediet value
   show - print registers
   dump - print memory
 
## Address modes:
 
   immediet                    - 5
   register                    - a
   register indirect           - [a]
   register indirect + offset  - [a+4]
   memory                      - [1234]
 
## Directives:
 
 .org	- assemble here
 .mem   - define memory
 label: - define a memory label
 
