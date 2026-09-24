/*
 * Copyright (c) 2025 Andes Technology Corporation
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/offsets.h>
#include <zephyr/toolchain.h>
#include <andes_csr.h>
#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC
#include <zephyr/arch/riscv/irq.h>
#endif

#ifdef CONFIG_64BIT
	/* register-wide load/store based on ld/sd (XLEN = 64) */

	.macro lr, rd, mem
	ld \rd, \mem
	.endm

	.macro sr, rs, mem
	sd \rs, \mem
	.endm

#else
	/* register-wide load/store based on lw/sw (XLEN = 32) */

	.macro lr, rd, mem
	lw \rd, \mem
	.endm

	.macro sr, rs, mem
	sw \rs, \mem
	.endm

#endif

#ifdef CONFIG_RISCV_SOC_CONTEXT_SAVE

	.macro __custom_csr_save_context __soc_esf_reg reg

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_PFT
	csrr \reg, NDS_MXSTATUS
	sr \reg, __soc_esf_t_mxstatus_OFFSET(\__soc_esf_reg)
#endif

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_HWDSP
	csrr \reg, NDS_UCODE
	sr \reg, __soc_esf_t_ucode_OFFSET(\__soc_esf_reg)
#endif

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC
	/* A nested interrupt may overwrite mcause before the restore */
	csrr \reg, mcause
	sr \reg, __soc_esf_t_mcause_OFFSET(\__soc_esf_reg)
#endif

	.endm

	.macro  __custom_csr_restore_context __soc_esf_reg reg tmp

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_PFT
	lr \reg, __soc_esf_t_mxstatus_OFFSET(\__soc_esf_reg)
	csrw NDS_MXSTATUS, \reg
#endif
#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_HWDSP
	lr \reg, __soc_esf_t_ucode_OFFSET(\__soc_esf_reg)
	csrw NDS_UCODE, \reg
#endif

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC
	/*
	 * Only a vectored PLIC interrupt saved plic_mcause, in Andes custom
	 * _isr_wrapper, which also faked mcause as a machine external
	 * interrupt. Restore plic_mcause to the value it had before that
	 * interrupt overwrote it.
	 */
	lr \reg, __soc_esf_t_mcause_OFFSET(\__soc_esf_reg)
	li \tmp, RISCV_MCAUSE_IRQ_BIT | RISCV_IRQ_MEXT
	bne \reg, \tmp, 1f
	lw \reg, __soc_esf_t_plic_mcause_OFFSET(\__soc_esf_reg)
	la \tmp, plic_mcause
	sw \reg, 0(\tmp)
1:
#endif

	.endm

#endif /* CONFIG_RISCV_SOC_CONTEXT_SAVE */
