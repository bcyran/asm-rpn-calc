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

