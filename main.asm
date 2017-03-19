
.macro push (%reg)
	addi $sp, $sp, -4
	sw %reg, 0($sp)
.end_macro 

.macro pop (%reg)
	lw %reg, ($sp)
	addi $sp, $sp, 4
.end_macro

.macro call (%label)
	push $ra
	jal %label
.end_macro

.macro return
	move $t0, $ra
	pop $ra
	jr $t0
.end_macro

.data 
#board is a 2D array of 1 byte entrys
boardStart: 
	.space 48 
topStart:
	.space 7
board:
	.asciiz "" #TODO
playerPrompt: 
	.asciiz "" #TODO
winMsg:
	.asciiz "" #TODO

	#$s0 is always win condition, 10 for t1	  , 11 for t2
	#$s1 is the type of game, 0 for 2 player, 1 for computer 
	#$s2 is row for last move
	#$s3 is col for last move
	#if game has computer it is on t1
	
.text
setup:
	call prompts
	call drawBoard
	bnez  $s1, compGameLoop
	
gamePlayLoop:
	#TODO add tile t0
	li $a2, 0
	call winCheck #BUG other team still plays if t0 wins
	#TODO add tile t1
	li $a2, 1
	call winCheck 
	bnez $s0, win #met win condition, BUG: if both teams win on the same turn t1 always wins, 
	j gamePlayLoop
	#you should never get here
	j exit
	
compGameLoop:
	#TODO add tile t0
	li $a2, 0
	call winCheck #BUG other team still plays if t0 wins
	#TODO add tile t1
	li $a2, 1
	call winCheck 
	bnez $s0, win #met win condition
	j compGameLoop 
	#should never get here
	j exit
	
drawBoard:
	la $a0, board # load addr of board into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	return #ret
	
#in: $a0 = row, $a1 = col  
#ret: $v0 = square's value
getSquare: 
	sll $t0, $a0, 3
	add $t0,$t0,$a1
	lbu $v0,boardStart($t0)
	return#ret
	
prompts:#TODO
	la $a0, playerPrompt # load addr of playerPrompt into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	return #ret
	
win:
#TODO print win message
	j exit
	
# in: $a0 = cell content from array
# ret: $v0 = 1 = occ, 0 = not occ
getOcc:
	andi $t0, $a0, 0x80 # MS bit is if cell is occ
	sltiu $v0, $t1,1
	return
	
# in: $a0 = cell content from array
# ret: $v0 = team
getTeam:
	andi $t0, $a0, 0x40 # 7th MS bit is team
	sltiu $v0, $t1,1
	return

# in: $a0 = cell content from array
# ret: $v0 = run length
getRunLength:
	andi $t0, $a0, 0x30 # 5 and 6th MS bit is run length
	srl $v0, $a0, 4 #move to begining
	return
	
# in: $a0 = cell content from array
# ret: $v0 = run dir
getRunDir:
	andi $t0, $a0, 0xE #bit 1-3 is dir
	srl $v0, $t0, 1
	return
	
# in: $a0 = cell content from array
# ret: $v0 = 1 if multiple intersecting runs
getMultiRun:
	andi $v0, $a0, 1
	return
	
#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheck:
	beq $a0, 0, winCheckBottom
	beq $a1, 0, winCheckRightSide
	beq $a1, 6, winCheckLeftSide
	j winCheckMiddle

#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win	
winCheckBottom:
	beq $a1, 0, winCheckBottomRight
	beq $a1, 6, winCheckBottomLeft

#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheckRightSide:
	move $a0, $s2
	move $a1, $s3
	call checkBelow

checkBelow:
	subi $a0, $s2 ,1
	move $a1, $s3
	call getSquare
	move $v0, $a0
	call getTeam
	li $a3, 5
	beq $v0,$a2, calcRun
	return


#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheckLeftSide:


#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheckBottomRight:


#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheckBottomLeft:


#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheckMiddle:


#in: $a0 = row
#out: $v0 = col
gravity:
	lbu $v0, topStart($a0) #load next aval cell
	addiu $t0,$v0,1 #move up one
	sw $t0, topStart($a0) #store it back
	return #ret

	
exit:
	li $v0, 10
	syscall
