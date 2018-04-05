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
	movq	$10, %rsi				# Number base for multiplication
	movq	$0, %rcx				# Initialize the counter
	movq	$0, %rax				# Initialize the accumulator

atoi_loop:
	movq	$0, %rbx				# Clear rbx
	movb	(%rdi, %rcx, 1), %bl	# Get the next char to bl

	cmpb	$'\n', %bl				# End if char is newline
	je		atoi_end
	cmpb	$'0', %bl				# End if char is lower than 0
	jb		atoi_end
	cmpb	$'9', %bl				# End if char is greater than 9
	ja		atoi_end

	subb	$'0', %bl				# Convert ASCII to digit
	mulq	%rsi					# Multiply current sum by 10
	addq	%rbx, %rax				# Add current digit to the sum

	incq	%rcx					# Increment counter
	jmp		atoi_loop				# Go to the start of the loop

atoi_end:
	ret

