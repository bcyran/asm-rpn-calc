#
# Mathematical functions
#

#
# Global functions declarations
#
.global int_pow

#
# Raises given base to given power, both parameters must be integers
#
# params:
#	rdi - base
#	rsi - exponent
# return:
#	rax - result
#
int_pow:
	pushq	%rcx				# Backup registers
	pushq	%rdx
	movq	$0, %rcx			# Initialize the counter
	movq	$1, %rax			# Initialize the accumulator

int_pow_loop:
	mulq	%rdi				# Multiply current sum by base
	incq	%rcx				# Increment counter
	cmpq	%rsi, %rcx			# Compare counter with exponent
	jl	int_pow_loop			# If counter is lesser jumpt to start of the loop

int_pow_return:
	popq	%rdx				# Restore registers
	popq	%rcx
	ret

