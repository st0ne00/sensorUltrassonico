.device atmega328p

.org 0x0000
jmp start

delay10us:
	ldi r20, 53
	topa:
		dec r20
		brne topa
		ret

start:
	ldi r16, 0xff			;setando portas
	out ddrd, r16			;portd como output
	
	ldi r16, 0x00		
	out ddrc, r16			;pinc como input

disparar:					;pulsando trigger do sensor (pulso de 10us de acordo com o datasheet)
	sbi portd, 0			;porta D0 ativada
	call delay10us
	cbi portd, 0			;D0 desativada

calcular_ciclos:			;ciclos = (r18 * 1788) + (r17 * 7)
	ldi r19, 7
	mul r17, r19			;r17 * 7
	mov r24, r0				;resultado low
	mov r25, r1				;resultado high

	mov r16, r18
	ldi r17, 0
	ldi r18, 0b11111100		;low de 1788
	ldi r19, 0b00000110		;high de 1788
	call mul16x16

	ldi r26, 0
	ldi r27, 0
							;quantidade de ciclos:
	add r20, r24			;byte 0
	adc r21, r25			;byte 1
	adc r22, r26			;byte 2
	adc r23, r27			;byte 3

