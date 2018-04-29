#
# Mathematical functions
#

#
# Global functions declarations
#
.global int_pow
.global float_pow

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

#
# Raises given base to the given power, parameters are floats
#
# params:
#	st0 - base
#	st1 - exponent
# return:
#	st0 - result
#
float_pow:
	fyl2x					# st0 = st0 * log2(st1)
	fld1					# push 1
	fld	%st(1)				# push st1
	fprem					# st0 = st0 % st1
	f2xm1					# st0 = 2^st1 - 1
	faddp					# st0 = st0 + 1
	fscale					# st0 = st0 * 2^(floor(st1))
	fxch	%st(1)				# swap(st0, st1)
	fstp	%st				# pop st0
	ret

