# asm-rpm-calc: simple reverse polish notation calculator
# Authors: Bazyli Cyran, Paweł Komorowski

#
# Initialized data
#
.data
	INPUT_LEN = 1024			# Size of the input buffer

	# Greeting message shown on program start
	greeting: .ascii "Kalkulator wyrażeń w odwrotnej notacji polskiej, podaj wyrażenie po znaku '>'.\n"
	greeting_len = . - greeting		# Length of the greeting message

	# Prompt for next calculation
	prompt: .ascii "> "
	prompt_len = . - prompt			# Length of the prompt

	precision: .int 2
	
	# Function names
	fx_sqrt: .ascii "sqrt"			# Square root
	fx_sin: .ascii "sin\0"			# Sine
	fx_cos: .ascii "cos\0"			# Cosine
	fx_abs: .ascii "abs\0"			# Absolute value
	fx_setp: .ascii "setp"			# Set precision

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
	.global	greeting
	.global greeting_len
	.global prompt
	.global	prompt_len
	.global input
	.global cur_token
	.global tmp
	.global precision
	.global	fx_sqrt
	.global	fx_sin
	.global fx_cos
	.global fx_abs
	.global fx_setp

#
# Entry point
#
main:
	call	show_greeting			# Shwo greeting message
	
	call	repl				# Start REPL loop
	
