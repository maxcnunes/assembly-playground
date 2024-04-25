.text
.align 4
.global _start

_start:
	bl _print_prompt
	bl _scan_input
	b _convert_temperature

_print_prompt:
	stp x29, x30, [sp, #-16]!			// store fp and sp on the stack

	adrp x1, output_prompt@PAGE			// pointer to the prompt string
	add x1, x1, output_prompt@PAGEOFF
	ldr x2, =output_prompt_len			// length of the string
	bl print

	ldp x29, x30, [sp], #16				// pop fp and sp from stack

	ret

_scan_input:
	stp x29, x30, [sp, #-16]!			// store fp and sp on the stack

	adrp x1, input@PAGE
	add x1, x1, input@PAGEOFF
	ldr x2, =input_len
	bl input_stdin

	mov x2, x0							// updates x2 (input length) with x0 (number of bytes read)

	ldp x29, x30, [sp], #16				// pop fp and sp from stack

	ret

_convert_temperature:
	stp x29, x30, [sp, #-16]!			// store fp and sp on the stack

	// extract income type
	subs x2, x2, #1
	ldrb w6, [x1, x2]

	cmp w6, #'C'
	beq _convert_temperature_c_to_f

	cmp w6, #'F'
	beq _convert_temperature_f_to_c

	b _convert_temperature_failure

_convert_temperature_success:
	bl print_int

	// Load w7 to stack because we cannot pass the data itself
	// directly to write syscall, it must receive the pointer to that
	// data instead. Therefore, we load it to stack, the we can pass the
	// stack pointer for that purpose.
	strb w7, [sp]

	mov w7, #'\n'
	strb w7, [sp, #1]	// store the digit on the stack as single byte

	mov  x1,  sp		// copy stack pointer to x1, which points the string to be printed

	mov x2, #2			// F\n or C\n length
	bl print

	mov x0, #0  // exit status code
	bl exit

_convert_temperature_failure:
	adrp x1, output_invalid_type@PAGE			// pointer to the prompt string
	add x1, x1, output_invalid_type@PAGEOFF
	ldr x2, =output_invalid_type_len			// length of the string
	bl print

	mov x0, #1  // exit status code
	bl exit

_convert_temperature_c_to_f:
	mov w7, #'F'
	bl atoi								// parse the rest of the argument to a number
	bl c_to_f
	b _convert_temperature_success

_convert_temperature_f_to_c:
	mov w7, #'C'
	bl atoi								// parse the rest of the argument to a number
	bl f_to_c
	b _convert_temperature_success

.data
input:	.fill 20,1,0
input_len = . - input

output_prompt: .ascii "Type in temperature to be converted between Fahrenheit and Celsius including
F or C at the end (68F to convert it to 20C): \n"
output_prompt_len = . - output_prompt

output_invalid_type: .ascii "Invalid temperature type. It must end either with F or C."
output_invalid_type_len = . - output_invalid_type
