#
# Memory related functions
#

#
# Global functions declarations
#
.global clear_buffer
.global pop_to_fpu
.global	push_from_fpu

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

#
# Pops float number from the stack and pushes it to FPU
#
# return:
#	rax - status: 1 - success, -1 - error
#
pop_to_fpu:
	cmpl	$0, stack_counter		# If stack is not empty
	jne	pop_to_fpu_continue		# Continue popping
	movq	$-1, %rax
	ret					# Otherwise return with error code
pop_to_fpu_continue:
	fldl	8(%rsp)				# Skip return address and load number to FPU
	decl	stack_counter
	movq	$1, %rax
	ret	$8				# Return and free 8 bytes left after popping float

#
# Pops float number from FPU and pushes it on the stack
#
push_from_fpu:
	movq	(%rsp), %rax			# Make space for float by
	movq	%rax, -8(%rsp)			# copying return address 8 bytes lower
	subq	$8, %rsp			# Move stack pointer accordingly
	fstpl	8(%rsp)				# Store float in created space
	incl	stack_counter
	ret					# Return to moved address

