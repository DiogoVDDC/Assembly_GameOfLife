
    ;;    game state memory location
    .equ CURR_STATE, 0x1000             ; current game state
    .equ GSA_ID, 0x1004                 ; gsa currently in use for drawing
    .equ PAUSE, 0x1008                  ; is the game paused or running
    .equ SPEED, 0x100C                  ; game speed
    .equ CURR_STEP,  0x1010             ; game current step
    .equ SEED, 0x1014              		; game seed
    .equ GSA0, 0x1018              		; GSA0 starting address
    .equ GSA1, 0x1038              		; GSA1 starting address
    .equ SEVEN_SEGS, 0x1198             ; 7-segment display addresses
    .equ CUSTOM_VAR_START, 0x1200 		; Free range of addresses for custom variable definition
    .equ CUSTOM_VAR_END, 0x1300
    .equ LEDS, 0x2000                   ; LED address
    .equ RANDOM_NUM, 0x2010          	; Random number generator address
    .equ BUTTONS, 0x2030                ; Buttons addresses

    ;; states
    .equ INIT, 0
    .equ RAND, 1
    .equ RUN, 2

    ;; constants
    .equ N_SEEDS, 4
    .equ N_GSA_LINES, 8
    .equ N_GSA_COLUMNS, 12
    .equ MAX_SPEED, 10
    .equ PAUSED, 0x00
    .equ RUNNING, 0x01

main:
	;stw zero, GSA_ID(zero)
	;addi t0, zero, 2730
	;addi t1, zero, 1365
	;stw t0, GSA0(zero)
	;stw t1, GSA0+4(zero)
	;stw t0, GSA0+8(zero)
	;stw t1, GSA0+12(zero)
	;stw t0, GSA0+16(zero)
	;stw t1, GSA0+20(zero)
	;stw t0, GSA0+24(zero)
	;stw t1, GSA0+28(zero)
	;addi sp, zero, 24
	addi a0, zero, 4
	addi a1, zero, 5
	call set_pixel
	;;TODO

; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, LEDS + 4(zero)
	stw zero, LEDS + 8(zero)
	ret 
; END:clear_leds

;BEGIN:set_pixel
set_pixel:
	; Find in which array to change the led
	srli t1, a0, 2 		; index of word in of LED (0, 1, 2)
	slli t1, t1, 2		; multiply by 4 to get the correct LED word address (0, 4, 8)

	addi t2, zero, 3	; mask for mod 4
	and t3, a0, t2 		; x mod 4
	slli t3, t3, 3 		; multiply t3 by 8 
	add t3, t3, a1 		; add y to t3 to get index of bit to be set to 1;
	addi t4, zero, 1	; set t4 to 1 
	sll t4, t4, t3		; shift t4 to have a one at the led index	

	; Set new state of the leds  
	ldw t5, LEDS(t1)	; get current state of the leds array
	or t5, t4, t5		; turn on the given led 
	stw t5, LEDS(t1)	; store the new state
	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi t0, zero, 1
	slli t0, t0, 3 ;19
	ldw t2, SPEED(zero)
	call PUSH
	jmpi decrement_timer_loop
	call POP
	ret 
; END:wait

; BEGIN:get_gsa
get_gsa:
	addi t0, zero, GSA_ID	; set t0 to the GSAID
	beq t0, zero, fetchGSA0 ; if gsa ID is 0 then fetch in gsa0 else fetch in gsa1
	call fetchGSA1
	ret 
; END:get_gsa

; BEGIN:set_gsa
set_gsa:
	addi t0, zero, GSA_ID	; set t0 to the GSAID
	beq t0, zero, setGSA0	; if gsa ID is 0 then set in gsa0 else in gsa1
	call setGSA1
	ret 
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	add a0, zero, zero
	add t0, zero, zero
	add t1, zero, zero
	add t2, zero, zero
	add t4, zero, zero
	call PUSH
	call get_gsa
	call draw_loop
	ret 
; END:draw_gsa


; BEGIN:helper
PUSH:
	addi sp, sp, -4
	stw ra, 0(sp)
	ret
POP:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

decrement_timer_loop:
	sub t0, t0, t2
	bge t0, zero, decrement_timer_loop
	ret

fetchGSA0:
	ldw t0, GSA0(a0)
	add v0, zero, t0
	ret
fetchGSA1:
	ldw t0, GSA1(a0)
	add v0, zero, t0
	ret

setGSA0:
	stw a0, GSA0(a1)
	ret
setGSA1:
	stw a0, GSA1(a1)
	ret

draw_loop:
	;t0 leds0 , t1, leds1, t2 leds 2

	add t5, t4, a0		;get index in leds of the bit

	andi t3, v0, 1		;isolate last bit of v0 // isolated bit is already in LSB
	sll t3, t3, t5		;shift to get bit in the rigt column and row
	or t0, t0, t3		; Put in leds 0											t4
;																				0 1 2 3 4 5 6 7 8 9 1011			LEDS 0		LEDS 1		LEDS 2
	andi t3, v0, 16		;isolate bit at index 4 of v0					   a0 0 | | | | | | | | | | | |			0 8  16 24 | 0 8  16 24 | 0 8  16 24 
	slli t3, t3, 4		;isolated bit in LSB								  1	| | | | | | | | | | | | 		1 9  17 25 | 1 9  17 25 | 1 9  17 25 
	sll t3, t3, t5		;shift to get bit in the rigt column and row		  2	| | | | | | | | | | | | 		2 10 18 26 | 2 10 18 26 | 2 10 18 26 
	or t1, t1, t3		;Put in leds 1										  3	| | | | | | | | | | | | 		3 11 19 27 | 3 11 19 27 | 3 11 19 27 
;																			  4	| | | | | | | | | | | | 		4 12 20 28 | 4 12 20 28 | 4 12 20 28 
	andi t3, v0, 256	;isolate bit at index 8 of v0						  5	| | | | | | | | | | | | 		5 13 21 29 | 5 13 21 29 | 5 13 21 29 
	slli t3, t3, 8		;isolated bit in LSB								  6	| | | | | | | | | | | | 		6 14 22 30 | 6 14 22 30 | 6 14 22 30 
	sll t3, t3, t5		;shift to get bit in the rigt column and row		  7	| | | | | | | | | | | | 		7 15 23 31 | 7 15 23 31 | 7 15 23 31 
	or t2, t2, t3		;Put in leds 2
	
	srli v0, v0, 1		;shift v0 one bit to the right
	addi t4, t4, 8		;add 8 to the column index 
	cmpgeui t6, t4, 24	;set to 1 if column index is bigger than 24
	add a0, a0, t6		;if loop finished placing all bit of current line then t6=1 which will increment the line

	cmpgeui t7, a0, 7 	;set if line index is bigger than 7 (out of bounds)
	bne t7, zero, end_draw_loop ;check if last line has been reached in which case calls the end of the loop
	br draw_loop		;else go to next iteration

end_draw_loop:
	stw t0, LEDS(zero)	;Set leds 0
	stw t1, LEDS+4(zero);Set leds 1
	stw t2, LEDS+8(zero);Set leds 2
	ret				; return to call

; END:helper
font_data:
    .word 0xFC # 0
    .word 0x60 # 1
    .word 0xDA # 2
    .word 0xF2 # 3
    .word 0x66 # 4
    .word 0xB6 # 5
    .word 0xBE # 6
    .word 0xE0 # 7
    .word 0xFE # 8
    .word 0xF6 # 9
    .word 0xEE # A
    .word 0x3E # B
    .word 0x9C # C
    .word 0x7A # D
    .word 0x9E # E
    .word 0x8E # F

seed0:
    .word 0xC00
    .word 0xC00
    .word 0x000
    .word 0x060
    .word 0x0A0
    .word 0x0C6
    .word 0x006
    .word 0x000

seed1:
    .word 0x000
    .word 0x000
    .word 0x05C
    .word 0x040
    .word 0x240
    .word 0x200
    .word 0x20E
    .word 0x000

seed2:
    .word 0x000
    .word 0x010
    .word 0x020
    .word 0x038
    .word 0x000
    .word 0x000
    .word 0x000
    .word 0x000

seed3:
    .word 0x000
    .word 0x000
    .word 0x090
    .word 0x008
    .word 0x088
    .word 0x078
    .word 0x000
    .word 0x000


    ## Predefined seeds
SEEDS:
    .word seed0
    .word seed1
    .word seed2
    .word seed3

mask0:
    .word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF

mask1:
    .word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF

mask2:
    .word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF

mask3:
    .word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

mask4:
    .word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

MASKS:
    .word mask0
    .word mask1
    .word mask2
    .word mask3
    .word mask4
