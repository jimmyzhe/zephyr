/*
 * Copyright (c) 2021 Andes Technology Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "soc_v5.h"

#include <zephyr/offsets.h>
#include <zephyr/toolchain.h>
#include <zephyr/arch/riscv/irq.h>

#ifdef CONFIG_RISCV_SOC_CONTEXT_SAVE

/* Exports */
GTEXT(__soc_save_context)
GTEXT(__soc_restore_context)

SECTION_FUNC(exception.other, __soc_save_context)

#ifdef CONFIG_SOC_ANDES_V5_PFT
	csrr t0, NDS_MXSTATUS
#endif
#ifdef CONFIG_SOC_ANDES_V5_HWDSP
	csrr t1, NDS_UCODE
#endif

#ifdef CONFIG_SOC_ANDES_V5_PFT
	sw t0, __soc_esf_t_mxstatus_OFFSET(a0)
#endif
#ifdef CONFIG_SOC_ANDES_V5_HWDSP
	sw t1, __soc_esf_t_ucode_OFFSET(a0)
#endif
	ret

SECTION_FUNC(exception.other, __soc_restore_context)

#ifdef CONFIG_SOC_ANDES_V5_PFT
	lw t0, __soc_esf_t_mxstatus_OFFSET(a0)
#endif
#ifdef CONFIG_SOC_ANDES_V5_HWDSP
	lw t1, __soc_esf_t_ucode_OFFSET(a0)
#endif

#ifdef CONFIG_SOC_ANDES_V5_PFT
	csrw NDS_MXSTATUS, t0
#endif
#ifdef CONFIG_SOC_ANDES_V5_HWDSP
	csrw NDS_UCODE, t1
#endif

#ifdef CONFIG_SOC_ANDES_AE350_CLIC
	/*
	 * Keep the interrupt state for Andes ECLIC implementation to restore
	 * interrupt level when MRET.
	 */
	addi a0, a0, -__struct_arch_esf_soc_context_OFFSET
	lr t0, __struct_arch_esf_mcause_OFFSET(a0)
	li t1, 1 << RISCV_MCAUSE_IRQ_POS
	or t0, t0, t1
	sr t0, __struct_arch_esf_mcause_OFFSET(a0)
#endif

	ret

#endif /* CONFIG_RISCV_SOC_CONTEXT_SAVE */
