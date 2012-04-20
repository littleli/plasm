; plasm.asm 256b demo, v1.1 (2002-06-13)
; coder/ littleli / idea by jarre vangelisteam
[ORG 0100h]

spd1    equ     1
spd2    equ     2
spd3    equ     3
spd4    equ     4

RED     equ     0
GREEN   equ     1
BLUE    equ     2

color1  equ     GREEN
color2  equ     BLUE

[SECTION .bss]
tpos1         resb    1
tpos2         resb    1
tpos3         resb    1
tpos4         resb    1

pal           resb    768
waves         resb    256

[SECTION .data]
pos1          db      0
pos2          db      0
pos3          db      0
pos4          db      0

konst         dd      0.02454369260617026       ; pi/128
THIRTY        dw      30
x             dw      0

[SECTION .text]
        mov     ax,03f00h
        mov     di,pal
        push    di
        mov     cx,768
        rep     stosb                           ; in DI rests offset of waves
xxx1    mov     [bx+pal+color1],al              ; red ascending
        mov     [bx+pal+color1+64*3],ah         ; red descending
        mov     [bx+pal+color2+128*3],al        ; green ascending
        mov     [bx+pal+color2+192*3],ah        ; green descending
        dec     ah
        inc     al
        add     bx,BYTE 3
        cmp     bx,64*3
        jl      xxx1
; results in gradient palette

        mov     ch,1            ; array size of 0x100
        push    cx              ; store same for palette
        finit                   ; coprocessor init
xxx2    fld     DWORD [konst]
        fimul   WORD [x]        ; st0<-st0*x                 x*(pi/128)
        fsin                    ; st0<-sin(x*pi/128)      sin(x*pi/128)
        fstp    st1
        fld1                    ; st0<-1!
        fadd    st0,st1         ; st0<-st0+st1          1+sin(x*pi/128)
        fimul   WORD [THIRTY] ; st0<-st0*30       30*(1+sin(x*pi/128))
                                ; st0<-result before conversion
                                ;      and store to memory
        fistp   WORD [di]
        inc     di
        inc     WORD [x]
        loop    xxx2
; waves generation formula

        mov     ax,013h
        int     010h
; setting standard vga mode 320x200x8

vgafix  cli
        mov     dx,03c4h                ; modify vga mode to use 80x50
        mov     ax,0604h
        out     dx,ax
        mov     ax,0f02h
        out     dx,ax
        add     dx,BYTE 010h            ; 3c4h+10h
        mov     ax,014h
        out     dx,ax
        mov     ax,0e317h
        out     dx,ax
        mov     al,9
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0e0h
        add     al,7
        out     dx,al
        sti

setpal  pop     cx
        pop     dx
        mov     ax,01012h
        xor     bx,bx
        int     010h                    ; use bios to setup palette

        push    WORD 0a000h
        pop     fs                      ; ES needs to be preserved for xlatb instruction

waitvr  mov     dx,03dah
wait1   in      al,dx
        and     al,8
        jnz     wait1
wait2   in      al,dx
        and     al,8
        jz      wait2
        xor     bp,bp
        mov     ax,[pos1]
        mov     [tpos1],ax
        mov     ch,032h
for_y   mov     ax,[pos3]
        mov     [tpos3],ax
        mov     cl,050h
for_x   mov     si,tpos1        ; sum
        mov     bx,waves
        mov     ah,0
        mov     dl,4
s1      lodsb
        xlatb
        add     ah,al
        dec     dl
        jnz     s1
        mov     [fs:bp],ah
        inc     bp
        inc     BYTE [tpos3]
        add     [tpos4],BYTE 3
        dec     cl
        jnz     for_x

        add     [tpos1],BYTE 2
        inc     BYTE [tpos2]
        dec     ch
        jnz     for_y

        inc     BYTE [pos1]
;        add     [pos1],BYTE spd1       ; inc instruction is one byt shorter
        sub     [pos2],BYTE spd2
        add     [pos3],BYTE spd3
        sub     [pos4],BYTE spd4
        in      al,60h
        dec     al
        jnz     waitvr

        mov     ax,3
        int     10h             ; recovery from the graphic mode
        ret                     ; goodbye

        db      '!!'		; just for alignment to 256 bytes :)
