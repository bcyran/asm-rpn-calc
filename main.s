# SYSTEM CALLS
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

# I/O
STD_IN = 0
STD_OUT = 1

# OTHERS
EXIT_SUCCESS = 0
INPUT_LEN = 1024


# INITIALIZED BUFFERS
.data
# Greeting message shown on program start
greeting: .ascii "Kalkulator wyrażeń w odwrotnej notacji polskiej, podaj wyrażenie po znaku '>'.\n"
greeting_len = . - greeting
# Prompt for next calculation
prompt: .ascii "> "
prompt_len = . - prompt


# UNINITIALIZED BUFFERS
.bss
# User input buffer
.comm input, 1024


# PROGRAM
.text
.global main
main:


# Show greeting text
greet:
	movq	$SYS_WRITE, %rax
	movq	$STD_OUT, %rdi
	movq	$greeting, %rsi
	movq	$greeting_len, %rdx
	syscall


// TODO Well, the entire program


# Exit from program with success code
exit:
	movq	$SYS_EXIT, %rax
	movq	$EXIT_SUCCESS, %rdi
	syscall

