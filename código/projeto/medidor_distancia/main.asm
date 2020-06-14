.device atmega328p

.org 0x0000
jmp start



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

;===================================================================================

DIV3216:
		.DEF res1 = R0				;resposta em 32bits
		.DEF res2 = R1				;byte 1 (*256)
		.DEF res3 = R2				;byte 2 (*256*256)
		.DEF res4 = R3				;byte 3 (*256*256*256)   

		.DEF REM1 = R4				;resto em 32bits
		.DEF REM2 = R5				
		.DEF REM3 = R6				
		.DEF REM4 = R7				

		.DEF dZERO = R8				;zero para operações de carry

		.DEF   A1 = R20				;dividendo em 32bits
		.DEF   A2 = R21				
		.DEF   A3 = R22				
		.DEF   A4 = R23				

		.DEF   dL = R16				;low byte do divisor
		.DEF   dH = R17				;high byte do divisor 

		.DEF    C = R22				;contador para o loop

        CLR dZERO
        MOVW res2:res1,A2:A1		
        MOVW res4:res3,A4:A3 
        LDI C,33					;carrega 33 no contador (1+ num de bits)
        CLR REM1					;zerando resto
        CLR REM2					
        CLR REM3					
        CLR REM4					
LOOP:   ROL res1					;passando a resposta uma casa para a esquerda
        ROL res2					
        ROL res3					
        ROL res4          
        DEC C						;decrementando contador
         BREQ DONE					;se o contador é 0, então todos os bits foram processados
        ROL REM1					
        ROL REM2          
        ROL REM3          
        ROL REM4          
        SUB REM1,dL					;subtraindo divisor do resto
        SBC REM2,dH       
        SBC REM3,dZERO     
        SBC REM4,dZERO     
         BRCC SKIP					;branch se o resultado for negativo
        ADD REM1,dL					;somando o divisor no resto
        ADC REM2,dH       
        ADC REM3,dZERO     
        ADC REM4,dZERO     
        CLC							
         RJMP LOOP					
SKIP:   SEC							
         RJMP LOOP
DONE:
		ret

;===================================================================================

delay10us:
	ldi r20, 53
	topa:
		dec r20
		brne topa
		ret

;===================================================================================

start:
	ldi r16, 0xff			;setando portas
	out ddrd, r16			;portd como output
	
	ldi r16, 0x00		
	out ddrc, r16			;pinc como input

;===================================================================================

disparar:					;pulsando trigger do sensor (pulso de 10us de acordo com o datasheet)
	sbi portd, 0			;porta D0 ativada
	call delay10us
	cbi portd, 0			;D0 desativada

;===================================================================================

increg:
	inc r20
	breq disparar			;timeout
ler_sensor:					;aguardando pulso do pino echo
	in r16, pinc			;coloca os bits do PINC no r16
	cpi r16, 0b00100000		;se pinc5 for 1, pulso é detectado
	breq calcular_pulso
	inc r19
	breq increg
	rjmp ler_sensor			;se o pulso não for detectado, a função se repete

;===================================================================================

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
	
;===================================================================================

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

;===================================================================================

calcular_tempo:				;ciclos / 1600 = tempo (centena de us)
	ldi r16, 0b01000000		;low de 1600
	ldi r17, 0b00000110		;high de 1600

	call div3216			;tempo (centenas de us)

;===================================================================================
	
calcular_distancia:			;distancia(cm) = (tempo(100us) * 34) / 20
	mov r16, r0				;byte 0 do tempo
	mov r17, r1				;byte 1 do tempo 
	ldi r18, 34
	ldi r19, 0
	call mul16x16
	ldi r16, 20
	ldi r17, 0
	call div3216
	mov r28, r0				;salvando resultado em cm (byte0 * 1)
	mov r29, r1				;(byte1 * 256)
	mov r30, r2				;(byte2 * 256 * 256)
	mov r31, r3				;(byte3 * 256 * 256 * 256)

	ldi  r18, 41			;delay de 500ms
    ldi  r19, 150
    ldi  r20, 128
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1

	rjmp disparar