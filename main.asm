.data 
#board is a 2D array of 1 byte entrys, there is a lot of waste in this, its easier to do this vs. less waste  
boardStart: 
	.space 48 
board:
	.asciiz "" #TODO
playerPrompt: 
	.asciiz "" #TODO
player1Name:
	.asciiz "" #TODO
player2Name:
	.asciiz "" #TODO
winMsg:
	.asciiz "" #TODO

	#$s0 is always win condition, 10 for t1	  , 11 for t2
	#if game has computer it is on t1
	
.text
setup:
	jal prompts
	jal drawBoard
	#here $s1 is the type of game, 0 for 2 player, 1 for computer 
	bnez  $s1, compGameLoop
	
gamePlayLoop:
	#TODO add tile t0
	li $a2, 0
	j winCheck #BUG other team still plays if t0 wins
	#TODO add tile t1
	li $a2, 1
	j winCheck 
	bnez $s0, win #met win condition, BUG: if both teams win on the same turn t1 always wins, 
	j gamePlayLoop
	#you should never get here
	j exit
	
compGameLoop:
	#TODO add tile t0
	li $a2, 0
	j winCheck #BUG other team still plays if t0 wins
	#TODO add tile t1
	li $a2, 1
	j winCheck 
	bnez $s0, win #met win condition
	j compGameLoop 
	#should never get here
	j exit
	
drawBoard:
	la $a0, board # load addr of board into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	jr $31 #ret
	
#in: $a0 = row, $a1 = col  
#ret: $v0 = square's value
getSquare: 
	sll $t0, $a0, 3
	add $t0,$t0,$a1
	lbu $v0,boardStart($t0)
	jr $31 #ret
	
prompts:#TODO
	la $a0, playerPrompt # load addr of playerPrompt into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	jr $31 #ret
	
win:
#TODO print win message
	j exit
	
# in: $a0 = cell content from array
# ret: $v0 = 1 = occ, 0 = not occ
getOcc:
	andi $t0, $a0, 0x80 # MS bit is if cell is occ
	sltiu $v0, $t1,1
	
# in: $a0 = cell content from array
# ret: $v0 = team
getTeam:
	andi $t0, $a0, 0x40 # 7th MS bit is team
	sltiu $v0, $t1,1

# in: $a0 = cell content from array
# ret: $v0 = run length
getRunLength:
	andi $t0, $a0, 0x30 # 5 and 6th MS bit is run length
	srl $v0, $a0, 4 #move to begining
	
# in: $a0 = cell content from array
# ret: $v0 = run dir
getRunDir:
	andi $t0, $a0, 0xE #bit 1-3 is dir
	srl $v0, $t0, 1
	
#in: $a0= row, $a1 = col, $a2 =  team
#out: $s0 = win
winCheck:
	beq $a0, 0, winCheckBottom
	beq $a1, 0, winCheckRightSide
	beq $a1, 6, winCheckLeftSide
	j winCheckMiddle
	
winCheckBottom:


winCheckRightSide:


WinCheckLeftSide:


winCheckMiddle:

	
exit:
	li $v0, 10
	syscall
