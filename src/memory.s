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
pop_to_fpu:
	fld	8(%rsp)				# Skip return address and load number to FPU
	ret	$4				# Return and free 4 bytes left after popping float

#
# Pops float number from FPU and pushes it on the stack
#
push_from_fpu:
	movq	(%rsp), %rax			# Make space for float by
	movq	%rax, -4(%rsp)			# copying return address 4 bytes lower
	subq	$4, %rsp			# Move stack pointer accordingly
	fstp	8(%rsp)				# Store float in created space
	ret					# Return to moved address

