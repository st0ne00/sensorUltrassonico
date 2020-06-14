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

	ldi  r18, 41				;delay de 500ms
    ldi  r19, 150
    ldi  r20, 128
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1

	rjmp disparar


increg:
    inc r20
    breq disparar            ;timeout
ler_sensor:                  ;aguardando pulso do pino echo
    in r16, pinc             ;coloca os bits do PINC no r16
    cpi r16, 0b00100000      ;se pinc5 for 1, pulso é detectado
    breq calcular_pulso
    inc r19
    breq increg
    rjmp ler_sensor          ;se o pulso não for detectado, a função se repete