	INCLUDE				STM32F4xx.s
	AREA		SRAM1,		NOINIT,			READWRITE
	SPACE		0x400
Stack_Top
	
	AREA		RESET,		DATA,		READONLY
	DCD			Stack_Top			;[0x000-0x003]
	DCD			Start_Init			;[0x004-0x007]
	SPACE		0x50					;[0x08 - 0x57]
	DCD			EXTI0_IRQHandler		;[0x58 - 0x5B]
	SPACE		0x5B					;[0x5C - 0xB7]
	DCD			TIM4_IRQHandler			;[0xB8 - 0xBB]
	SPACE		0x4B					;[0xBC - 0x107]
	DCD			TIM5_IRQHandler			;[0x108 - 0x10B]
	SPACE		0x0C					;[0x10C - 0x117]
	DCD			TIM6_DAC_IRQHandler		;[0x118-0x11B]
	
	AREA		PROGRAM,	CODE,		READONLY
	ENTRY

Start_Init
;-------------------------- Config TX ---------------------------|
	LDR			R0,			=RCC_BASE
;Clocking TIM6, TIM7, GPIOB/D - Enable
	LDR			R1,			[R0,		#RCC_APB1ENR]
	ORR			R1,			R1,		#(RCC_APB1ENR_TIM6EN + RCC_APB1ENR_TIM4EN) 
	STR			R1,			[R0,		#RCC_APB1ENR]
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,		#RCC_AHB1ENR_GPIOBEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,		#RCC_AHB1ENR_GPIODEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
	LDR			R1,			[R0,		#RCC_AHB1ENR]
	ORR			R1,			R1,		#RCC_AHB1ENR_GPIOEEN
	STR			R1,			[R0,		#RCC_AHB1ENR]
;Create transmit control line MODER13
	LDR			R0,			=GPIOD_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	AND			R1,			R1,		#~GPIO_MODER_MODER13
	ORR			R1,			R1,		#GPIO_MODER_MODER13_0
	STR			R1,			[R0,		#GPIO_MODER]
;PB7 Output
	LDR			R0,			=GPIOB_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	AND			R1,			R1,		#~GPIO_MODER_MODER7
	ORR			R1,			R1,		#GPIO_MODER_MODER7_0
	STR			R1,			[R0,		#GPIO_MODER]
	
	LDR			R1,			[R0,		#GPIO_ODR]
	ORR			R1,			R1,		#GPIO_ODR_OD7
	STR			R1,			[R0,		#GPIO_ODR]	
;-------------------------- Config RX ---------------------------|
	LDR			R0,			=RCC_BASE
;Clocking TIM5
	LDR			R1,			[R0,		#RCC_APB1ENR]
	ORR			R1,			R1,		#RCC_APB1ENR_TIM5EN
	STR			R1,			[R0,		#RCC_APB1ENR]
;Enable SYSCFG for EXTIx
	LDR			R1,			[R0,		#RCC_APB2ENR]
	ORR			R1,			R1,		#RCC_APB2ENR_SYSCFGEN
	STR			R1,			[R0,		#RCC_APB2ENR]
;PE0 Input
	LDR			R0,			=GPIOE_BASE
	LDR			R1,			[R0,		#GPIO_MODER]
	AND			R1,			R1,		#~GPIO_MODER_MODER0
	STR			R1,			[R0,		#GPIO_MODER]
;EXTI0 = GPIOE
	LDR 		R0,			=SYSCFG_BASE
	LDR			R1,			[R0,		#SYSCFG_EXTICR1]
	AND			R1,			R1,		#~SYSCFG_EXTICR1_EXTI0
	ORR			R1,			R1,		#(4 << SYSCFG_EXTICR1_EXTI0_Pos)
	STR			R1,			[R0,		#SYSCFG_EXTICR1]
;EXTI0 config Falling Edge on line 0
	LDR			R0,			=EXTI_BASE
	LDR			R1,			[R0,		#EXTI_FTSR]
	ORR			R1,			R1,		#EXTI_FTSR_TR0
	STR			R1,			[R0,		#EXTI_FTSR]
	LDR			R1,			[R0,		#EXTI_RTSR]
	AND			R1,			R1,		#~EXTI_RTSR_TR0
	STR			R1,			[R0,		#EXTI_RTSR]
;EXTI0 Enable
	LDR			R1,			[R0,		#EXTI_IMR]
	ORR			R1,			R1,		#EXTI_IMR_MR0
	STR			R1,			[R0, 		#EXTI_IMR]
;EXTI0 IRQ Enable
	LDR			R0,			=NVIC_BASE
	LDR			R1,			[R0,		#NVIC_ISER0]
	ORR			R1,			R1,		#(1 << EXTI0_IRQn)
	STR			R1,			[R0,		#NVIC_ISER0]
;Config TIM5
	LDR			R0,			=TIM5_BASE
;TIM5 PSC = 1 
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_PSC]
;TIM5 ARR = 833 (1/2 9600)
	MOV			R1,			#833
	STR			R1,			[R0,		#TIM_ARR]
;TIM5 CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]	
;TIM5 Update Interrupt Enable
	LDR			R1,			[R0,		#TIM_DIER]
	ORR			R1,			R1,		#TIM_DIER_UIE
	STR			R1,			[R0,		#TIM_DIER]
;TIM5 IRQ Enable
	LDR			R0,			=NVIC_BASE
	LDR			R1,			[R0,		#NVIC_ISER1]
	ORR			R1,			R1,		#(1 << (TIM5_IRQn - 32))
	STR			R1,			[R0,		#NVIC_ISER1]
;Config TIM4 	
	LDR			R0,			=TIM4_BASE
;TIM4 PSC = 1 
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_PSC]
;TIM4 ARR = 1667
	MOV			R1,			#1667
	STR			R1,			[R0,		#TIM_ARR]
;TIM4 CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]	
;TIM4 Update Interrupt Enable
	LDR			R1,			[R0,		#TIM_DIER]
	ORR			R1,			R1,		#TIM_DIER_UIE
	STR			R1,			[R0,		#TIM_DIER]
;TIM4 IRQ Enable
	LDR			R0,			=NVIC_BASE
	LDR			R1,			[R0,		#NVIC_ISER0]
	ORR			R1,			R1,		#(1 << TIM4_IRQn)
	STR			R1,			[R0,		#NVIC_ISER0]
;	\|/
Main_Loop
	
	B			Main_Loop
;-------------------------- Interrupts for transmit ---------------------------|
TIM6_DAC_IRQHandler
	LDR			R0,			=TIM6_BASE
	LDR			R1,			[R0,		#TIM_SR]
	AND			R1,			R1,		#~TIM_SR_UIF   
	STR			R1,			[R0,		#TIM_SR]
;Read zero bit in register
	AND			R6,			R4,		#0x01			
;Shift register in left on 1 bit	
	LSR			R4,			R4,		#1	
;	\|/
;Set 0 or 1 in line
	LDR			R2,			=GPIOB_BASE
	LDR			R1,			[R2,		#GPIO_ODR]
;Compare with 0
	CMP			R6,			#0
;If equally	- set on line 0
	ANDEQ			R1,			R1,		#~GPIO_ODR_OD7
;If not equally - set on line 1 
	ORRNE			R1,			R1,		#GPIO_ODR_OD7 
;Load back to register	
	STR			R1,			[R2 ,		#GPIO_ODR]
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]
;Increment counter and check (if counter == 10 off timer)
	ADD			R7,			#1
	CMP			R7,			#11
	BXNE			LR
	
	LDR			R0,			=TIM6_BASE
	LDR			R1,			[R0,		#TIM_CR1]
	ANDEQ			R1,			R1,		#~TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
;After transmit ON PD13	
	LDR			R0,			=GPIOD_BASE
	LDR			R1,			[R0,		#GPIO_ODR]
	ORR			R1,			R1,		#GPIO_ODR_OD13
	STR			R1,			[R0,		#GPIO_ODR]
	LDR			R0,			=EXTI_BASE
;ON EXTI0
	LDR			R1,			[R0,		#EXTI_IMR]
	ORR			R1,			R1,		#EXTI_IMR_MR0
	STR			R1,			[R0,		#EXTI_IMR]
	MOV 		R7,			#0
	BX 			LR
;-------------------------- Interrupts for receiving ---------------------------|
EXTI0_IRQHandler
;Reset flag
	LDR			R0,			=EXTI_BASE
	LDR			R1,			[R0,		#EXTI_PR]
	ORR			R1,			R1,		#EXTI_PR_PR0
	STR			R1,			[R0,		#EXTI_PR]
;OFF EXTI0
	LDR			R1,			[R0,		#EXTI_IMR]
	AND			R1,			R1,		#~EXTI_IMR_MR0
	STR			R1,			[R0,		#EXTI_IMR]
	B			Enable_TIM4
	LDR			R0,			=TIM5_BASE
;TIM5_CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]
;TIM5 ON
	LDR			R1,			[R0,		#TIM_CR1]
	ORR			R1,			R1,		#TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
	BX			LR
TIM5_IRQHandler
	LDR			R0,			=TIM5_BASE
	LDR			R1,			[R0,		#TIM_SR]
	AND			R1,			R1,		#~TIM_SR_UIF   
	STR			R1,			[R0,		#TIM_SR]
	LDR			R0,			=GPIOE_BASE
	LDR			R1,			[R0,		#GPIO_IDR]
	AND			R1,			R1,		#GPIO_IDR_ID0
	CMP			R1,			#0
	BEQ			Enable_TIM4
	BX			LR
Enable_TIM4
	LDR			R0,			=TIM4_BASE
;TIM4_CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]
;TIM4 ON
	LDR			R1,			[R0,		#TIM_CR1]
	ORR			R1,			R1,		#TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
	LDR         		R0,         		=TIM5_BASE
	LDR         		R1,         		[R0,        	#TIM_CR1]
	AND			R1,         		R1,         	#~TIM_CR1_CEN
	STR        		R1,         		[R0,        	#TIM_CR1]
	MOV			R5,			#1
	MOV			R4,			#0
	MOV			R7,			#0
	BX			LR
TIM4_IRQHandler
	LDR         		R0,         		=TIM4_BASE
	LDR        		R1,         		[R0,     	#TIM_SR]
	AND         		R1,         		R1,      	#~TIM_SR_UIF
	STR        		R1,         		[R0,     	#TIM_SR]
;TIM4_CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]
	
	LDR			R2,			=GPIOE_BASE
	LDR        		R1,			[R2,    	#GPIO_IDR]
	AND         		R1,			R1,     	#GPIO_IDR_ID0
	CMP         		R1,         		#0
	ORRNE			R4,			R4,		R5
	LSL         		R5,			R5,     	#1
;Increment counter and check (if counter == 7 off timer)
	ADD         		R7,         		#1						
	CMP         		R7,         		#9						
	BXNE        		LR															
;Check stop bit
	LDR         		R1,			[R2,    	#GPIO_IDR]
	AND		        R1,			R1,     	#GPIO_IDR_ID0
	CMP         		R1,         		#1
;IF NE OFF TIM4 and ON EXTI0
	LDRNE			R1,			[R0,		#TIM_CR1]
	ANDNE			R1,         		R1,         	#~TIM_CR1_CEN
	STRNE       		R1,         		[R0,        	#TIM_CR1]
	LDRNE			R0,			=EXTI_BASE
	LDRNE			R1,			[R0,		#EXTI_IMR]
	ORRNE			R1,			R1,		#EXTI_IMR_MR0
	STRNE			R1,			[R0,		#EXTI_IMR]
	BXNE			LR
	LSL			R4,  			R4,  		#1				
	ORR			R4,  			R4,  		#0x600			
;OFF TIM4
	LDR         		R1,         		[R0,        	#TIM_CR1]
	AND		    	R1,         		R1,         	#~TIM_CR1_CEN
	STR         		R1,         		[R0,        	#TIM_CR1]	
;Setting the TIM6 to the frequency 9600
	LDR			R0,			=TIM6_BASE
;TIM6 PSC = 1 
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_PSC]
;TIM6 ARR = 1667
	MOV			R1,			#1667
	STR			R1,			[R0,		#TIM_ARR]
;TIM6 CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]	
;TIM6 Update Interrupt Enable
	LDR			R1,			[R0,		#TIM_DIER]
	ORR			R1,			R1,			#TIM_DIER_UIE
	STR			R1,			[R0,		#TIM_DIER]
;TIM6 IRQ Enable
	LDR			R0,			=NVIC_BASE
	LDR			R1,			[R0,		#NVIC_ISER1]
	ORR			R1,			R1,		#(1 << (TIM6_DAC_IRQn - 32))
	STR			R1,			[R0,		#NVIC_ISER1]
;TIM6 (Transmit) ON
	LDR			R0,			=TIM6_BASE
;TIM6_CNT = 0
	MOV			R1,			#0
	STR			R1,			[R0,		#TIM_CNT]
	LDR			R1,			[R0,		#TIM_CR1]
	ORR			R1,			R1,		#TIM_CR1_CEN
	STR			R1,			[R0,		#TIM_CR1]
	MOV			R7,			#0
	BX			LR
	END
