
;	Title:		Initialize I/O Ports
;	Name:		IPORTS
;
;	Purpose:	Initialize I/O ports from an array of port addresses and values. 
;
;	Entry:		Register X = Base address of array 
;
;			The array consists of 3 byte elements 
;			array+0 = High byte of port 1 address 
;			array+1 = Low  byte of port 1 address 
;			array+2 = Value to store in port 1 address 
;			array+3 = High byte of port 2 address 
;			array+4 = Low  byte of port 2 address 
;			array+5 = Value to store in port 2 address 
;				.
;				.
;				.
;
;	Exit:	None Registers Used: A,B,CC,U,X
;
;	Time:	10 cycles overhead plus 23 * N cycles for each port,
;		where N is the number of bytes. 
;
;	Size:	Program 13 bytes
;
IPORTS:
	;
	; EXIT IMMEDIATELY IF NUMBER OF PORTS IS ZERO
	; 
	TSTA			; TEST NUMBER OF PORTS
	BEQ	EXITIP		; BRANCH IF NO PORTS TO INITIALIZE
; 
; LOOP INITIALIZING PORTS
;
INITPT:
	LDU	,X++		; GET NEXT PORT ADDRESS
	LDB	,X+		; GET VALUE TO SEND THERE 
	STB	,U		; SEND VALUE TO PORT ADDRESS 
	DECA			; COUNT PORTS 
	BNE	INITPT		; CONTINUE UNTIL ALL PORTS INITIALIZED
; 
; EXIT
; 
EXITIP:
	RTS
;
; SAMPLE EXECUTION:
; 
; INITIALIZE
; 6820/6821 PIA (PERIPHERAL INTERFACE ADAPTER)
; 6850 ACIA (ASYNCHRONOUS COMMUNICATIONS INTERFACE ADAPTER)
; 6840 PTM (PROGRAMMABLE TIMER MODULE)
; 
; ARBITRARY DEVICE MEMORY ADDRESSES
; 
; 6820/6821 PIA ADDRESSES
;
PIADRA	EQU	$A400		; 6821 PIA DATA REGISTER A 
PIACRA	EQU	$A401		; 6821 PIA CONTROL REGISTER A 
PIADRB	EQU	$A402		; 6821 PIA DATA REGISTER B 
PIACRB	EQU	$A403		; 6821 PIA CONTROL REGISTER B
;
; 6840 PTM ADDRESSES
;
PTMC13	EQU	$A100		; 6840 PTM CONTROL REGISTERS 1,3 
PTMCR2	EQU	$A101		; 6840 PTM CONTROL REGISTER 2 
PTM1MS	EQU	$A102		; 6840 PTM TIMER 1 MSB
PTM1LS	EQU	$A103		; 6840 PTM TIMER 1 LSB
PTM2MS	EQU	$A104		; 6840 PTM TIMER 2 MSB
PTM2LS	EQU	$A105		; 6840 PTM TIMER 2 LSBA
PTM3MS	EQU	$A106		; 6840 PTM TIMER 3 MSB
PTM3LS	EQU	$A107		; 6840 PTM TIMER 3 LSB
;
; 6850 ACIA ADDRESSES
;
ACIADR	EQU	$A200		; 6850 ACIA DATA REGISTER
ACIACR	EQU	$A201		; 6850 ACIA CONTROL REGISTER 
ACIASR	EQU	$A201		; 6850 ACIA STATUS REGISTER 

SC8F:
	LDX	BEGPIN		; GET BASE ADDRESS OF INITIALIZATION
; ARRAY 
	LDA	SZINIT		; GET SIZE 0F ARRAY IN BYTES 
	JSR	IPORTS		; INITIALIZE PORTS 
	BRA	SC8F		; REPEAT TEST 
PINIT:
; 
; INITIALIZE 6820 OR 6821 PERIPHERAL INTERFACE ADAPTER (PIA)
;
	;	PORT A = INPUT
	;	CA1 =	DATA AVAILABLE, SET ON LOW TO HIGH TRANSITION,
	;		NO INTERRUPTS
	;	CA2 =	DATA ACKNOWLEDGE HANDSHAKE
	;
	FDB	PIACRA		; PIA CONTROL REGISTER A ADDRESS
	FDB	00000000B	; INDICATE NEXT ACCESS TO DATA
				; DIRECTION REGISTER (SAME ADDRESS
				; AS DATA REGISTER) 

	FDB	PIADRA		; PIA DATADIRECTION REGISTER A ADDRESS
	FDB	00000000B	; ALL BITS INPUT

	FDB	PIACRA		; PIA CONTROL REGISTER A ADDRESS
	FDB	00100110B	; BITS 7,6 NOT USED
				; BIT 5 = 1 TO MAKE CA2 OUTPUT
				; BIT 4 = 0 TO MAKE CA2 A PULSE
				; BIT 3 = 0 TO MAKE CA2 INDICATE
				; 			DATA REGISTER FULL 
				; BIT 2 = 1 TO ADDRESS DATA REGISTER
				; BIT 1 = 1 TO MAKE CA1 ACTIVE
				; 			LOW TO HIGH
				; BIT 0 = 0 TO DISABLE CA1 INTERRUPTS 
	;
	;	PORT B = OUTPUT
	;	CB1 =	DATA ACKNOWLEDGE, SET ON HIGH TO LOW TRANSITION,
	;		NO INTERRUPTS
	;	CB2 =	DATA AVAILABLE, CLEARED BY WRITING TO DATA
	;		REGISTER B, SET TO 1 BY HIGH TO LOW TRANSITION ON CB1
	;
	FDB	PIACRB		; PIA CONTROL REGISTER B ADDRESS 
	FDB	00000000B	; INDICATE NEXT ACCESS TO DATA
				; DIRECTION REGISTER (SAME ADDRESS
				; AS DATA REGISTER 
	FDB	PIADRB		; PIA DATA DIRECTION REGISTER B
	FDB	11111111B	; ADDRESS ALL BITS OUTPUT
	FDB	PIACRB		; PIA CONTROL REGISTER B ADDRESS
	FDB	00100100B	; BITS 7,6 NOT USED
				; BIT 5 = 1 TO MAKE CB2 OUTPUT
				; BIT 4 = 0 TO MAKE CB2 A PULSE
				; BIT 3 = 0 TO MAKE CB2 INDICATE DATA REGISTER FULL 
				; BIT 2 = 1 TO ADDRESS DATA REGISTER
				; BIT 1 = 0 TO MAKE CB2 ACTIVE
				; BIT 0 = 0 TO DISABLE CB1 INTERRUPTS
;
; INITIALIZE 6850 ASYNCHRONOUS COMMUNICATIONS INTERFACE ADAPTER
; (ACIA OR UART)
;
	; 8 BIT DATA, NO PARITY
	; 1 STOP BIT
	; DIVIDE MASTER CLOCK BY 16
	; NO INTERRUPTS
	;
	FDB 	ACIACR		; ACIA CONTROL REGISTER ADDRESS 
	FCB 	00000011B	; PERFORM MASTER RESET
				; 6850 HAS NO RESET INPUT 
	FDB	ACIACR		; ACIA CONTROL REGISTER ADDRESS 
	FCB	00010101B	; BIT 7 = 0 TO DISABLE RECEIVE INTERRUPTS 
				; BIT 6 = 0 TO MAKE RTS LOW 
				; BIT 5 = 0 TO DISABLE TRANSMIT INTERRUPTS
				; BIT 4 = 1 TO SELECT DATA
				; BIT 3 = 0 FOR NO PARITY
				; BIT 2 = 1 FOR 1 STOP BIT
				; BIT 1 = 0, BIT 0 = 1 TO DIVIDE MASTER CLOCK BY 16
;
; INITIALIZE 6840 PROGRAMMABLE TIMER MODULE (PTM)
; 
; CLEAR ALL TIMER COUNTERS
; RESET TIMERS
; OPERATE TIMER 2 IN CONTINUOUS MODE,
; DECREMENTING COUNTER AFTER EACH CLOCK CYCLE
; SET TIME CONSTANT TO 12 CLOCK CYCLES
; THIS GENERATES A SQUARE HAVE WITH PERIOD
; 2 * (12 + 1) = 26 CYCLES
;
; THIS INITIALIZATION PRODUCES A 2400 HZ CLOCK FOR USE
; IN DIVIDE BY 16 DATA TRANSMISSION
;
; IT ASSUMES A 1 MHZ SYSTEM CLOCK, SO A PERIOD OF
; (1,000,000)/(16*2400) = 26 CYCLES WILL GENERATE
; A 38,400 (16*2400) HZ SQUARE WAVE
; 
	FDB	PTM1MS		; PTM   TIMER 1 MS BYTE 
	FCB	0		; CLEAR TIMER 1 MS BYTE
	FDB	PTM1LS		; PTM   TIMER 1 LS BYTE 
	FCB	0		; CLEAR TIMER 1 LS BYTE 
	FDB	PTM2MS		; PTM   TIMER 2 MS BYTE 
	FCB	0		; CLEAR TIMER 2 MS BYTE 
	FDB	PTM2LS		; PTM   TIMER 2 LS BYTE 
	FCB	0		; CLEAR TIMER 2 LS BYTE 
	FDB	PTM3MS		; PTM   TIMER 3 MS BYTE 
	FCB	0		; CLEAR TIMER 3 MS BYTE 
	FDB	PTM3LS		; PTM   TIMER 3 LS BYTE
	FCB	0		; CLEAR TIMER 3 LS BYTE
	FDB	PTMCR2		; PTM TIMER 2 CONTROL REGISTER
	FCB	00000001B	; ADDRESS TIMER 1 CONTROL REGISTER 
	FDB	PTMC13		; PTM TIMER 1,3 CONTROL REGISTER 
	FCB	00000001B	; RESET TIMERS
	FDB	PTMC13		; PTM TIMER 1,3 CONTROL REGISTER 
	FCB	0		; REMOVE RESET
	FDB	PTMCR2		; PTM TIMER 2 CONTROL REGISTER 
	FCB	10000010B	; BIT 7 = 1 TO PUT SQUARE WAVE OUTPUT ON O2
				; BIT 6 = 0 TO DISABLE INTERRUPT
				; BIT 5 = 0 FOR PULSE MODE
				; BIT 4 = 0 TO INITIALIZE COUNTER ON WRITE TO LATCHES
				; BIT 3 = 0 FOR CONTINUOUS OPERATION
				; BIT 2 = 0 FOR OPERATION
				; BIT 1 = 1 TO USE CPU CLOCK
				; BIT 0 = 0 TO ADDRESS CONTROL REGISTER 3
	FCB	PTM2MS		; PTM TIMER 2 MS BYTE
	FCB	0		; MS BYTE OF COUNT
	FCB	PTM2LS		; PTM TIMER 2 LS BYTE
	FCB	12		; LS BYTE OF COUNT
ENDPIN:				; END OF ARRAY

BEGPIN:	FCB	PINIT			; BASE ADDRESS OF ARRAY
SZINIT:	FCB	(ENDPIN-PINIT)/3	; NUMBER OF PORTS TO INITIALIZE
	END
