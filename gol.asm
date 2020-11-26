
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
	; Initialization of value // DONT DELETE OR WONT WORK
	stw zero, GSA_ID(zero)	;Set GSA ID to 0 
	addi sp, zero, 8192		;Init stack pointer to end of memory
	addi t0, t0, 1			; init value for speed
	stw t0, SPEED(zero)		; load init value in speed register
	stw t0, CURR_STEP(zero)	; default value currstep
	add t1, zero, zero
	addi t1, t1, 4			; index display 1
	ldw t2, font_data(zero)	; load hexadecimal value of 0
	stw t2, SEVEN_SEGS(t1)	; default value sevenseg to 0
	addi t1, t1, 4			; index display 2
	stw t2, SEVEN_SEGS(t1)	; default value sevenseg to 1
	addi t1, t1, 4			; index display 3
	addi t3, t3, 4
	ldw t2, font_data(t3)	; get the hexadecimal value of 1
	stw t2, SEVEN_SEGS(t1)	; default value sevenseg to 1
	


	;Testing random_gsa:	
	;call random_gsa
	;call draw_gsa
	;break

	;Testing change_speed:
	;addi a0, a0, 0
	;call change_speed
	;break

	;Testing pause_game:
	;call pause_game 
	;call pause_game 
	;break

	;Testing change steps:
	addi a0, a0, 1
	addi a1, a1, 1
	addi a2, a2, 1
	call change_steps
	addi a0, a0, 1
	addi a1, a1, 1
	addi a2, a2, 1
	call change_steps
	break

	;Testing increment_seed:
	;call increment_seed
	;call draw_gsa
	;break

	;;TODO

; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, LEDS + 4(zero)
	stw zero, LEDS + 8(zero)
	ret 
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	; Find in which array to change the led
	srli t1, a0, 2 		; index of word in of LED (0, 1, 2)
	slli t1, t1, 2		; multiply by 4 to get the correct LED word address (0, 4, 8)

	andi t3, a0, 3 		; x mod 4
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
	decrement_timer_loop:
	sub t0, t0, t2
	bgeu t0, t2, decrement_timer_loop
	ret
; END:wait

; BEGIN:get_gsa
get_gsa:
	ldw t0, GSA_ID(zero)
	slli t0, t0, 5
	slli t1, a0, 2
	add t0, t0, t1
	ldw v0, GSA0(t0)
	ret
; END:get_gsa

; BEGIN:set_gsa
set_gsa:
	ldw t0, GSA_ID(zero)	; set t0 to the GSAID
	slli t0, t0, 5
	slli t1, a1, 2
	add t0, t0, t1
	stw a0, GSA0(t0) 
	ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	;PUSH
	addi sp, sp, -4
	stw ra, 0(sp)
	
	add a0, zero, zero	; line index (0,1,2,3,4,5,6 or 7)
	add s0, zero, zero	; LEDS0
	add s1, zero, zero	; LEDS1
	add s2, zero, zero	; LEDS2
	add s4, zero, zero 	; x index in the leds (0, 8, 16 or 24)
	draw_gsa_iterator:
	addi t7, zero, 7		;8 in t7
	call get_gsa
	add s4, zero, zero

	blt a0, t7, draw_line_loop
	br end_draw
	
	draw_line_loop:
	;s0=LEDS0 , s1=LEDS1, s2=LEDS2
	add t5, s4, a0		;get shift index in the leds array

	andi t3, v0, 1		;isolate last bit of v0 // isolated bit is already in LSB
	sll t3, t3, t5		;shift to get bit in the rigt column and row
	or s0, s0, t3		;Put in leds 0											t4
;																				11109 8 7 6 5 4 3 2 1 0			LEDS 0		LEDS 1		LEDS 2
	andi t3, v0, 16		;isolate bit at index 4 of v0					   a0 0 | | | | | | | | | | | |			0 8  16 24 | 0 8  16 24 | 0 8  16 24 
	srli t3, t3, 4		;isolated bit in LSB								  1	| | | | | | | | | | | | 		1 9  17 25 | 1 9  17 25 | 1 9  17 25 
	sll t3, t3, t5		;shift to get bit in the rigt column and row		  2	| | | | | | | | | | | | 		2 10 18 26 | 2 10 18 26 | 2 10 18 26 
	or s1, s1, t3		;Put in leds 1										  3	| | | | | | | | | | | | 		3 11 19 27 | 3 11 19 27 | 3 11 19 27 
;																			  4	| | | | | | | | | | | | 		4 12 20 28 | 4 12 20 28 | 4 12 20 28 
	andi t3, v0, 256	;isolate bit at index 8 of v0						  5	| | | | | | | | | | | | 		5 13 21 29 | 5 13 21 29 | 5 13 21 29 
	srli t3, t3, 8		;isolated bit in LSB								  6	| | | | | | | | | | | | 		6 14 22 30 | 6 14 22 30 | 6 14 22 30 
	sll t3, t3, t5		;shift to get bit in the rigt column and row		  7	| | | | | | | | | | | | 		7 15 23 31 | 7 15 23 31 | 7 15 23 31 
	or s2, s2, t3		;Put in leds 2
	
	cmpeqi t6, s4, 24	;if t4==24 then t6 = 6 hence changing the line 
	add a0, a0, t6		;increment line index if reached column 4 
	bne t6, zero, draw_gsa_iterator
	
	srli v0, v0, 1		;shift v0 one bit to the right
	addi s4, s4, 8		;add 8 to the column index 
	br draw_line_loop	;else go to next iteration

	end_draw:
	stw s0, LEDS(zero)	;Set leds 0
	stw s1, LEDS+4(zero);Set leds 1
	stw s2, LEDS+8(zero);Set leds 2
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:draw_gsa

; BEGIN:random_gsa
random_gsa:
	;PUSH
	addi sp, sp, -4
	stw ra, 0(sp)

	addi s1, zero, 8	;Max value of y coordinate (used for comparisons later)
	add a0, zero, zero
	add a1, zero, zero

	randomize_gsa:
	ldw a0, RANDOM_NUM(zero)
	call set_gsa
	addi a1, a1, 1
	blt a1, s1, randomize_gsa
	br end_random_gsa

	end_random_gsa:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:random_gsa

; BEGIN: update_state
update_state:
	;PUSH
	addi sp, sp, -4
	stw ra, 0(sp)

	ldw s1, CURR_STATE(zero)	; get value of the curr state in s1
	beq s1, zero, update_init	; if curr state = 0 = init then update state init
	addi t1, zero, 1			
	beq s1, t1, update_rand		; if curr state = 1 = rand then update state rand
	br update_run				; if curr state = 2 = run then update state run

	update_init:
	addi t1, zero, N_SEEDS		; set t1 to number of seeds
	ldw t0, SEED(zero)			; amount of time b0 has been pressed
	beq t0, t1, setStateRand	;if 1 next state is rand
	andi t2, a0, 2 				; isolate input of button b1
	bne t2, zero, setStateRun	; if b1 is pressed go to state run
	br end_updater				; else remain instate init

	update_rand:
	andi t0, a0, 1				; isolate input of button b0
	bne t0, zero, end_updater	; if b0 is pressed, stay in state rand hence finish updater. Needs to be done before checking b1 because we prioritize lsb 
	andi t0, a0, 2 				; isolate input of button b1
	bne t0, zero, setStateRun	; if b1 is pressed, go to run state
	br end_updater				; else remain in state rand

	update_run:
	andi t0, a0, 1				; isolate input of button b0
	andi t1, a0, 2				; isolate input of button b1
	srli t1, t1, 1				; shift b1 input to lsb of t1
	andi t2, a0, 4				; isolate input of button b2
	srli t2, t2, 2				; shift b2 input to lsb of t2
	or t0, t0, t1				; sets t0 to 1 if either b0 or b1 is pressed
	or t0, t0, t2				; sets t0 to 1 if either b0 or b1 or b2 is pressed
	bne t0, zero, end_updater	; if b0 or b1 or b2 is pressed we must remain in state run hence finishes version
	andi t0, a0, 8				; isolate input of button b3
	bne t0, zero, setStateInit	; if b3 is pressed go to state init
	ldw t0, CURR_STEP(zero)		; get the number of steps left
	beq t0, zero, setStateInit	; if reached max steps go to state init
	br end_updater

	; Setters for the state
	setStateRand:
	addi t0, zero, 1
	stw t0, CURR_STATE(zero)
	br end_updater

	setStateInit:
	stw zero, CURR_STATE(zero)
	br end_updater

	setStateRun:
	addi t0, zero, 2
	stw t0, CURR_STATE(zero)

	end_updater:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:update_state
	
; BEGIN:select_action
select_action:
	;PUSH
	addi sp, sp, -4
	stw ra, 0(sp)
	
	add s7, a0, zero	;stores a0 in s7 to be able to restore it at the end
	
	stw t0, CURR_STATE(zero)	
	cmpeqi t0, t0, 2
	beq t0, zero, actionInitRand
	br actionRun

	; ACTIONS OF RAND AND INIT STATE
	actionInitRand:
	andi t0, a0, 1	;input b0
	bne t0, zero, initB0
	andi t0, a0, 2	;input b1
	bne t0, a0, initB1
	br initB234
	andi t0, a0, 4
	br end_select

	initB0:				;actions of b0
	call increment_seed
	br end_select
	initB1:				;actions of b1
	br end_select
	initB234:			;actions of b2
	andi t0, a0, 4
	cmpeqi a2, t0, 1
	andi t0, a0, 8    
	cmpeqi a1, t0, 1
	andi t0, a0, 16
	cmpeqi a0, t0, 1
	call change_steps
	br end_select

	; ACTIONS OF RUN STATE
	actionRun:	
	andi t0, a0, 1	;input of b0
	bne t0, zero, runB0
	andi t0, a0, 2	;input of b1
	bne t0, zero, runB1
	andi t0, a0, 4	;input of b2
	bne t0, zero, runB2
	andi t0, a0, 8	;input of b3
	bne t0, zero, runB3
	andi t0, a0, 16	;input of b4
	bne t0, zero, runB4
	br end_select	;if no input, just go to the end
	
	runB0:	;actions of b0
	call pause_game
	br end_select

	runB1:	;actions of b1
	addi a0, zero, 0
	call change_speed
	br end_select

	runB2:	;actions of b2
	addi a0, zero, 1
	call change_speed
	br end_select
	
	runB3:	;actions of b3
	call reset_game
	br end_select
	
	runB4:	;actions of b4
	call random_gsa
	br end_select	

	end_select:		
	add a0, zero, s7	; put original a0 back in place
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END: select_action

; BEGIN:change_speed
change_speed: 
	ldw t0, SPEED(zero)
	beq a0, zero, increment_speed

	decrement_speed:
	cmpgei t1, t0, 2
	beq t1, zero, end_change_speed
	addi t0, t0, -1
	br end_change_speed
	increment_speed:
	cmpgei t1, t0, 10
	bne t1, zero, end_change_speed
	addi t0, t0, 1
	end_change_speed:
	stw t0, SPEED(zero)
	ret

	; a0 is 1 if speed is to be incremented, 0 if speed to be decremented
	add s0, zero, zero
	add t0, zero, zero
	add t1, zero, zero

	addi t0, zero, 1
	beq a0, t0, ldw_speed_decrement
	beq a0, zero, ldw_speed_increment

	ldw_speed_increment:
	addi t1, zero, 10
	ldw s0, SPEED(zero)
	blt s0, t1, speed_increment 
	ret

	ldw_speed_decrement:
	addi t1, zero, 2
	ldw s0, SPEED(zero)
	bge s0, t1, speed_decrement 
	ret
	speed_increment:
	addi s0, s0, 1
	stw s0, SPEED(zero)
	ret

	speed_decrement:
	addi s0, s0, -1
	stw s0, SPEED(zero)
	ret
; END:change_speed

; BEGIN:pause_game
pause_game:
	add t0, zero, zero
	addi t0, t0, 1
	ldw t1, PAUSE(zero)
	xori t1, t1, 1 ;t1 XOR 1 = NOT t1 (inversion of bit t1)
	stw t1, PAUSE(zero)
	ret
; END:pause_game

; BEGIN:change_steps
change_steps:
	;t0 is the Seven Segment Display 3 (most to right) associated to button 4 and a0
	;t1 is the Seven Segment Display 2 associated to button 3 and a1
	;t2 is the Seven Segment Display 1 associated to button 2 and a2
	;t3 is the current number of steps in HEXADECIMAL

	ldw t0, SEVEN_SEGS+12(zero)
	ldw t1, SEVEN_SEGS+8(zero)
	ldw t2, SEVEN_SEGS+4(zero)
	ldw t3, CURR_STEP(zero)
	add t4, zero, zero
	add t5, zero, zero
	addi t4, t4, 4 ; which display will be updated first
	add s2, zero, zero ; set index to word to 0
	add s1, zero, zero 
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	br update_display

	update_display:
	add s1, s1, t2 ;s1 stores value of the seven_segs that will be updated
	add t5, t5, a2
	call loop

	add s1, s1, t1
	add t5, t5, a1
	call loop	
	
	add s1, s1, t0 
	add t5, t5, a0
	call loop

	br increment_number_steps

	loop: 
	beq t5, zero, finish_loop
	ldw t6, font_data(s2)
	beq t6, s1, stw_display
	addi s2, s2, 4
	br loop

	stw_display:
	addi s2, s2, 4
	ldw t7, font_data(s2)
	stw t7, SEVEN_SEGS(t4)
	br finish_loop

	finish_loop:
	add t5, zero, zero
	addi t4, t4, 4
	add s1, zero, zero 
	add s2, zero, zero
	ret

	increment_number_steps:
	add t3, t3, a0
	slli t4, a1, 4 ; a0 * 16 stored in t4  
	slli t5, a2, 8 ; a0 * 16^2 stored in t5s
	add t3, t3, t4 ; increment time
	add t3, t3, t5 ; increment time
	stw t3, CURR_STEP(zero)
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

; END:change_steps

; BEGIN:increment_seed
increment_seed:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	;if state is INIT increment seed by one and store new seed in current GSA
	;t0 is the current state
	addi t1, zero, 1

	ldw t0, CURR_STATE(zero)
	beq t0, zero, increment_seed_init
	beq t0, t1, increment_seed_rand
	br end

	increment_seed_init:
	ldw t0, SEED(zero)
	addi t0, t0, 1
	stw t0, SEED(zero)
	addi a0 ,zero, 0	; line value
	addi a1 ,zero, 0	; line y coord
	addi s2, zero, 8	; max y coord value
	slli t0, t0, 2
	ldw s1, SEEDS(t0)	; t1 is address of seed(0, 1, 2 or 3)
	ldw t1, MASKS(t0)	; address of the mask
	stw t1, MASK(zero)	; stores the address of the mask in the RAM

	increment_loop:		; applies the seed to the gsa
	ldw a0, 0(s1)		; value of the line in the seed
	call set_gsa
	addi s1, s1, 4		; increment line
	addi a1, a1, 1		; increment y coordinate
	blt a1, s2, increment_loop
	br end

	increment_seed_rand:
	addi t0, zero, N_SEEDS
	slli t0, t0, 4
	ldw t0, MASKS+N_SEEDS(zero) ; load
	stw t0, MASK(zero)
	call random_gsa
	br end

	end:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

; END:increment_seed

; BEGIN:cell_fate
cell_fate:
	addi t0, t0, 2
	addi t1, t1, 3
	addi t2, t2, 4

	blt a0, t0, set_dead	;has less then 2 neighbours
	bge a0, t2, set_dead	;has more than 3 neighbours
	beq a0, t0, current_state	;has 2 neighbours if dead stays dead, if alive stays alive
	beq a0, t1, set_alive 	;reproduction	

	set_alive:
	addi v0, zero, 1
	ret

	set_dead:
	add v0, zero, zero
	ret

	current_state:
	add v0, a1, zero
	ret
; END: cell_fate 

; BEGIN:find_neighbours
find_neighbours:
	addi t0, zero, 1
	; what is in cell t1?	
	;t1

	beq t1, t0, increment_neighbour_count

	;set s3 (the x coordinate) return the s0 and s1

		
	increment_neighbour_count:
		addi v0, v0, 1 		

; END:find_neighbours

; BEGIN:update_gsa
update_gsa:
; END:update_gsa

; BEGIN:mask
mask:
; END:mask

; BEGIN:get_input
get_input:
; END:get_input

; BEGIN:decrement_step
decrement_step:
; END:decrement_step

; BEGIN:reset_game
reset_game:
; END:reset_game

; BEGIN:helper
.equ MASK, 0x1200 

get_pixel: 	
	andi s0, s3, 3	;x mod 4 correspond to which LED array we fall in
	srli s1, s3, 2	;floor(x/4) is the selected word in LED
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
