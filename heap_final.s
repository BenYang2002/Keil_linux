		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
		STMDB SP!,{r1-r11}
		MOV R0,#0X4000
		MOV R1,#0x2000
		MOV R2,#0X6800
		ADD R1,R2,R1,LSL #16
		STRH R0,[R1]
		LDMIA SP!,{r1-r11}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )

		EXPORT	_kalloc
_kalloc
  ;size = ( size < 32 ) ? 32 : size; // minimum 32 bytes
  ;return _ralloc( size, mcb_top, mcb_bot );
		;EXPORT _R0_storage_space
;_R0_storage_space DCD 0
    CMP R0,#32
    BGT _if_larger
    MOV R0,#32
_if_larger
    MOV R1,#0x2000
	MOV R2,#0X6800
	ADD R1,R2,R1,LSL #16 ; R1 holds the MCB base
	MOV R2,#0
	MOV R3,#511
	MOV R12,#0 ; R12 IS THE SUCCESS BIT
    B _ralloc

_ralloc
	PUSH {LR}
	CMP R12,#1
	BEQ _kalloc_already_allocated ; THIS MEANS IN OTHER ITERATIONS THIS HAS ALREADY BEEN ALLOCATED
	SUB R4,R3,R2
	ADD R4,R4,#1
	LSL R4,R4,#5;entire = 32* (right - left+1)
    ASR R5,R4,#1;half = entire/2
    ADD R6,R2,R3
	ASR R6,R6,#1;mid = (right+left)/2
	CMP R0,R4;if(size > entire){
    BGT  _kalloc_not_enough_space  ;return false}
	
	CMP R0,R5	;else if(half<size<=entire){
    BGT _allocate_entire_chunk  
	; if programs proceed the following code that means we are doing the recursion
	ADD R6,R6,#1
	ADD R8,R1,R6,LSL #1;R8 holds the address for the RIGHT PART mcb
	SUB R6,R6,#1
	LDRH R7,[R8]
	MOV R10,R8
	STMDB SP!,{r1-r11}
	MOV R3,R6 ; mid becomes the right for ralloc_left
	
	ADD R8,R1,R2,LSL #1;R8 holds the address for the left mcb
	LDRH R8,[R8] ; R8 now has the available size
	MOV R9,#0X0
	UBFX R9,R8,#0,#1 ;R9 now holds the valid bit
	CMP R9,#0
	BEQ _kalloc_begin_split
	SUB R8,R8,#1
	CMP R8,R4
	BGE _kalloc_not_enough_space_case2
_kalloc_begin_split
	CMP R7,#0
	BNE _jump_update
	STRH R5,[R10] ;update the number on the RIGHT part
_jump_update
	BL _ralloc ; left
	LDMIA SP!,{r1-r11}
	
	CMP R12,#1
	BEQ _kalloc_already_allocated ; THIS MEANS IN OTHER ITERATIONS THIS HAS ALREADY BEEN ALLOCATED
	ADD R6,R6,#1
	MOV R2,R6 ; mid +1 becomes the left fo ralloc_right
	BL _ralloc ; right
	POP{LR}
	MOV PC,LR 
	
_kalloc_not_enough_space_case2
	LDMIA SP!,{r1-r11}
	POP{LR}
	MOV PC,LR ; 
_kalloc_not_enough_space
	POP{LR}
	MOV PC,LR ; 
_kalloc_not_available
	POP{LR}
	MOV PC,LR ; 
_kalloc_already_allocated
	POP{LR}
	MOV PC,LR ; 
_allocate_entire_chunk 
	CMP R12,#1
	BEQ _kalloc_already_allocated ; THIS MEANS IN OTHER ITERATIONS THIS HAS ALREADY BEEN ALLOCATED
	ADD R8,R1,R2,LSL #1;R8 holds the address for the left mcb
	LDRH R8,[R8] ; R8 now has the available size
	CMP R8,R0
	BLT _kalloc_not_enough_space ; not enough space ; Line 94 - 97 looks redundant since in the previous chunk 
													;we already have else if(half<=size<=entire){, delete?
	MOV R9,#0X0
	UBFX R9,R8,#0,#1 ;R9 now holds the valid bit
	CMP R9,#1
	BEQ _kalloc_not_available
	MOV R9,#1
	ADD R10,R1,R2,LSL #1;R10 holds the address for the left mcb
	MOV R8,R4 ; UPDATE SIZE
	BFI R8,R9,#0,#1; R8 now indicates that this address is occupied
	STRH R8,[R10]
	;; now translating mcb address to heap address
	STMDB SP!,{r1-r11} ; CUZ I DON'T WANT TO ACCIDENTALLY CHANGE CONTENTS OF OTHER REGISTER WHICH MAY BE USEFUL
	MOV R1,#0x2000
	MOV R3,#0X1000
	ADD R1,R3,R1,LSL #16 ; R1 holds the heap base
	ADD R1,R1,R2,LSL #5 ; R1 now has the heap value
	MOV R0,R1
	LDMIA SP!,{r1-r11}
	MOV R12,#1 ; THE MALLOC SUCCEEDED

	POP{LR}
	MOV PC,LR ; 

		EXPORT	_kfree
_kfree
	;; Implement by yourself
	;R0 has the address of the address to be freed
	CMP R0,#0
	BEQ _kfree_NOT_VALID_ADDRESS
	;;TRANSLATE R0/HEAP ADDRESS TO MCB ADDRESS
	MOV R1,#0x2000
	MOV R3,#0X1000
	ADD R1,R3,R1,LSL #16 ; R1 holds the heap base
	SUB R1,R0,R1 ; 
	ASR R1,R1,#5; R1 HOLDS THE MCB NUMBER
	
	MOV R2,#0x2000
	MOV R3,#0X6800
	ADD R2,R3,R2,LSL #16 ; R2 holds the MCB base
	
	ADD R2,R2,R1,LSL #1; R2 HOLDS THE MCB ADDRESS
	
	LDRH R3,[R2] ; R3 HOLDS THE SIZE AND THE VALID BIT
	BFI R4,R3,#0,#1 ;R4 HOLDS THE VALID BIT
	CMP R4,#0
	BEQ _kfree_nothing_to_free
	
	BFC R3,#0,#1 ; free the address by changing the valid bit and R4 holds the size
	STRH R3,[R2] ; freeing this block
	B _kfree_left_or_right

_kfree_left_or_right
	;R3 IS THE SIZE
	ASR R3,R3,#5 ; SIZE IN TERMS OF mcb BLOCKS
	MOV R5,R3 ; store SIZE IN TERMS OF MCB BLOCKS
	LSL R3,R3,#1 ; double it
	
	;;PERFORM A MODULO
	SDIV R6,R1,R3 ; MCB_NUMBER / DOUBLE_BLOCK_SIZE ROUND DOWN
	MUL R7,R3,R6 
	SUB R3,R1,R7 ; we now have the remainder of mcb_number / double_block_size
	;AND R6,R6,#1
	CMP R3,#0
	BEQ _kfree_left
	B _kfree_right

_kfree_left
	ADD R4,R5,R1 ; MCB NUMBER
	;NOTICE R2 HAS THE CURRENT MCB ADDRESS NOT THE BASE
	ADD R4,R2,R5, LSL #1 ;R4 holds MCB ADDRESS
	LDRH R7,[R4] ; R7 has the size for right buddy
	MOV R6,#0
	BFI R6,R7,#0,#1 ; extract the valid bit on the right buddy
	ASR R7,R7,#5 ; we don't need to continue if the available space doesn't match
	CMP R7,R5
	BNE _kfree_done
	CMP R6,#0
	BEQ _kfree_free_left
	B _kfree_done
	
_kfree_free_left
	MOV R6,#0
	STRH R6,[R4] ; update the right buddy 
	LSL R5,R5,#1; double the size for left buddy
	PUSH{R5}
	LSL R5,R5,#5 ; translate mcb size into btye size
	STRH R5,[R2] ; update the size for left buddy
	POP{R5}
	LSL R5,R5,#5 ; shift left to reflect the size in btyes
	MOV R3,R5 ; we have to update R1 and R3
	;DO NOTHING FOR R1 IN THIS CASE
	B _kfree_left_or_right
	
_kfree_right ;R5 SIZE IN TERMS OF MCB BLOCKS, R5 NUMBER
			 ;R1 IS THE MCB NUMBER, R2 holds the MCB base
	SUB R4,R1,R5 ; MCB NUMBER
	SUB R4,R2,R5, LSL #1 ;R4 holds MCB ADDRESS for left buddy
	;NOTICE R2 HAS THE CURRENT MCB ADDRESS NOT THE BASE
	LDRH R7,[R4] ; R7 has the size for left buddy
	MOV R6,#0
	BFI R6,R7,#0,#1 ; extract the valid bit on the left buddy
	; IF THE AVAILABLE SIZE DOESN'T MATCH WE ALSO DON'T WANNA MERGE
	ASR R7,R7,#5
	CMP R7,R5
	BNE _kfree_done
	CMP R6,#0
	BEQ _kfree_free_right
	B _kfree_done

_kfree_free_right
	MOV R6,#0
	STRH R6,[R2] ;update current buddy's memory
	SUB R1,R1,R5 ; update the the starting MCB TO THE LEFT BUDDY
	SUB R2,R2,R5, LSL #1 ; UPDATE THE STARTING MCB ADDRESS
	LSL R5,R5,#1; double the size for left buddy
	PUSH{R5}
	LSL R5,R5,#5 ; translate mcb size into btye size
	STRH R5,[R4] ; update the size for left buddy
	POP{R5}
	LSL R5,R5,#5 ; shift left to reflect the size in btyes
	; ALSO NEED TO UPDATE R2 DUE TO POOR DESIGN
	MOV R3,R5
	B _kfree_left_or_right

_kfree_NOT_VALID_ADDRESS
	MOV		pc, lr
_kfree_nothing_to_free
	MOV		pc, lr
_kfree_done
	MOV		pc, lr

		END