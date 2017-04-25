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
	.space 7
board:
	.asciiz "" # This is filled by draw board when being printed.
playerPrompt: 
	.asciiz "Type a column (1-7) to drop your next piece.\n"
player1Win:
	.asciiz "Player 1 (human) won!"
player2Win:
	.asciiz "Player 2 (computer) won!"
winMsg:
	.asciiz "" #TODO: Change this per user (eg: Player (PLYAER_NAME) won!), done at runtime.
invalidColumn:
	.asciiz "Please enter a column number between 1 and 7 inclusive."
fullColumn:
	.asciiz "That column is already full. Please choose another column."
newLine:
	.asciiz "\n"
	
# Empty space and player peices to draw the 2D byte-array board with
emptySpace:
	.asciiz "|_|"
player1Piece:
	.asciiz "|X|"
player2Piece:
	.asciiz "|O|"

	#$s0 is always win condition, 10 for t1, 11 for t2
	#$s1 is the type of game, 0 for 2 player, 1 for computer 
	#$s2 is row for last move
	#$s3 is col for last move
	#if game has computer it is on t1
	
.text
gamePlayLoop:
	# Get input from player 1 (human player)
	call input
	
	move $a0, $v0 # Load the returned input into the column parameter
	li $a1, 1 # Load player 1 (human) into the player parameter to set the piece
	call placePiece
	
	# Move the col into the first param
	li $a0, 0
	# Move the row into the second param
	li $a1, 6
	# Set the player param
	li $a2, 1
	call winCheck
	
	call drawBoard
	
	# TODO: Check if player 1 (human) has won
	#li $a2, 1
	#call winCheck
	
	# Get input from the computer player (next valid column)
	call compInput
	
	# What I assume we can do here is check topStart if the column that input (human or comp) returns is valid (as in not greater than 5, assuming topStart ranges from 0-5).
	# If we get an invalid input for a column, ask the prompt again (j input)
	
	# Place the piece into the column loaded from $v0
	move $a0, $v0
	li $a1, 2 # Load player 2 (computer) into the player parameter
	call placePiece
	
	# print new line
	la $a0, newLine
	li $v0, 4
	syscall
	
	call drawBoard
	
	# TODO: Check if player 2 (computer) has won
	#li $a2, 2
	#call winCheck 
	j gamePlayLoop
	
# $v0 = Sanitized column number from human input (should be 1-7)
input:
	# TODO: Get input from human and load into $v0
	la $a0, playerPrompt # load addr of playerPrompt into reg a0
	li $v0, 4 # syscall # for "print string"
	syscall
	li $v0, 5
	syscall
	
	# check if column was between 1 and 7
	blez $v0, printInvalidColumn
	li $t3, 7
	bgt $v0, $t3, printInvalidColumn
	
	addi $v0, $v0, -1 # subtract 1 from the input to get the column number from (0-6)
	
	# check if column is already full
	move $a0, $v0
	call topPiece
	li $t1, 5
	bgt $v0, $t1, printFullColumn
	move $v0, $a0
	
	return # end call input

# $v0 = The computer player's decided column to place its next piece
compInput:
	# TODO: Find the next valid column to place a piece and load it into $v0
	li $v0, 2
	return

# $a0: column
# $a1: player number
# return the row the piece dropped to 
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
	# $t5 is the actual value at that index
	lbu $t5, boardStart($t4)
	beq $t5, 1, printPlayer1
	beq $t5, 2, printPlayer2
	beqz $t5, printEmptySpace
	
	continue:

	addi $t2, $t2, 1
	blt $t2, $t3, innerForLoop

	# print new line
	la $a0, newLine
	li $v0, 4
	syscall

	addi $t0, $t0, -1
	bgt $t0, $t1, forLoop

	la $a0, board # load addr of board into reg a0
	li $v0, 4 # syscall number for "print string"
	syscall
	return #ret

printInvalidColumn:
	li $v0, 4
	la $a0, invalidColumn
	syscall
	j input

printFullColumn:
	li $v0, 4
	la $a0, fullColumn
	syscall
	j input
	
printEmptySpace:
	li $v0, 4
	la $a0, emptySpace
	syscall
	j continue
printPlayer1:
	li $v0, 4
	la $a0, player1Piece 
	syscall
	j continue
printPlayer2:
	li $v0, 4
	la $a0, player2Piece
	syscall
	j continue

# $a0 = player (1 or 2)
win:
	# Draw the final board
	call drawBoard
	# Print win message for player 1 or 2
	beq $a0, 1, printPlayer1Won
	beq $a0, 2, printPlayer2Won

printPlayer1Won:
	li $v0, 4
	la $a0, player1Win
	syscall
	j exit

printPlayer2Won:
	li $v0, 4
	la $a0, player2Win
	syscall
	j exit

# $a0: column
# $v0: row of top piece of that column
topPiece:
	lbu $v0, topStart($a0)
	return

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
	
# $a0 = col of the piece
# $a1 = row of the piece
# $a2 = player placing the piece
# The check(Direction) functions will jump to win if the player won
winCheck:
	# If the column is more than or equal to 3, checkLeft
	#bge $a0, 3, checkLeft
		
	# If the column is less than or equal to 3, checkRight
	#ble $a0, 3, checkRight 
		
	# If the row is more than or equal to 3, checkUp
	bge $a1, 3, checkUp
	
	# If the row is less than or equal to 3, checkDown
	#ble $a1, 3, checkDown
	
	# TODO: Check diagonals
	
	return

# Parameters are for the following check(Direction) functions
# These functions should check recursively
# $a0 = col
# $a1 = row
# $a2 = player (1 or 2)
# $a3 = current count (starts at 0, when it hits 3, return win)

checkUp:
	# All the other functions with check(Direction) should folow this pattern:
	# Recursively check the direction, if the player wins, jump to setWin

	# Check the current piece if it's the player's
	call boardIndex
	
	# Get the piece from the position in the board returned by boardIndex and load the value into $t6
	lbu $t6, boardStart($v0)
	
	# If the piece is not the current player's ($a2) piece, exit
	bne $t6, $a2, exitCheckUp
	
	# Increment the row up 1 (subtract since 0 is the top)
	addi $a1, $a1, -1
	
	# Increment the count up 1
	addi $a3, $a3, 1
	
	# Branch checkUp if count is less than 3
	blt $a3, 3, checkUp
	
	# Branch win if count is 3
	move $a0, $a2
	beq $a3, 3, win
	
	# Return if the current piece is not the player's piece (base case)
	exitCheckUp:
		return
	
checkUpRight:
	return
	
checkRight:
	return
	
checkDownRight:
	return
	
checkDown:
	# Check the current piece if it's the player's
	call boardIndex
	
	# Get the piece from the position in the board returned by boardIndex and load the value into $t6
	lbu $t6, boardStart($v0)
	
	# If the piece is not the current player's ($a2) piece, exit
	bne $t6, $a2, exitCheckDown
	
	# Increment the row down 1 (add since 0 is the top)
	addi $a1, $a1, 1
	
	# Increment the count up 1
	addi $a3, $a3, 1
	
	# Branch checkUp if count is less than 3
	blt $a3, 3, checkDown
	
	# Branch win if count is 3
	move $a0, $a2
	beq $a3, 3, win
	
	# Return if the current piece is not the player's piece (base case)
	exitCheckDown:
		return
	
checkDownLeft:
	return
	
checkLeft:
	return
	
checkUpLeft:
	return
exit:
	li $v0, 10
	syscall

