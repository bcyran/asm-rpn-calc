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
.global show_greeting
.global show_prompt
.global read_input
.global print_string
.global exit

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

