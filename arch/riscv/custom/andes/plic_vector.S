/*
 * Copyright (c) 2026 Andes Technology Corporation
 * Copyright (c) 2026 Analog Devices, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/arch/riscv/irq.h>
#include "csr_irq.inc"

#define PLIC_MCAUSE_OFFSET (__struct_arch_esf_soc_context_OFFSET + \
	__soc_esf_t_plic_mcause_OFFSET - __struct_arch_esf_SIZEOF)

/* exports */
GTEXT(_isr_wrapper)
/* imports */
GTEXT(_riscv_isr_wrapper)
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
SECTION_FUNC(exception.entry, _isr_wrapper)
#ifdef CONFIG_USERSPACE
	/*
	 * Userspace handling logic should match that in _riscv_isr_wrapper,
	 * we need the same here since we want to save plic_mcause to the
	 * privileged stack
	 */
	/* retrieve address of _current_cpu preserving s0 */
	csrrw s0, mscratch, s0

	/* preserve t0 and t1 temporarily */
	sr t0, _curr_cpu_arch_user_exc_tmp0(s0)
	sr t1, _curr_cpu_arch_user_exc_tmp1(s0)

	/* determine if we come from user space */
	csrr t0, mstatus
	li t1, MSTATUS_MPP
	and t0, t0, t1
	bnez t0, 1f

	/* in user space we were: switch to our privileged stack */
	mv t0, sp
	lr sp, _curr_cpu_arch_user_exc_sp(s0)

	/* Save user stack value. Coming from user space, we know this
	 * can't overflow the privileged stack. The esf will be allocated
	 * later but it is safe to store our saved user sp here. */
	sr t0, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_sp_OFFSET)(sp)
1:
	/* t0/t1 are free here; sp is the privileged stack either way.
	 * Swap the source ID into plic_mcause.
	 */
	csrr t1, mcause
	la t0, plic_mcause
	lw t0, 0(t0)
	sr t0, PLIC_MCAUSE_OFFSET(sp)
	la t0, plic_mcause
	sw t1, 0(t0)

	/* Fake mcause as a machine external interrupt so _isr_wrapper
	 * dispatches it normally.
	 */
	li t1, RISCV_MCAUSE_IRQ_BIT | RISCV_IRQ_MEXT
	csrw mcause, t1

	/* retrieve original t0/t1 values */
	lr t0, _curr_cpu_arch_user_exc_tmp0(s0)
	lr t1, _curr_cpu_arch_user_exc_tmp1(s0)

	/* retrieve original s0 and restore _current_cpu in mscratch */
	csrrw s0, mscratch, s0
#else /* !CONFIG_USERSPACE */
	/* The esf is allocated later, but it is safe to borrow the members
	 * holding these registers already.
	 */
	sr t0, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t0_OFFSET)(sp)
	sr t1, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t1_OFFSET)(sp)

	/* Swap the source ID into plic_mcause. */
	csrr t1, mcause
	la t0, plic_mcause
	lw t0, 0(t0)
	sr t0, PLIC_MCAUSE_OFFSET(sp)
	la t0, plic_mcause
	sw t1, 0(t0)

	/* Fake mcause as a machine external interrupt so _isr_wrapper
	 * dispatches it normally.
	 */
	li t1, RISCV_MCAUSE_IRQ_BIT | RISCV_IRQ_MEXT
	csrw mcause, t1

	lr t0, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t0_OFFSET)(sp)
	lr t1, (-__struct_arch_esf_SIZEOF + __struct_arch_esf_t1_OFFSET)(sp)
#endif
	/* Jump to the architecture ISR wrapper */
	j _riscv_isr_wrapper
