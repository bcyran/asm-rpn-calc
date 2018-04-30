#
# Functions related to parsing user input
#

#
# Initialized data
#
.data
	fx_sqrt: .ascii "sqrt"			# Square root
	fx_sin: .ascii "sin\0"			# Sine
	fx_cos: .ascii "cos\0"			# Cosine
	fx_abs: .ascii "abs\0"			# Absolute value
	fx_setp: .ascii "setp"			# Set precision

.text

#
# Global functions declarations
#
.global calculate

#
# Calculate value of expression in input buffer
# 
# params:
#	rdi - address of input buffer
#
# return:
#	st0 - result
#	rax - status: 1 - return number, 0 - no return, -1 - parsing error, -2 - fpu error
#
calculate:
	movq	$0, %rcx			# Initialize counter

calculate_loop:
	pushq	%rdi				# Clear token buffer
	movq	$cur_token, %rdi
	movq	$INPUT_LEN, %rsi
	call	clear_buffer
	popq	%rdi

	movq	$cur_token, %rsi		# get_token param (output buffer)
	movq	%rcx, %rdx			# get_token param (starting index)
	call	get_token			# Get the next token

	movq	%rax, %rbx			# Copy token end index
	cmpq	$0, %rdx			# Empty token means end of string
	je	calculate_return		# So end function

	cmpq	$1, %rdx			# Token can't be an operand if it's longer than 1 char
	ja	calculate_loop_function
	cmpb	$'0', cur_token			# It's operand if it's beyond 0
	jb	calculate_loop_operand
	cmpb	$'9', cur_token			# It's operand if it's above 9
	ja	calculate_loop_operand
	jmp	calculate_loop_function		# Otherwise it's a function or number

calculate_loop_operand:
	call	pop_to_fpu			# Pop two arguments from the stack
	call	pop_to_fpu

calculate_loop_add:				# Addition
	cmpb	$'+', cur_token			# If operand is not '+' (plus)
	jne	calculate_loop_sub		# Jump to subtraction
	faddp
	jmp	calculate_loop_end		# And jump to the end of the loop

calculate_loop_sub:				# Subtraction
	cmpb	$'-', cur_token
	jne	calculate_loop_mul
	fsubp
	jmp	calculate_loop_end

calculate_loop_mul:				# Multiplication
	cmpb	$'*', cur_token
	jne	calculate_loop_div
	fmulp
	jmp	calculate_loop_end

calculate_loop_div:				# Division
	cmpb	$'/', cur_token
	jne	calculate_loop_pow
	fdivp
	jmp	calculate_loop_end

calculate_loop_pow:				# Exponentiation
	cmpb	$'^', cur_token
	jne	calculate_loop_number
	call	float_pow
	jmp	calculate_loop_end

calculate_loop_function:			# Functions
	movl	cur_token, %eax			# Copy current token to eax for comparison

calculate_loop_sqrt:				# Square root
	cmpl	%eax, fx_sqrt
	jne	calculate_loop_sin
	call	pop_to_fpu
	fsqrt
	jmp	calculate_loop_end
	
calculate_loop_sin:				# Sine
	cmpl	%eax, fx_sin
	jne	calculate_loop_cos
	call	pop_to_fpu
	fsin
	jmp	calculate_loop_end

calculate_loop_cos:				# Cosine
	cmpl	%eax, fx_cos
	jne	calculate_loop_abs
	call	pop_to_fpu
	fcos
	jmp	calculate_loop_end

calculate_loop_abs:				# Absolute value
	cmpl	%eax, fx_abs
	jne	calculate_loop_setp
	call	pop_to_fpu
	fabs
	jmp	calculate_loop_end

calculate_loop_setp:				# Set precision
	cmpl	%eax, fx_setp
	jne	calculate_loop_number
	call	pop_to_fpu
	fistpl	-8(%rsp)
	movl	-8(%rsp), %eax
	movl	%eax, precision
	fldz
	movq	$0, %rax			# Status - no return
	ret

calculate_loop_number:
	pushq	%rdi				# Convert token to float
	movq	$cur_token, %rdi
	call	atof
	popq	%rdi
	cmpq	$-1, %rax			# If atof returned error
	je	calculate_parsing_error		# Return parsing error
	
calculate_loop_end:
	cmpq	$-1, %rax			# If one of the pops returned error
	je	calculate_parsing_error		# Return parsing error
	fstsw	%ax				# Store FPU status word in ax
	andw	$0b0000000000111111, %ax	# Clean all flags besides error summary
	cmpw	$0, %ax				# If error summary flag is set
	jne	calculate_fpu_error		# Return FPU error
	call	push_from_fpu			# Push new number or result to the stack
	movq	%rbx, %rcx			# Update counter to end index of substring
	jmp	calculate_loop			# Jump to the start of the loop

calculate_return:				# Return with success code
	call	pop_to_fpu
	cmpq	$-1, %rax			# If pop returned error
	je	calculate_parsing_error		# Return parsing error
	movq	$1, %rax			# Status - return number
	ret

calculate_parsing_error:			# Return with -1 code
	movq	$-1, %rax
	jmp	calculate_error

calculate_fpu_error:				# Return with -2 code
	fclex					# Clean error flags
	movq	$-2, %rax
	jmp	calculate_error

calculate_error:				# Clean stack and return with error code
	movq	$0, %rbx			# Clean rbx
	movl	stack_counter, %ebx		# Copy stack counter to rbx
	shlq	$3, %rbx			# Multiply by 8 bytes
	addq	%rbx, %rsp			# Remove elements from the stack
	movq	$0, stack_counter		# Clean stack counter
	ret

#
# Finds substring from given starting index to next space in input buffer and puts found substring in output buffer.
#
# params:
#	rdi - address of input buffer
#	rsi - address of output buffer
#	rdx - starting index
# return:
#	rax - end index of the substring
#	rdx - length of the substring
#
get_token:
	pushq	%rcx				# Backup modified registers
	pushq	%rbx

	movq	%rdx, %rax			# Initialize input counter
	movq	$0, %rcx			# Initialize substring counter

get_token_loop:
	movb	(%rdi, %rax, 1), %bl		# Get next chat to bl

	cmpb	$'\n', %bl			# End if char is newline
	je	get_token_return
	
	cmpb	$' ', %bl			# If char is space
	je	get_token_space			# Handle this case

	movb	%bl, (%rsi, %rcx, 1)		# Otherwise copy current char to output buffer
	incq	%rax				# Increment input counter
	incq	%rcx				# And substring counter
	jmp	get_token_loop			# Jump to the start of the lopp

get_token_space:				# Handle space as current char
	cmpq	$0, %rcx			# If substring counter is not equal zero
	jne	get_token_return		# End function
	incq	%rax				# Otherwise increment input counter to skip the space
	jmp	get_token_loop			# End jump to the start of the loop

get_token_return:
	movq	%rcx, %rdx
	popq	%rbx				# Restore registers
	popq	%rcx
	ret

