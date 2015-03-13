.model tiny

;#make_bin#

;#LOAD_SEGMENT=0FFFFh#
;#LOAD_OFFSET=0000h#

;#CS=0000h#
;#IP=0000h#

;#DS=0000h#
;#ES=0000h#

;#SS=0000h#
;#SP=0FFFEh#
;#AX=0000h#
;#BX=0000h#
;#CX=0000h#
;#DX=0000h#
;#SI=0000h#
;#DI=0000h#
;#BP=0000h#


.data

porta equ 00h 	;8255(1) 
portb equ 02h
portc equ 04h
creg  equ 06h
cnt0  equ 08h ;8254 
cnt1  equ 0Ah
cnt2  equ 0Ch
cregt equ 0Eh
add1  equ 10h ;8259(1)
add2  equ 12h ;8259- two addresses
ireg  equ 18h ;LCD - 3 addresses.
streg  equ 1Ah
dreg  equ 1Ch


MODE 		EQU 	1D1DH
TRANS 		EQU		1E1DH
PROGRAM		EQU		0F1EH
YES			EQU		0F1BH
NO			EQU		171BH
ZERO		EQU		1E17H
ONE			EQU		0F0FH
TWO			EQU		170FH
THREE		EQU		1B0FH
FOUR		EQU		1D0FH
FIVE		EQU		1E0FH
SIX			EQU		0F17H
SEVEN		EQU		1717H
EIGHT		EQU		1B17H
NINE		EQU		1D17H
ENT			EQU		1B1BH
BACKSPACE	EQU		1D1BH
CANCEL		EQU		1E1BH
ITMNO		EQU		0F1DH
QUANTITY	EQU		171DH
TOTAL		EQU		1B1DH
ADDITM		EQU		171EH
DELITEM		EQU		1B1EH
COST		EQU		1D1EH




TABLE_P 	DW 256 DUP(?)

;MESSAGES
MODE2		DB	'ENTER MODE',00h
READY		DB	'SYSTEM READY',00h
CONF		DB	'CONFIRM Y/N ?',00h
ITEMNO		DB	'ITEM NO. ?',00h
NOITEM		DB	'NO ITEM FOUND',00h
QUANTITY2	DB	'ENTER QUANTITY',00h
INVALID		DB	'INVALID KEY',00h
NOSLOT		DB	'NO SLOT',00h
ENT_COST	DB	'ENTER COST',00h
ITEM_SAVED	DB	'ITEM SAVED',00h
NOSLOT2		DB	'NO ITEM IN SLOT',00h
ITEM_DEL	DB	'ITEM DELETED',00h

SUBTOT	DW	'0',00h
TOTAL2	DW	'0',00h
ITMNO2	DW	'0',00h
QUANT	DW	'0',00h


       




.code
.startup

;initialise





; add your code here
         jmp     st12 
  
		 db     509 dup(0)

;IVT entry for 80H
         
        dw     unlock_isr
        dw     0000
		dw		lock_isr
		dw		0000
        db     508 dup(0)
		 
;main program
          
st12:      cli 
; intialize ds, es,ss to start of RAM
          mov       ax,0200h
          mov       ds,ax
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH
;intialise portb as input &portc as output
          mov       al,10000011b
		  out 		creg,al 


mov al,00010011b
	out add1,al
	mov al,80h
	out add2,al
	mov al,03h
	out add2,al
	mov al,0FCh
	out add2,al
	sti


;lock

b0:	mov  al,00h
	out  porta,al
b1:	in   al,portb
    and  al,1fh
	cmp  al,1fh
	jnz  b1
	mov  cx,20
	call delay
    mov  al,00h
	out  porta,al
b2:	in   al,portb
	and  al,1fh
	cmp  al,1fh
	jz   b2
	mov  cx,20
	call delay
        mov  al,00h
	out  porta,al
	in   al,portb
	and  al,1fh
	cmp  al,1fh
	jz   b2

buzzer: mov al,00110110b
	out cregt,al
	mov al,01110110b
	out cregt,al
	mov al,10110110b
	out cregt,al
	mov al,02h
	out cnt0,al
	mov	al,00h
	out cnt0,al
	mov al,0Fh
	out cnt1,al
	mov al,00h
	out cnt1,al
	mov al,60h
	out cnt2,al
	mov al,0EAh
	out cnt2,al




;lock code ends

X1:
LEA		SI,READY
CALL	LCD
call	KEYBOARD
CMP		AX,MODE
JNZ		X1

X2:
LEA		SI,MODE2
CALL	LCD
CALL	KEYBOARD
CMP		AX,TRANS
JZ		TRANSAC
CMP		AX,PROGRAM
JZ		PROG




TRANSAC:
LEA		SI,CONF
CALL	LCD
CALL	KEYBOARD
CMP		AX,NO
JZ		X2
CMP		AX,YES
JZ		ITEM
JNZ		TRANSAC

ITEM:
LEA		SI,ITEMNO
CALL	LCD
CALL	KEYBOARD

MOV		DI,00H
X4:
CMP		DI,0100H
JZ		NOITEM2
MOV		SI,AX
MOV		CX,00H
CMP		CX,TABLE_P[SI]
INC		DI
JNZ		X3
JZ		X4

NOITEM2:
LEA		SI,NOITEM
CALL	LCD
JMP		ITEM


X3:
DEC		DI
LEA		SI,QUANTITY2
CALL	LCD
CALL	KEYBOARD
MOV		QUANT,AX
MOV		CX,TABLE_P[DI]
MUL		CX
ADD		SUBTOT,CX
MOV		CX,0
CALL	KEYBOARD
CMP		AX,TOTAL
JMP		TOTAL_PRICE
CMP		AX,ADDITM
JMP		ITEM
LEA		SI,INVALID
CALL	LCD





TOTAL_PRICE:
MOV		BX,SUBTOT
MOV		CX,TOTAL2
ADD		CX,BX
MOV		TOTAL2,CX
LEA		SI,TOTAL2
CALL	LCD
CALL	KEYBOARD
CMP		AX,MODE
JMP		X2




PROG:
LEA		SI,CONF
CALL	LCD
CALL	KEYBOARD
CMP		AX,NO
JZ		X2
CMP		AX,YES
JZ		PROG_2
JNZ		PROG

PROG_2:
CALL	KEYBOARD
CMP		AX,ITMNO
JMP		PROG_ITEM
CMP		AX,DELITEM
JMP		DEL_ITEM
LEA		SI,INVALID
CALL	LCD
JMP		PROG

PROG_ITEM:

LEA		SI,ITEMNO
CALL	LCD
CALL	KEYBOARD

MOV		DI,00H

SLOT:
CMP		DI,0100H
JZ		NO_SLOT
MOV		SI,AX
MOV		CX,0000H
CMP		CX,TABLE_P[SI]
INC		DI
JNZ		SET_COST
JZ		SLOT




SET_COST:
LEA		SI,ENT_COST
CALL	LCD
CALL	KEYBOARD
MOV		CX,AX
LEA		SI,CONF
CALL	LCD
CALL	KEYBOARD
CMP		AX,YES
JNZ		X2
DEC		DI
MOV		TABLE_P[DI],CX
LEA		SI,ITEM_SAVED
CALL	LCD
JMP		X2




NO_SLOT:
LEA		SI,NOSLOT
CALL	LCD
JMP		PROG_ITEM

NO_SLOT2:
LEA		SI,NOSLOT2
CALL	LCD
JMP		PROG_ITEM


DEL_ITEM:

LEA		SI,ITEMNO
CALL	LCD
CALL	KEYBOARD

MOV		DI,00H

DEL_SLOT:
CMP		DI,0100H
JZ		NO_SLOT2
MOV		BX,TABLE_P[SI]
MOV		CX,0000H
CMP		CX,BX
INC		DI
JNZ		DL_ITEM
JZ		DEL_SLOT


DL_ITEM:
LEA		SI,CONF
CALL	LCD
CALL	KEYBOARD
CMP		AX,YES
JNZ		X2
DEC		DI
MOV		TABLE_P[DI],0
LEA		SI,ITEM_DEL
CALL	LCD
JMP		X2



KEYBOARD PROC NEAR	
	
k0:	mov  al,00h
	out  porta,al
k1:	in   al,portb
        and  al,1fh
	cmp  al,1fh
	jnz  k1
	mov  cx,20
	call delay
        mov  al,00h
	out  porta,al
k2:	in   al,portb
	and  al,1fh
	cmp  al,1fh
	jz   k2
	mov  cx,20
	call delay
        mov  al,00h
	out  porta,al
	in   al,portb
	and  al,1fh
	cmp  al,1fh
	jz   k2
	
	mov  al,0fh
	mov  bl,al
	out  portb,al
	in   al,porta
	and  al,1fh
	cmp  al,1fh
	jnz  k3
	mov  al,17h
	mov  bl,al
	out  portb,al
	in   al,porta
	and  al,1fh
	cmp  al,1fh
	jnz  k3
	mov  al,1bh
	mov  bl,al
	out  portb,al
	in   al,porta
	and  al,1fh
	cmp  al,1fh
	jnz  k3
	mov  al,1dh
	mov  bl,al
	out  portb,al
	in   al,porta
	and  al,1fh
	cmp  al,1fh
	jnz  k3
	mov  al,1eh
	mov  bl,al
	out  portb,al
	in   al,porta
	and  al,1fh
	cmp  al,1fh
	jnz  k3
	k3:
	mov  ah,bl
	ret
KEYBOARD ENDP	





LCD proc near
	mov  al,10000011b
	out  creg,al
	call allclr
	call ret_home	
	call string
	ret
	LCD endp

allclr proc near
	 
	 mov ah,00000001b
out1 :  
	push ax
    push dx
	call busy
	mov  al,ah
	mov  dx,ireg
	out  dx,al
	pop  dx
	pop  ax
	ret
	allclr endp

busy proc near
	push dx
	push ax	
	mov  dx,streg

	busy1:	
	in   al,streg
	and  al,10000000b
	jnz  busy1
	pop  ax
	pop  dx
	ret
busy endp

charout proc near
	 push dx
	 push ax
	 call busy
	 mov  al,ah
	 mov  dx,dreg
	 out  dx,al
	 pop  ax
	 pop  dx
	 ret
charout endp

string proc near
chk:	 
	mov ah,[si]
	cmp ah,00h
	je  string1
	call busy
    call charout
	inc si	
	jmp chk	
string1: ret 
string endp

ret_home proc near
	mov ah,11000000b	
out1 :  push ax
        push dx
	call busy
	mov  al,ah
	mov  dx,ireg
	out  dx,al
	pop  dx
	pop  ax
	ret
	ret_home endp
	
unlock_isr : 
	call allclr
	call ret_home
	jmp  X1
	iret
	
lock_isr: 
	mov al,00001000b
out1 :  push ax
        push dx
	call busy
	mov  al,ah
	mov  dx,ireg
	out  dx,al
	pop  dx
	pop  ax
	jmp  b0
	iret	

delay proc near
	mov	ah,86h
	mov	cx,00h
	mov	dx,4e20h
	int	15h
	ret
delay endp


END 