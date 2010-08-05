#include <stdint.h>
#include <string.h>

#include "cmsis.h"
#include "os_init.h"

extern void Reset_Handler();
extern void NMI_Handler();
extern void HardFault_Handler();
extern void MemManage_Handler();
extern void BusFault_Handler();
extern void UsageFault_Handler();
extern void SVC_Handler();
extern void DebugMon_Handler();
extern void PendSV_Handler();
extern void SysTick_Handler();
extern void UnhandledIRQ_Handler();

// Symbols defined by the linker:
extern unsigned int __text_end__, __stacks_top__,
					__data_start__, __data_end__,
					__bss_start__,  __bss_end__;


/*****************************************************************************/

// Vector table:
void (* const vectors[])(void)
		__attribute__ ((section(".vectors"))) =
{
	(void (*)())&__stacks_top__,	// Initial stack pointer
	Reset_Handler,
	NMI_Handler,
	HardFault_Handler,
	MemManage_Handler,				// MPU faults handler
	BusFault_Handler,
	UsageFault_Handler,
	0, 0, 0, 0, 					// (reserved)
	SVC_Handler,
	DebugMon_Handler,
	0,								// (reserved)
	PendSV_Handler,
	SysTick_Handler,
};


#define VECTORS_LEN_CORE	(sizeof(vectors) / sizeof(void(*)(void)))
#define VECTORS_LEN_LPC17XX	(35)
#define VECTORS_LEN			(VECTORS_LEN_CORE + VECTORS_LEN_LPC17XX)

// Vector table in RAM (after relocation):
void (* __ram_vectors[VECTORS_LEN])(void)
		__attribute__ ((aligned(0x100), section(".privileged_bss")));

__attribute__ ((noreturn)) void Reset_Handler(void)
{
	// Copy the data segment initializers from flash to RAM
	unsigned int *src  = &__text_end__;
	unsigned int *dest = &__data_start__;
	while (dest < &__data_end__)
		*(dest++) = *(src++);

	// Zero fill the bss segment
	dest = &__bss_start__;
	while (dest < &__bss_end__)
		*(dest++) = 0;

	// Copy the initial vector table from flash to RAM and then fill the
	// remaining vectors with calls to UnhandledIRQ_Handler.
	for (int i = 0; i < VECTORS_LEN_CORE; i++)
		__ram_vectors[i] = vectors[i];
	for (int i = VECTORS_LEN_CORE; i < VECTORS_LEN; i++)
		__ram_vectors[i] = UnhandledIRQ_Handler;

	// Perform the relocation
	SCB->VTOR = (unsigned int)__ram_vectors;

	// Boot the system: hardware initialisation etc., eventually calls main()
	Boot_Init();
}

