;================================================
; klib.asm 内核库函数
;================================================


global	memcpy
global	println
global	printmsg
global	itoa

[SECTION .data]
PrintPos	dd	(80 * 6 + 0) * 2	; println 显示字符串的地址 (初始值: 6 行 0 列)


[SECTION .text]

;-------------------------------------------------------------------------------
; memcpy(es:pDst, ds:pSrc, len)
;-------------------------------------------------------------------------------
memcpy:
	push	ebp
	mov	ebp, esp

	push	edi
	push	esi
	push	ecx

	mov	edi, [ebp+8]	; pDst
	mov	esi, [ebp+12]	; pSrc
	mov	ecx, [ebp+16]	; len
.1:
	mov	al, [ds:esi]
	mov	[es:edi], al
	inc	esi
	inc	edi
	loop	.1

	pop	ecx
	pop	esi
	pop	edi
	pop	ebp
	ret
;-------------------------------------------------------------------------------


[SECTION .text]
;-------------------------------------------------------------------------------
; void println(char* sz)
; 字符串 sz 的段选择器默认使用 ds
;-------------------------------------------------------------------------------
println:
	push	ebp
	mov	ebp, esp

	push	edi
	push	esi

	mov	esi, [ebp + 8]			; sz　字符串地址
	mov	edi, dword [PrintPos]
	mov	ah, 07h				; 0000 黑底, 0111 灰字
.printc:
	mov	al, [esi]
	cmp	al, 0
	jz	.end	
	cmp	al, 0Ah				; 是 '\n' 则回车换行
	jnz	.1
	add	edi, 160
	jmp	.2
.1:
	mov	[gs:edi], ax
	add	edi, 2
.2:
	inc	esi
	jmp	.printc
.end:
	add	dword [PrintPos], 160	; 下次打印时另起一行
	pop	esi
	pop	edi
	pop	ebp
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; void printmsg(char* sz, u8 color, u32 pos)
; 字符串 sz 的段选择器默认使用 ds
;-------------------------------------------------------------------------------
printmsg:
	push	ebp
	mov	ebp, esp

	push	edi
	push	esi

	mov	esi, [ebp + 8]			; sz　字符串地址
	mov	ah, byte [ebp + 12]		; color
	mov	edi, [ebp + 16]			; pos
.printc:
	mov	al, [esi]
	cmp	al, 0
	jz	.end	
	cmp	al, 0Ah				; 是 '\n' 则回车换行
	jnz	.1
	add	edi, 160
	jmp	.2
.1:
	mov	[gs:edi], ax
	add	edi, 2
.2:
	inc	esi
	jmp	.printc
.end:
	pop	esi
	pop	edi
	pop	ebp
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; void itoa(char* str, int v, int len, u8 flag)
; flag: 是否在 str 末尾添加 '\0'
; 例:
; char str[4 + 1];
; itoa(str, 0x1234, 4); // 便可从 str 取得字符串 "1234"
;-------------------------------------------------------------------------------
itoa:
	push	ebp
	mov	ebp, esp

	push	ecx
	push	esi

	mov	edx, [ebp + 16]		; len
	mov	eax, [ebp + 12]		; v
	mov	ebx, eax
	mov	esi, [ebp + 8]		; str
	add	esi, edx		; esi <- &str[len]
	mov	cl, [ebp + 20]		; flag
	cmp	cl, 0
	jz	.false
	mov	byte [esi], 0		; '\0'
.false:
	dec	esi
	mov	cl, 0
.loop:
	shr	eax, cl
	and	al, 0Fh
	cmp	al, 9
	jg	.1
	add	al, '0'
	jmp	.2
.1:
	sub	al, 0Ah
	add	al, 'A'
.2:
	mov	[esi], al
	dec	esi
	add	cl, 4
	mov	eax, ebx
	dec	edx
	jnz	.loop

	pop	esi
	pop	ecx
	pop	ebp
	ret
;-------------------------------------------------------------------------------






















;-------------------------------------------------------------------------------
