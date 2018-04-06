#
# Functions related to user interface
# 

#
# Constants
#
SYS_READ = 0
SYS_WRITE = 1
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
.global exit

#
# Show greeting text
#
show_greeting:
	movq	$SYS_WRITE, %rax
	movq	$STD_OUT, %rdi
	movq	$greeting, %rsi
	movq	$greeting_len, %rdx
	syscall
	ret

#
# Show prompt
#
show_prompt:
	movq	$SYS_WRITE, %rax
	movq	$STD_OUT, %rdi
	movq	$prompt, %rsi
	movq	$prompt_len, %rdx
	syscall
	ret

#
# Read user enetered text from std in to input buffer
#
read_input:
	movq	$SYS_READ, %rax
	movq	$STD_IN, %rdi
	movq	$input, %rsi
	movq	$INPUT_LEN, %rdx
	syscall
	ret

#
# Exit from program with success code
#
exit:
	movq	$SYS_EXIT, %rax
	movq	$EXIT_SUCCESS, %rdi
	syscall

