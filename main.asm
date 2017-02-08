.data 
#board is a 2D array of 2 bit entrys, 1/2 word per col, therefore wasting 2 bits / col or 12 bits across board
boardStart: 
	.half 0
	.half 0
	.half 0
	.half 0
	.half 0
	.half 0
board:
	.asciiz "TODO1 " #TODO
playerPrompt: 
	.asciiz "TODO2 " #TODO

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
	bne $s0,$0, win #met win condition
	j gamePlayLoop
	#you should never get here
	j exit
	
compGameLoop:
	
	bne $s0,$0, win #met win condition
	j gamePlayLoop
	#should never get here
	j exit
	
drawBoard:
	la $a0, board # load addr of board into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	jr $31 #ret
	
#in: $a1 = row ? ,$a2 = col ?
#ret: $v0 = square's value
getSquare: 
	sll  $t0,$a2,1 #calc offset col offset, really $t0 = $a2 * 2^1, 16 bits/col or 2 bytes / col
	lhu  $t0,boardStart($t0) #load the col
	sll  $t1,$a1,1 #calc ofset into the cell, 2 bits per cell, this is really $t1 = $a1 << 2^1 == $a1 * 2
	srlv $t0,$t0,$t1 #shift cell into first 2 bits
	andi $v0,$t0,0x3 #mask off first 2 bits (wanted cell), opt.
	jr   $31 #ret
	
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
