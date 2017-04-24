
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
	.space 42 
topStart:
	.space 6
board:
	.asciiz "" #TODO
playerPrompt: 
	.asciiz "" #TODO
winMsg:
	.asciiz "" #TODO
newLine:
	.asciiz "\n"

	#$s0 is always win condition, 10 for t1	  , 11 for t2
	#$s1 is the type of game, 0 for 2 player, 1 for computer 
	#$s2 is row for last move
	#$s3 is col for last move
	#if game has computer it is on t1
	
.text
setup:
	call prompts
	li $a0, 1
	li $a1, 1
	call placePiece
	call drawBoard
	li $a0, 1
	li $a1, 1
	call placePiece
	call drawBoard
	bnez  $s1, compGameLoop
	
gamePlayLoop:
	#TODO add tile t0
	# check if player 0 has won
	li $a2, 0
	call winCheck #BUG other team still plays if t0 wins
	#TODO add tile t1
	# check if player 1 has won
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
	
# $a0: column
# $a1: player number
placePiece:
	call gravity
	move $t2, $a1
	move $a1, $v0
	call boardIndex
	sb $t2, boardStart($v0)
	return
	
drawBoard:
	# print bytes of the board
	li $t0, 5 # $t0: outer loop iterator (row)
	li $t1, -1 # $t1: outer loop number of iterations
	forLoop:
	
	li $t2, 0 # $t2: inner loop iterator (column)
	li $t3, 7 # $t3: inner loop number of iterations
	innerForLoop:

	# $t4 will be the index of the byte we're printing
	mul $t4, $t0, $t3
	add $t4, $t4, $t2
	lbu $a0, boardStart($t4)
	li $v0, 1
	syscall

	addi $t2, $t2, 1
	blt $t2, $t3, innerForLoop

	la $a0, newLine
	li $v0, 4
	syscall

	addi $t0, $t0, -1
	bgt $t0, $t1, forLoop

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
	andi $t0, $a0, 0x80 # MS (most significant) bit is if cell is occ(upied)
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
	break
	#beq $v0,$a2, calcRun
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


#in: $a0 = col
#out: $v0 = row
gravity:
	lbu $v0, topStart($a0) #load next aval cell
	addiu $t0,$v0,1 #move up one
	sb $t0, topStart($a0) #store it back
	return #ret

# $a0 = col
# $a1 = row
# $v0 = position in byte array for the board
boardIndex:
	li $t3, 7
	mul $v0, $a1, $t3
	add $v0, $v0, $a0
	return
	
exit:
	li $v0, 10
	syscall
