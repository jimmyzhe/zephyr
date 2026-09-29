/*
 * Copyright (c) 2026 Andes Technology Corporation
 * Copyright (c) 2026 Analog Devices, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/arch/riscv/irq.h>
#include <offsets_short.h>
#include <zephyr/arch/riscv/csr.h>
#include "csr_irq.inc"

#ifdef CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY
#define PLIC_MCAUSE_OFFSET (__struct_arch_esf_soc_context_OFFSET + \
	__soc_esf_t_plic_mcause_OFFSET - __struct_arch_esf_SIZEOF)
#endif

/* exports */
GTEXT(_andes_plic_isr_entry)
/* imports */
GTEXT(_isr_wrapper)
GDATA(plic_mcause)

/*
 * Each Andes Vectored PLIC vector table entry is 4 bytes for both RV32 and RV64.
 * On RV64, the upper 32 bits of the ISR address are taken from mtvec[63:32].
 *
 * The table base must be aligned to a 2^log2(2N+2) byte boundary, where N is
 * the number of PLIC interrupt sources. For example, if N is 1023, the minimum
 * alignment requirement is 4096 bytes.
 *
 * Vector table entries:
 * - mtvec[0] is used for exceptions and non-external local interrupts.
 * - mtvec[i] is used for PLIC external interrupt source i.
 */

/*
 * Entry point for PLIC-sourced interrupts (mtvec[i], i >= 1). Vectored
 * PLIC hardware claims the interrupt and leaves the source ID in mcause
 * with no INTERRUPT bit set. Swap it into plic_mcause, then fake mcause
 * as a standard machine external interrupt so the architecture entry
 * point dispatches through plic_irq_handler as usual.
 */
SECTION_FUNC(exception.entry, _andes_plic_isr_entry)
#ifdef CONFIG_USERSPACE
	/* retrieve address of _current_cpu preserving s0 */
	csrrw s0, mscratch, s0

	/* preserve t0 and t1 temporarily */
	sr t0, _curr_cpu_arch_user_exc_tmp0(s0)
	sr t1, _curr_cpu_arch_user_exc_tmp1(s0)

#ifdef CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY
	/* determine if we come from user space */
	csrr t1, mstatus
	li t0, MSTATUS_MPP
	and t1, t1, t0

	/*
	 * t0: the stack top _isr_wrapper allocates the esf under, which is
	 * the privileged stack when coming from user space.
	 */
	mv t0, sp
	bnez t1, 1f
	lr t0, _curr_cpu_arch_user_exc_sp(s0)
1:
#endif /* CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY */
#else
	/* The esf is allocated later, but it is safe to borrow the members
	 * holding these registers already.
	 */
	sr t0, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t0_OFFSET)(sp)
	sr t1, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t1_OFFSET)(sp)

#ifdef CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY
	/* t0: the stack top _isr_wrapper allocates the esf under */
	mv t0, sp
#endif /* CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY */
#endif /* CONFIG_USERSPACE */

	/* Swap the source ID into plic_mcause. */
	.option push
	.option norelax
#ifdef CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY
	/*
	 * Interrupts are enabled before plic_irq_handler() reads plic_mcause,
	 * so keep the value this interrupt preempts in its esf.
	 */
	la t1, plic_mcause
	lw t1, 0(t1)
	sw t1, PLIC_MCAUSE_OFFSET(t0)
#endif /* CONFIG_PLIC_SUPPORTS_PREEMPTIVE_PRIORITY */
	csrr t1, mcause
	la t0, plic_mcause
	sw t1, 0(t0)
	.option pop

	/* Fake mcause as a machine external interrupt so _isr_wrapper
	 * dispatches it normally.
	 */
	li t1, RISCV_MCAUSE_IRQ_BIT | RISCV_IRQ_MEXT
	csrw mcause, t1

#ifdef CONFIG_USERSPACE
	/* retrieve original t0/t1 values */
	lr t0, _curr_cpu_arch_user_exc_tmp0(s0)
	lr t1, _curr_cpu_arch_user_exc_tmp1(s0)

	/* retrieve original s0 and restore _current_cpu in mscratch */
	csrrw s0, mscratch, s0
#else
	lr t0, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t0_OFFSET)(sp)
	lr t1, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t1_OFFSET)(sp)
#endif /* CONFIG_USERSPACE */

	/* Jump to the architecture ISR wrapper */
	j _isr_wrapper
