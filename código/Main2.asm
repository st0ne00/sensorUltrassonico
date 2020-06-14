MUL16x16:
		.DEF ZERO = R2              ;zero para operações com carry
		.DEF   AL = R16             ;multiplicado (low)
		.DEF   AH = R17				;multiplicado (high)

		.DEF   BL = R18             ;multiplicador (low)
		.DEF   BH = R19				;multiplicador (high)

		.DEF ANS1 = R20             ;resposta em 32bits
		.DEF ANS2 = R21				;byte 1 (*256)
		.DEF ANS3 = R22				;byte 2 (*256*256)	
		.DEF ANS4 = R23				;byte 3 (*256*256*256)

        CLR ZERO					;zerando
        MUL AH,BH					;multiplicando os bytes high
        MOVW ANS4:ANS3,R1:R0		;copiando os resultados (r0 -> ans3 e r1 -> ans4)
        MUL AL,BL					;multiplicando os bytes low
        MOVW ANS2:ANS1,R1:R0		;copiando os resultados (r0 -> ans1 e r1 -> ans2)
        MUL AH,BL					;multiplicando Ahigh com Blow
        ADD ANS2,R0					;somando resultado
        ADC ANS3,R1					
        ADC ANS4,ZERO				;adicionando bit de carry (caso a soma anterior tenha passado de 255)
        MUL BH,AL					;multiplicando Bhigh com Alow
        ADD ANS2,R0					;somando resultado
        ADC ANS3,R1					
        ADC ANS4,ZERO				;adicionando bit de carry (caso a soma anterior tenha passado de 255)
		ret

addr18:
	inc r18
	breq disparar			;timeout
calcular_pulso:				;calculando comprimento de onda do pulso
	inc r17
	breq addr18
	in r16, pinc			
	cpi r16, 0b00000000		;verificando se o pulso chegou ao final
	breq calcular_ciclos
	rjmp calcular_pulso		;enquanto o pulso não terminar, a função se repete


calcular_tempo:				;ciclos / 1600 = tempo (centena de us)
	ldi r16, 0b01000000		;low de 1600
	ldi r17, 0b00000110		;high de 1600

	call div3216			;tempo (centenas de us)



