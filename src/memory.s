#
# Memory related functions
#

#
# Global functions declarations
#
.global clear_buffer

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

