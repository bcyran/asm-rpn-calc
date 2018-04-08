#
# Functions for converting between data types
#

#
# Global functions declarations
#
.global atof
.global atoi
.global itoa

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
	fildq	-8(%rsp)			# Load number to FPU
	
	cmpb	$'.', %bl			# If last character wasn't a period
	jne	atof_sign			# End function
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
	fildq	-8(%rsp)			# Load number into the FPU

	movq	$10, %rdi			# int_pow parameter (base)
	movq	%rdx, %rsi			# int_pow parameter (exponent)
	call	int_pow				# Calculate denominator by raising 10 to powwer od fraction counter
	movq	%rax, -8(%rsp)			# Move denominator to memory for FPU division

	fidiv	-8(%rsp)			# Divide numerator in st0 by denominator
	faddp					# Add fraction part in st0  to the integer part in st1

atof_sign:
	cmpq	$0, %r8				# If negation flag is set to 0
	je	atof_return			# Jump to return
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

#
# Converts integer to ASCII string
#
# params:
#	rdi - integer to convert
#	rsi - address of output buffer
# return:
#	rax - length of the output string
#
itoa:
	pushq	%rcx				# Backup registers modified by function
	pushq	%rbx
	pushq	%rdx
	pushq	%r8

	movq	%rdi, %rax			# Move integer to the accumulator
	movq	$0, %rcx			# Initialize the counter
	movq	$10, %rbx			# 10 for division
	movq	$0, %r8				# Initialize negation flag

	cmpq	$0, %rax			# If number is not negative
	jge	itoa_loop			# Jump to conversion loop
	neg	%rax				# Negate the number
	movq	$1, %r8				# Set negation flag

itoa_loop:
	movq	$0, %rdx			# Clear rdx as dividend is rdx:rax
	div	%rbx				# Divide number by 10
	pushq	%rdx				# Push remainder (next digit) to the stack
	incq	%rcx				# Increment counter
	cmpq	$0, %rax			# If quotient is larger than 0
	ja	itoa_loop			# Jump to the start of the loop

	movq	%rcx, %rdx			# Copy counter to rdx
	movq	$0, %rcx			# Reset counter to 0
	
	cmpq	$0, %r8				# If negation flag is not set
	je	itoa_rev_loop			# Jump to the rev loop
	movq	$'-', (%rsi, %rcx, 1)		# Put '-' (minus) as the first character in output buffer
	incq	%rcx				# Increment counter
	incq	%rdx				# Increment total count to compensate for additional character

itoa_rev_loop:					# Reverse order of digits and convert them to ASCII
	popq	%rbx				# Pop digit from the stack
	addq	$'0', %rbx			# Convert digit to ASCII char
	movb	%bl, (%rsi, %rcx, 1)		# Put character in output buffer
	incq	%rcx				# Increment the counter
	cmpq	%rdx, %rcx			# If counter is smaller than number of digits
	jb	itoa_rev_loop			# Jump to the start of the loop

	movq	$'\n', (%rsi, %rcx, 1)		# Add trailing newline
	incq	%rcx				# Count the newline
	
	movq	%rcx, %rax			# Return length of the string

	popq	%r8				# Restore registers
	popq	%rdx
	popq	%rbx
	popq	%rcx

	ret

