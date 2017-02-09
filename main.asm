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
	#TODO add tile t1
	#TODO win check
	bnez $s0, win #met win condition
	j gamePlayLoop
	#you should never get here
	j exit
	
compGameLoop:
	#TODO add tile t0
	#TODO add tile t1
	#TODO win check
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
	

	
exit:
	li $v0, 10
	syscall
