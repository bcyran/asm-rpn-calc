# asm-rpm-calc: simple reverse polish notation calculator
# Authors: Bazyli Cyran, Paweł Komorowski

#
# Initialized data
#
.data
	# Size of the input buffer
	INPUT_LEN = 1024

	# Greeting message shown on program start
	greeting: .ascii "Kalkulator wyrażeń w odwrotnej notacji polskiej, podaj wyrażenie po znaku '>'.\n"
	greeting_len = . - greeting

	# Prompt for next calculation
	prompt: .ascii "> "
	prompt_len = . - prompt

#
# Uninitialized data
#
.bss
	# User input buffer
	.comm input, 1024
	# Temporary storage space
	.comm tmp, 1024


#
# Program
#
.text
	.global main
	.global INPUT_LEN
	.global	greeting
	.global greeting_len
	.global prompt
	.global	prompt_len
	.global input
	.global tmp

#
# Entry point
#
main:

	# Show greeting
	call	show_greeting
	
#
# Main program loop
#
main_loop:
	# Show prompt
	call	show_prompt
	# Read input
	call	read_input

	# Parameter for calculate (input buffer)
	movq	$input, %rdi
	# Calculate value of the expression
	call	calculate

	jmp	main_loop

	# Exit from program
	call	exit
	
