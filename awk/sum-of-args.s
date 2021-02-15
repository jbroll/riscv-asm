	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 10, 15	sdk_version 10, 15, 4
	.intel_syntax noprefix
	.globl	_main                   ## -- Begin function main
	.p2align	4, 0x90
_main:                                  ## @main
## %bb.0:
	push	rbp
	mov	rbp, rsp
	push	r15
	push	r14
	push	r12
	push	rbx
	test	edi, edi
	jle	LBB0_1
## %bb.3:
	mov	r14, rsi
	mov	r15d, edi
	xor	ebx, ebx
	xor	r12d, r12d
	.p2align	4, 0x90
LBB0_4:                                 ## =>This Inner Loop Header: Depth=1
	mov	rdi, qword ptr [r14 + 8*rbx]
	call	_atoi
	add	r12d, eax
	inc	rbx
	cmp	r15, rbx
	jne	LBB0_4
	jmp	LBB0_2
LBB0_1:
	xor	r12d, r12d
LBB0_2:
	lea	rdi, [rip + L_.str]
	mov	esi, r12d
	xor	eax, eax
	call	_printf
	xor	eax, eax
	pop	rbx
	pop	r12
	pop	r14
	pop	r15
	pop	rbp
	ret
                                        ## -- End function
	.section	__TEXT,__cstring,cstring_literals
L_.str:                                 ## @.str
	.asciz	"%d\n"


.subsections_via_symbols
