
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
	; Initialization of stack // DONT DELETE OR WONT WORK
	addi sp, zero, 8192		;Init stack pointer to end of memory (0x2000)

	loop1:
	call reset_game		;resets the game
	call get_input		;sets v0 to edgecapture
	loop2:
	add a0, zero, v0	;a0 is edgecapture input of select_action
	call select_action	;did not change value of v0
	add a0, zero, v0	;a0 is edgecapture input of update_state
	call update_state
	call update_gsa		;doesn't take input
	call mask			;doesn't take input
	call draw_gsa		;doesn't take input
	call wait			;doesn't take input
	call decrement_step	;v0 takes value 1 if finished else 0
	add v1, zero, v0	;puts v0 into v1 to preserve it's value since get_input will temper with v0
	call get_input		;v0 takes value of edge capture
	beq v1, zero, loop2	;if v1=0, game isn't finished hence we go again in loop2
	br loop1			;else end game en go back to loop1

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
	slli t0, t0, 19
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
	ldw t0, GSA_ID(zero)	; set t0 to the current GSAID
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
	
	call clear_leds
	add a0, zero, zero	; line index (0,1,2,3,4,5,6 or 7)
	add s0, zero, zero	; LEDS0
	add s1, zero, zero	; LEDS1
	add s2, zero, zero	; LEDS2
	add s4, zero, zero 	; x index in the leds (0, 8, 16 or 24)
	draw_gsa_iterator:
	addi t7, zero, 8		;8 in t7
	call get_gsa
	add s4, zero, zero

	blt a0, t7, draw_line_loop
	br end_draw
	
	draw_line_loop:
	;s0=LEDS0 , s1=LEDS1, s2=LEDS2
	add t5, s4, a0		;get shift index in the leds array

	andi t3, v0, 1		;isolate last bit of v0 // isolated bit is already in LSB
	sll t3, t3, t5		;shift to get bit in the rigt column and row
	or s0, s0, t3		;Put in leds 0											
;																				
	andi t3, v0, 16		;isolate bit at index 4 of v0					  
	srli t3, t3, 4		;isolated bit in LSB							
	sll t3, t3, t5		;shift to get bit in the rigt column and row		 
	or s1, s1, t3		;Put in leds 1										
;																			
	andi t3, v0, 256	;isolate bit at index 8 of v0					
	srli t3, t3, 8		;isolated bit in LSB								 
	sll t3, t3, t5		;shift to get bit in the rigt column and row		  
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

	add a0, zero, zero
	add a1, zero, zero

	randomize_gsa:
	ldw a0, RANDOM_NUM(zero)
	call set_gsa
	addi a1, a1, 1
	addi t0, zero, 8
	blt a1, t0	, randomize_gsa
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
	andi t2, a0, 1				;isolate input of b1
	addi t1, zero, N_SEEDS		; set t1 to max number of seeds
	ldw t0, SEED(zero)			; amount of time b0 has been pressed
	cmpeq t0, t1, t0			;sets t2 if reached max number of seeds
	and t0, t0, t2				;sets t0 if pressed b0 and reached max seed
	bne t0, zero, setStateRand	;sets to state Rand if b0 is pressed and we've reached max seeds
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
	bne s1, zero, RandOrRunToInit	;if the previous state wasn't already init, we need to reset the game
	stw zero, CURR_STATE(zero)		;not necessary since the previous state is already supposed to be init but just in case
	br end_updater

	setStateRun:
	addi t0, zero, 2
	stw t0, CURR_STATE(zero)
	br end_updater

	RandOrRunToInit:
	call reset_game		; if going from rand or run to init we must call reset game
	stw zero, CURR_STATE(zero)

	; Ends the updater
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
	
	ldw t0, CURR_STATE(zero)	
	cmpeqi t0, t0, 2
	beq t0, zero, actionInitRand
	br actionRun

	; ACTIONS OF RAND AND INIT STATE
	actionInitRand:
	andi t0, a0, 1	;input b0
	bne t0, zero, initB0
	andi t0, a0, 2	;input b1
	bne t0, zero, initB1
	br initB234
	andi t0, a0, 4
	br end_select

	initB0:				;actions of b0
	call increment_seed
	br end_select
	initB1:				;actions of b1
	addi t0, zero, 1
	stw t0, PAUSE(zero)
	br end_select
	initB234:			;actions of b2
	andi t0, a0, 4
	cmpne a2, t0, zero	;set input a2 of change steps
	andi t0, a0, 8    
	cmpne a1, t0, zero	;set input a1 of change steps
	andi t0, a0, 16
	cmpne a0, t0, zero	;set input a0 of change steps
	call change_steps
	call set_7Seg
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
	ldw t0, CURR_STEP(zero)
	
	add t0, t0, a0	;if b4 was pressed, a0 equals zero hence a unit is added, else nothing is added
	
	add t1, zero, a1
	slli t1, t1, 4	;if b3 was pressed then a1=1 and moving it by 4 to change it to 16 (value of a ten in hexa)
	add t0, t0, t1	;if t1 wasn't 0, adds a tens

	add t1, zero, a2
	slli t1, t1, 8	;if b2 was pressed then a1=1 and moving it by 8 to change it to 256 (value of a hundred in hexa)	
	add t0, t0, t1

	stw t0, CURR_STEP(zero)
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
	br end_incr

	increment_seed_init:
	ldw t0, SEED(zero)
	addi t1, zero, N_SEEDS - 1
	beq t0, t1, incr_init_w_overflow	;if seed if already the max one we have an overflow
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
	br end_incr

	incr_init_w_overflow:	;when pushed b0 one to many time
	addi t0, t0, 1	;go to seeds n+1 
	slli t0, t0, 2		;multiply n+1 by 4 (difference btwn addresses is 4)
	ldw t0, MASKS(t0)	;get address of mask n+1	
	stw t0, MASK(zero)	;store the address in the current seed address

	call random_gsa		;apply a random gsa
	br end_incr

	increment_seed_rand:
	addi t0, zero, N_SEEDS
	slli t0, t0, 4
	ldw t0, MASKS+N_SEEDS(zero) ; load
	stw t0, MASK(zero)
	br end_incr

	end_incr:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

; END:increment_seed

; BEGIN:cell_fate
cell_fate:
	addi t0, zero, 2
	addi t1, zero, 3
	addi t2, zero, 4

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
	add v0, zero, a1
	ret
; END: cell_fate 

; BEGIN:find_neighbours
find_neighbours:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)


	addi sp, sp, -20	;prepares to push 5 values
	stw s0, 0(sp)		;push s0
	stw s1, 4(sp)		;push s1
	stw s3, 8(sp)		;push s3
	stw s4, 12(sp)		;push s4
	stw s5, 16(sp)		;push s5


	add s0, a0, zero
	add s1, a1, zero
	addi s4, zero, -2	; offset in y direction
	add s5, zero, zero	; number of neighbours

	loop_y_increment:
	addi s3, zero, -1	; offset in x direction
	addi s4, s4, 1
	
	addi t0, zero, 2	; max value of y
	blt s4, t0, loop_x_increment
	br end_find_neigh
		
	loop_x_increment:
	add a0, s0, s3		;add offset to x
	add a1, s1, s4		;add offset to y							;* * *
	andi a1, a1, 7		;a1 mod 8									;* * *
	call mod12			;set a0 to x mod 12							;* * *
	call get_pixel_gsa		;v0 has value of cell at (x,y)				
	add s5, s5, v0		;add neigh value to total 

	addi s3, s3, 1		;increment offset
	addi t0, zero, 2	;max value of x offset
	blt s3, t0, loop_x_increment
	br loop_y_increment

	end_find_neigh:
	add a0, zero, s0	;restore original x 
	add a1, zero, s1	;restore original y
	call get_pixel_gsa		;v0 holds pixel value
	add v1, zero ,v0	;set return value
	sub s5, s5, v0		;substract self value to neighbors count
	add v0, zero, s5	;neigh count in return register v0
	;POP
	ldw s0, 0(sp)
	ldw s1, 4(sp)
	ldw s3,	8(sp)
	ldw s4, 12(sp)
	ldw s5, 16(sp)
	ldw ra, 20(sp)
	addi sp, sp, 24
	ret

	mod12:
	mod12_loop:
	blt a0, zero, retMod12
	addi a0, a0, -12
	br mod12
	retMod12:
	addi a0, a0, 12
	ret
	

; END:find_neighbours

; BEGIN:update_gsa
update_gsa:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	ldw t0, PAUSE(zero)
	beq t0, zero, end_update_gsa_noReversing
	
	add s5, zero, zero	; x axis
	add s6, zero, zero	; y axis
	add s7, zero, zero	; holds new gsa row value

	updater_loop:	
	add a0, zero, s5	;input x of find_neighbours to current x val
	add a1, zero, s6	;input y of find_neighbours to current y val
	call find_neighbours	
	add a0, zero, v0	; input live cells of cell_fate
	add a1, zero, v1	; input state of cell_fate
	call cell_fate	

	slli v0, v0, 12
	add s7, s7, v0		;adds the new value of the cell to the gsa row
	srli s7, s7, 1		

	addi s5, s5, 1		;increment x	
	addi t0, zero, 12	;t0 holds max val of x
	beq s5, t0,  changeLine
	br updater_loop

	changeLine:
	ldw t0, GSA_ID(zero)
	xori t0, t0, 1		;inverts GSA_ID (because set_gsa change the gsa of the currently in used GSA hence we needed to reverse it so that it changes the next GSA)
	stw t0, GSA_ID(zero)
	add a0, zero, s7	;set input for set_gsa
	add a1, zero, s6	;set input for set_gsa
	call set_gsa		
	ldw t0, GSA_ID(zero)
	xori t0, t0, 1		;re-inverse GSA_ID
	stw t0, GSA_ID(zero)
	
	addi t0, zero, 7
	beq s6, t0, end_update_gsa	;if reached max line, end 
	addi s6, s6, 1		;else increment y 
	add s5, zero, zero	;reset x coord to 0
	add s7, zero, zero	;resets the gsa row to zero to start again
	br updater_loop
	
	end_update_gsa:
	ldw t0, GSA_ID(zero)
	xori t0, t0, 1	;invert GSA_ID
	stw t0, GSA_ID(zero)
	end_update_gsa_noReversing:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:update_gsa

; BEGIN:mask
mask:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	add a0, zero, zero	;y coord
	ldw s0, MASK(zero)	;get corresponding mask starting address
	loop_mask:
	call get_gsa		;v0 now contains current gsa row
	ldw t1, 0(s0)		;gets mask for the current line
	and t0, v0, t1		;apply the mask
	add a1, zero, a0	;sets y coord for function set_gsa
	add a0, zero, t0	;sets line for function set_gsa
	call set_gsa		;puts the masked gsa back in place
	addi a0, a1, 1		;increments line and puts it back into a0
	addi t0, zero, 8	;max y value
	addi s0, s0, 4		;increment mask line address
	blt a0, t0, loop_mask

	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:mask

; BEGIN:get_input
get_input:
	ldw t0, BUTTONS+4(zero)		;get edge capture input
	addi t1, zero, 31			;mask to only keep 5 least significant bits of the edgecapture
	and v0, t0, t1				;use mask on edgecapture
	stw zero, BUTTONS+4(zero)	;clear the edgecapture 
	ret
; END:get_input

; BEGIN:decrement_step
decrement_step:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	ldw t0, CURR_STATE(zero)
	addi t1, zero, 2
	beq t0, t1, RunStateDecrement	
	
	InitRandDecrement:
	add v0, zero, zero
	br end_decrement_step

	RunStateDecrement:
	addi v0, zero, 0
	ldw t1, PAUSE(zero)
	beq t1, zero, end_decrement_step	
	ldw t1, CURR_STEP(zero)	;get the amount of step remaining
	cmpeq v0, t1, zero		;if steps remaining=0 set v0 to 1
	beq t1, zero, end_decrement_step	;if steps remaining was 0 go to the end
	addi t1, t1, -1			;decrement steps
	stw t1, CURR_STEP(zero)	;update remaining steps value

	end_decrement_step:
	call set_7Seg
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:decrement_step

; BEGIN:reset_game
reset_game:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t0, zero, 1		;t0 holds value 1
	stw t0, CURR_STEP(zero)	;set steps t0 1
	call set_7Seg			;display current amount of steps

	stw zero, SEED(zero)	;set seed to 0
	ldw t0, MASKS(zero)		;set to use mask0
	stw t0, MASK(zero)		;store mask0 in mask register

	stw zero, GSA_ID(zero)	;set GSA_ID to 0
	call reset_gsa			;set gsa0 to seed0
	
	stw zero, PAUSE(zero)	;pauses the game
	addi t0, zero, 1
	stw t0, SPEED(zero)		;set speed to 1 (t0 = 1)
		

	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:reset_game

; BEGIN:helper
.equ MASK, 0x1200	;holds the address of the current mask

reset_gsa:
	;PUSH 
	addi sp, sp, -4
	stw ra, 0(sp)

	add a1, zero, zero	;y coord
	loop_reset_gsa:
	slli t0, a1, 2	;multiplies a1 by 4
	ldw a0, seed0(t0)	;yth line of seed 0
	call set_gsa
	
	addi t1, zero, 7	;max value for y coord
	beq a1, t1, end_reset_gsa	;if reached max value for y, end loop 
	addi a1, a1, 1				;else increment y
	br loop_reset_gsa

	end_reset_gsa:
	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	

set_7Seg:	;Given the amount of steps to be displayed on the 7seg displays, finds the correct code for each 7seg
	addi t0, zero, 12		;loop counter
	ldw t1,	CURR_STEP(zero)	;load the number of steps to be displayed
	slli t1, t1, 4
	addi t2, zero, 15		;mask to keep only 4 lsbs
	loop_set7Seg:
	srli t1, t1, 4
	and t3, t1, t2			;masks the 4 lsb
	slli t3, t3, 2			;multiplise t3 by 4
	ldw t4, font_data(t3)	;get code for the 7seg corresponding to the 4 lsbs
	stw t4, SEVEN_SEGS(t0)	;stores the code
	beq t0, zero, end_set_7seg
	addi t0, t0, -4		
	br loop_set7Seg
	
	end_set_7seg:
	ret
	
get_pixel_gsa: 	;given coords (x,y) (in (a0, a1)) returns the state of the cell from gsa in v0
	;PUSH
	addi sp, sp, -4
	stw ra, 0(sp)

	add t0, zero, a0
	add a0, zero, a1	;puts a1 in a0
	add a1, zero, t0	;puts a0 in a1 (from t0 which is where we has stored the original value of a0)

	call get_gsa		;gets the current line

	addi t0, zero, 1
	sll t0, t0, a1		;shift the one to the index in the line given by x
	
	and t0, v0, t0		;isolate bit at position x in row 
	cmpnei v0, t0, 0	;if isolated bit isn't equal to zero, set t0 to 1

	;POP
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
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
