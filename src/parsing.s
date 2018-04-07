#
# Functions related to parsing user input
#

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
	ja	calculate_loop_number		# So handle it as a number

calculate_loop_addition:
	cmpb	$'+', cur_token(, 1)		# If operand is not '+' (plus)
	jne	calculate_loop_subtraction	# Jump to subtraction
	call	rpn_add				# Otherwise perform addition
	jmp	calculate_loop_end		# And jump to the end of the loop

calculate_loop_subtraction:
	jmp	calculate_loop_end

calculate_loop_number:
	pushq	%rdi				# Convert token to float
	movq	$cur_token, %rdi
	call	atof
	popq	%rdi
	subq	$4, %rsp			# Store number on the stack
	fstp	(%rsp)

calculate_loop_end:
	movq	%rbx, %rcx			# Update counter to end index of substring
	jmp	calculate_loop			# Jump to the start of the loop


calculate_return:
	fld	(%rsp)				# Return result to the st0
	addq	$4, %rsp
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

#
# Converts ASCII string to float
#
# params:
#	rdi - address of buffer containing ASCII string
# return:
#	st0 - value of number stored in string
#
atof:
	pushq	%rsi				# Backup registers used by the function
	pushq	%rcx
	pushq	%r8
	pushq	%rbx
	pushq	%rdx

	movq	$0, %rcx			# Initialize the input counter
	movq	$0, %rdx			# Initialize the integer part counter
	movq	$0, %r8				# Initialize negation flag
	
	pushq	%rdi				# Backup current parameter
	movq	$tmp, %rdi			# Parameter for clear_buffer
	movq	$INPUT_LEN, %rsi		# Parameter for clear_buffer
	call	clear_buffer			# Clear buffer
	popq	%rdi				# Restore parameter

	cmpb	$'-', (%rdi, %rcx, 1)		# If first char is not '-' (minus)
	jne	atof_int_loop			# Jump to extraction loop
	incq	%rcx				# Otherwise increment counter to skip it
	movq	$1, %r8				# And set negation flag

atof_int_loop:					# Get integer part of the nuber
	movb	(%rdi, %rcx, 1), %bl		# Get the next char to bl
	
	cmpb	$'.', %bl			# End integer extracion on '.' (period)
	je	atof_int_loop_end
	cmpb	$'\n', %bl			# End if char is newline
	je	atof_int_loop_end
	cmpb	$'0', %bl			# End if char is lower than 0
	jb	atof_int_loop_end
	cmpb	$'9', %bl			# End if char is greater than 9
	ja	atof_int_loop_end
	
	movb	%bl, tmp(, %rdx, 1)		# Copy char to temporary buffer

	incq	%rcx				# Increment input counter
	incq	%rdx				# Increment integer part counter
	jmp	atof_int_loop			# Jump to the start of the loop

atof_int_loop_end:				# Convert and load extracted integer part to FPU
	pushq	%rdi				# Backup parameter
	movq	$tmp, %rdi			# Parameter for atoi
	call	atoi				# Convert integer part to int
	popq	%rdi				# Restore parameter
	movq	%rax, -8(%rsp)			# Move converted number to stack's red zone
	fild	-8(%rsp)			# Load number to FPU
	
	cmpb	$'.', %bl			# If last character wasn't a period
	jne	atof_return			# End function
	incq	%rcx				# If last char was a period increment counter to skip it 
	movq	$0, %rdx			# Initialize fraction part counter

	pushq	%rdi				# Backup current parameter
	movq	$tmp, %rdi			# Parameter for clear_buffer
	movq	$INPUT_LEN, %rsi		# Parameter for clear_buffer
	call	clear_buffer			# Clear buffer
	popq	%rdi				# Restore parameter

atof_frac_loop:					# Extract fraction part of the number
	movb	(%rdi, %rcx, 1), %bl		# Get the next char to bl
	
	cmpb	$'\n', %bl			# End if char is newline
	je	atof_frac_loop_end
	cmpb	$'0', %bl			# End if char is lower than 0
	jb	atof_frac_loop_end
	cmpb	$'9', %bl			# End if char is greater than 9
	ja	atof_frac_loop_end

	movb	%bl, tmp(, %rdx, 1)		# Copy char to temporary buffer

	incq	%rcx				# Increment input counter
	incq	%rdx				# Incrememnt fraction part counter
	jmp	atof_frac_loop			# Jump to the start of the loop

atof_frac_loop_end:
	movq	$tmp, %rdi			# Parameter for atoi, no need to backup
	call	atoi				# Convert frac part to int
	movq	%rax, -8(%rsp)			# Move converted number to stack's red zone
	fild	-8(%rsp)			# Load number into the FPU

	movq	$10, %rdi			# int_pow parameter (base)
	movq	%rdx, %rsi			# int_pow parameter (exponent)
	call	int_pow				# Calculate denominator by raising 10 to powwer od fraction counter
	movq	%rax, -8(%rsp)			# Move denominator to memory for FPU division

	fidiv	-8(%rsp)			# Divide numerator in st0 by denominator
	faddp					# Add fraction part in st0  to the integer part in st1

	cmpq	$0, %r8				# If negation flag is set to 0
	je	atoi_return			# Jump to return
	fchs					# Otherwise negate st0
	
atof_return:
	popq	%rdx				# Restore values of modified registers
	popq	%rbx
	popq	%r8
	popq	%rcx
	popq	%rsi
	ret

#
# Convert ASCII string to integer
#
# params:
# 	rdi - address of buffer containing ASCII string
# return:
# 	rax - value of number stored in string
#
atoi:
	pushq	%rsi				# Backup registers used by the function
	pushq	%rcx
	pushq	%r8
	pushq	%rbx
	pushq	%rdx

	movq	$10, %rsi			# Number base for multiplication
	movq	$0, %rcx			# Initialize the counter
	movq	$0, %rax			# Initialize the accumulator
	movq	$0, %r8				# Initialize negation flag

	cmpb	$'-', (%rdi, %rcx, 1)		# If first char is not '-' (minus)
	jne	atoi_loop			# Jump to loop
	incq	%rcx				# Otherwise increment counter to skip it
	movq	$1, %r8				# And set negation flag

atoi_loop:
	movq	$0, %rbx			# Clear rbx
	movb	(%rdi, %rcx, 1), %bl		# Get the next char to bl

	cmpb	$'\n', %bl			# End if char is newline
	je	atoi_end
	cmpb	$'0', %bl			# End if char is lower than 0
	jb	atoi_end
	cmpb	$'9', %bl			# End if char is greater than 9
	ja	atoi_end

	subb	$'0', %bl			# Convert ASCII to digit
	mulq	%rsi				# Multiply current sum by 10
	addq	%rbx, %rax			# Add current digit to the sum

	incq	%rcx				# Increment counter
	jmp	atoi_loop			# Go to the start of the loop

atoi_end:
	cmpq	$0, %r8				# If negation flag is set to 0
	je	atoi_return			# Jump to return
	negq	%rax				# Otherwise negate result

atoi_return:
	popq	%rdx				# Restore values of modified registers
	popq	%rbx
	popq	%r8
	popq	%rcx
	popq	%rsi
	ret

