		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; implement your complete logic, including stack operations
		; R0 holds the address , R1 holds the size, R2 is holding the value 0
		STMDB SP!,{r0-r12}
		MOV R2,#0
_bzero_loop
		CMP R1,#0
		BEQ _bzero_done
		SUB R1,R1,#1
		STRB R2,[R0],#1
		B _bzero_loop
_bzero_done
		LDMIA SP!,{r0-r12}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; implement your complete logic, including stack operations
		;r0 holds the dest address, r1 holds the source address, r2 holds the size
		STMDB SP!,{r0-r12}
_strncpy_loop
		CMP R2,#0
		BEQ _strncpy_done
		SUB R2,R2,#4
		LDR R3,[R1],#4
		STR R3,[R0],#4
		B _strncpy_loop
		
_strncpy_done
		LDMIA SP!,{r0-r12}
		MOV		pc, lr	
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		STMDB SP!,{r1-r12}
		PUSH {LR}
		; set the system call # to R7
		MOV R7,#3
		;MOV LR,PC
		;ADD LR,LR,#8
		;PUSH {LR} ;TRIALS OF MANUALLY SAVING THE LR//IT FAILS
	        SVC     #0x0
		; resume registers
		MRS r1,PSP
		LDR r0,[r1]
		POP {LR}
		LDMIA SP!,{r1-r12}
		;		IMPORT _R0_storage_space
		;LDR R1,=_R0_storage_space
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		; set the system call # to R7
		STMDB SP!,{r0-r12}
		PUSH {LR}
		MOV R7,#4
        	SVC     #0x0
		; resume registers
		POP {LR}
		LDMIA SP!,{r0-r12}
		LDR R0,[R1]
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		; set the system call # to R7
		STMDB SP!,{r0-r12}
		PUSH {LR}
		MOV R7,#1
        	SVC     #0x0
		; resume registers	
		POP {LR}
		LDMIA SP!,{r0-r12}
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		; set the system call # to R7
		STMDB SP!,{r0-r12}
		PUSH {LR}
		MOV R7,#2
        	SVC     #0x0
		; resume registers
		POP {LR}
		LDMIA SP!,{r1-r12}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
