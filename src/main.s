# asm-rpm-calc: simple reverse polish notation calculator
# Authors: Bazyli Cyran, Paweł Komorowski

#
# Initialized data
#
.data
	INPUT_LEN = 1024			# Size of the input buffer
	precision: .int 2			# Default calculation precision
	stack_counter: .int 0			# RPN stack counter
	
#
# Uninitialized data
#
.bss
	.comm input, 1024			# User input buffer
	.comm cur_token, 1024			# Token storage for parser
	.comm output, 1024			# Output buffer
	.comm tmp, 1024				# Temporary storage space

#
# Program
#
.text
	.global main				# Declare global function and variables
	.global INPUT_LEN
	.global precision
	.global stack_counter

#
# Entry point
#
main:
	call	show_greeting			# Shwo greeting message
	
	call	repl				# Start REPL loop
	
