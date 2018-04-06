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
calculate:
	// TODO Calculate value of the RPN expression	
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

#
# Clears buffer
#
# params:
#	rdi - address of buffer to clear
#	rsi - size of the buffer
#
clear_buffer:
	pushq	%rcx				# Backup rcx value
	movq	$0, %rcx			# Initialize the counter

clear_buffer_loop:
	movq	$0, (%rdi, %rcx, 1)		# Write 0 to current byte
	incq	%rcx				# Increment counter
	cmpq	%rsi, %rcx			# Compare counter with buffer's size
	jl	clear_buffer_loop		# If counter is lesser jump to start of the loop

clear_buffer_return:
	popq	%rcx				# Restore value to rcx
	ret

