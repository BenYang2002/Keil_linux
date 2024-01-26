		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x3		; address 20007B10
SYS_FREE		EQU		0x4		; address 20007B14
		IMPORT	_kfree
		IMPORT	_kalloc
		IMPORT	_signal_handler
		IMPORT	_timer_start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
		
_syscall_table_init
	;; Implement by yourself
			
		STMDB SP!,{r0-r12}
		LDR R0,=SYSTEMCALLTBL
		ADD R0,R0,#4
		
		LDR R1,=_timer_start
		STR R1,[R0],#4
		
		LDR R1,=_signal_handler
		STR R1,[R0],#4
		
		LDR R1,=_kalloc
		STR R1,[R0],#4
		
		LDR R1,=_kfree
		STR R1,[R0],#4
		
		LDMIA SP!,{r0-r12}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;; Implement by yourself
		STMDB SP!,{r1-r2,r4-r12}
		LDR R2,=SYSTEMCALLTBL
		MOV R4,#4 
		MUL R3,R7,R4
		ADD R3,R2,R3 ;R3 has the address for the TABLE that stores the actual implementation address
		LDR R3,[R3]
		LDMIA SP!,{r1-r2,r4-r12} ; we want to use the original parameter
		STMDB SP!,{r1-r11}
		PUSH {LR}
		BLX R3
		POP {LR}
		LDMIA SP!,{r1-r11}
		STMDB SP!,{r1-r11}
		CMP R7,#3
		BEQ _malloc_sub_routine
		LDMIA SP!,{r1-r11}
		MOV		pc, lr
		
_malloc_sub_routine		
		CMP R12,#0
		BEQ __malloc_sub_routine_IF
		LDMIA SP!,{r1-r11}
		MOV		pc, lr
__malloc_sub_routine_IF
		MOV R0,#0 ; if not success we set R0 to 0 indicating null pointer
		LDMIA SP!,{r1-r11}
		MOV		pc, lr
		END


		
