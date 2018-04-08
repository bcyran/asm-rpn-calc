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

#
# Entry point
#
main:
	call	show_greeting			# Shwo greeting message
	
#
# Main program loop
#
main_loop:
	call	show_prompt			# Show prompt

	movq	$input, %rdi			# Parameter for clean_buffer (buffer to clean)
	movq	$INPUT_LEN, %rsi		# Parameter for clean_buffer (length of the buffer)
	call	clear_buffer			# Clear input buffer

	call	read_input			# Read user input
	
	cmpb	$'q', input			# If entered char is 'q'
	je	exit				# End program

	movq	$input, %rdi			# Parameter for calculate (input buffer)
	call	calculate			# Calculate value of the expression

	movq	$output, %rdi			# Parameter for ftoa (output buffer)
	movq	$2, %rsi			# Parameter for ftoa (precision)
	call	ftoa				# Convert result to ASCII string

	movq	$output, %rdi			# Parameter for print_string (buffer to print)
	movq	%rax, %rsi			# Parameter fro print_string (number of char to print)
	call	print_string			# Print result

	jmp	main_loop			# Jump to the start of the loop

