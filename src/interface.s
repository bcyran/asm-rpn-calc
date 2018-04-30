#
# Functions related to user interface
# 

#
# Constants
#
SYS_READ = 0
SYS_WRITE = 1
SYS_IOCTL = 16
SYS_EXIT = 60
STD_IN = 0
STD_OUT = 1
EXIT_SUCCESS = 0

#
# Global functions decalrations
#
.global repl
.global show_greeting
.global show_prompt
.global read_input
.global print_string
.global exit

#
# Read-Eval-Print Loop
#
repl:
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
	movl	precision, %esi			# Parameter for ftoa (precision)
	call	ftoa				# Convert result to ASCII string

	movq	$output, %rdi			# Parameter for print_string (buffer to print)
	movq	%rax, %rsi			# Parameter fro print_string (number of char to print)
	call	print_string			# Print result

	jmp	repl				# Jump to the start of the loop
	ret

#
# Shows greeting text
#
show_greeting:
	movq	$greeting, %rdi
	movq	$greeting_len, %rsi
	call	print_string
	ret

#
# Shows prompt
#
show_prompt:
	movq	$prompt, %rdi
	movq	$prompt_len, %rsi
	call	print_string
	ret

#
# Reads user enetered text from std in to input buffer
#
read_input:
	movq	$SYS_READ, %rax
	movq	$STD_IN, %rdi
	movq	$input, %rsi
	movq	$INPUT_LEN, %rdx
	syscall
	ret

#
# Prints string
#
# params:
#	rdi - buffer to print
#	rsi - length of the string to print
#
print_string:
	movq	%rsi, %rdx
	movq	%rdi, %rsi
	movq	$SYS_WRITE, %rax
	movq	$STD_OUT, %rdi
	syscall
	ret

#
# Exits from program with success code
#
exit:
	movq	$SYS_EXIT, %rax
	movq	$EXIT_SUCCESS, %rdi
	syscall

