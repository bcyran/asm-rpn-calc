#
# Functions for converting between data types
#

#
# Initialized data
#
.data
	nan: .ascii "NaN\n"			# NaN string
	nan_len = . - nan			# NaN string length
	inf: .ascii "inf\n"			# Infinity string
	inf_len = . - inf			# Infinity string length

.text

#
# Global functions declarations
#
.global atof
.global atoi
.global ftoa
.global itoa

#
# Converts ASCII string to float
#
# params:
#	rdi - address of buffer containing ASCII string
# return:
#	st0 - value of number stored in string
#	rax - status: 1 - success, -1 - error
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
	cmpb	$0, %bl				# End if char is \0
	je	atof_int_loop_end
	cmpb	$'0', %bl			# Return error if char is lower than 0
	jb	atof_error
	cmpb	$'9', %bl			# Return error if char is greater than 9
	ja	atof_error
	
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
	cmpb	$0, %bl				# End if char is \0
	je	atof_frac_loop_end
	cmpb	$'0', %bl			# Return error if char is lower than 0
	jb	atof_error
	cmpb	$'9', %bl			# Return error if char is greater than 9
	ja	atof_error

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
	movq	$1, %rax
	ret

atof_error:					# Return with error code
	popq	%rdx
	popq	%rbx
	popq	%r8
	popq	%rcx
	popq	%rsi
	movq	$-1, %rax
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
# Converts float number to ASCII string
#
# params:
#	st0 - float number to convert
#	rdi - address of output buffer
#	rsi - precision of the conversion (number of decimal places)
# return:
#	rax - length of the output string
#
ftoa:
	pushq	%rbx				# Backup registers
	pushq	%rcx
	pushq	%rdx
	pushq	%r8

	movq	$0, %r8				# Initialize the negation flag
	movq	$0, %rcx			# Initialize output char counter

	fxam					# Examine number in st0
	fstsw	%ax				# Store FPU status word in ax
	andw	$0b0100010100000000, %ax	# Clean all bits besides C0, C2, C3
	cmpw	$0b0000000100000000, %ax	# Check if number is NaN (only C0)
	je	ftoa_nan			# And display NaN if it is
	cmpw	$0b0000010100000000, %ax	# Check if number is inf (C0 and C2)
	je	ftoa_inf			# And display inf if it is
	jmp	ftoa_number			# Otherwise treat it as a number

ftoa_nan:					# Display NaN
	movl	nan, %eax			# Copy NaN string to eax
	movl	%eax, (%rdi)			# Copy NaN string to the output
	movq	$nan_len, %rcx			# Add NaN string length to the counter
	jmp	ftoa_return			# Return

ftoa_inf:					# Display inf
	movl	inf, %eax			# Copy inf string to eax
	movl	%eax, (%rdi)			# Copy inf string to the output
	movq	$inf_len, %rcx			# Add inf string length to the counter
	jmp	ftoa_return			# Return

ftoa_number:
	pushq	%rdi				# Backup rdi
	movq	$10, %rdi			# Parameter for int_pow (base), exponent already in rsi
	call	int_pow				# Calculate fraction denominator (10^precision)
	popq	%rdi				# Restore rdi
	movq	%rax, -8(%rsp)			# Put denominator in stack's red zone
	movq	%rax, %rbx			# Save denominator for later division

	fimul	-8(%rsp)			# Multiply number by fraction denominator
	frndint					# Round the number to the nearest integer

	movq	$0, -8(%rsp)			# Clear red zone
	fistpq	-8(%rsp)			# Store number in red zone
	movq	-8(%rsp), %rax			# Move number to the accumulator
	
	cmpq	$0, %rax			# If number is not negative
	jge	ftoa_integer			# Go to conversion
	negq	%rax				# Otherwise negate the number
	movq	$1, %r8				# Set negation flag
	movb	$'-', (%rdi, %rcx, 1)		# Set '-' ad first char of output
	incq	%rcx				# Increment output counter

ftoa_integer:
	movq	$0, %rdx			# Clear rdx for division
	divq	%rbx				# Divide number by fraction part denominator

	pushq	%rdi				# Backup parameters
	pushq	%rsi
	addq	%rcx, %rdi			# Add char counter to the output address
	movq	%rdi, %rsi			# Parameter fot itoa (output)
	movq	%rax, %rdi			# Parameter for itoa (number)
	call	itoa				# Convert integer part to string
	popq	%rsi				# Restore parameters
	popq	%rdi

	addq	%rax, %rcx			# Update char counter

	cmpq	$0, %rsi			# End here if precision is set to 0
	je	ftoa_return
	
	decq	%rcx				# Decrement char counter to overwrite integer newline
	movb	$'.', (%rdi, %rcx, 1)		# Add decimal point
	incq	%rcx				# Increment char counter

ftoa_fraction:
	pushq	%rdi
	pushq	%rsi
	addq	%rcx, %rdi			# Add char counter to the output address
	movq	%rdi, %rsi			# itoa parameter
	movq	%rdx, %rdi			# itoa parameter
	call	itoa				# Convert fraction part
	popq	%rsi
	popq	%rdi

	addq	%rax, %rcx			# Update char counter

	movq	%rsi, %rdx			# Copy of precision
	subq	%rax, %rdx			# Subtract fraction part length from precision to calculate offset
	incq	%rdx				# Add 1 to account for newline char

	cmpq	$0, %rdx			# Skip adding leading zeros
	jle	ftoa_return			# If offset equals zero

leading_zeros:					# Add missing leading zeros to fraction e.g. 0.1 -> 0.0001
	pushq	%rsi				# Backup registers
	pushq	%rdi
	pushq	%rcx
	pushq	%rax
	movq	%rdi, %rsi			# Source - Copy address of the buffer
	addq	%rcx, %rsi			# Add char counter
	decq	%rsi				# Decrement to point to the last char
	movq	%rsi, %rdi			# Destination - Copy source address to destination
	addq	%rdx, %rdi			# Source address + offset
	movq	%rax, %rcx			# Count - fraction length
	std					# Direction - decrement
	rep	movsb				# Move fraction part by offset
	movq	$'0', %rax			# Fill character - '0' character
	movq	%rdx, %rcx			# Count - offset
	rep	stosb				# Fill gap with zeros
	popq	%rax				# Restore registers
	popq	%rcx
	popq	%rdi
	popq	%rsi

	addq	%rdx, %rcx			# Update char counter with offset

ftoa_return:
	movq	%rcx, %rax			# Return length of the string

	popq	%r8				# Restore registers
	popq	%rdx
	popq	%rcx
	popq	%rbx
		
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

