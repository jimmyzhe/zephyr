/*
 * Copyright (c) 2025 Andes Technology Corporation
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/offsets.h>
#include <zephyr/toolchain.h>
#include <andes_csr.h>

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

	/*
	 * plic_mcause is not saved here: the PLIC vector table entry
	 * already swaps the previous value into this esf, before this
	 * save context call runs.
	 */

	.endm

	.macro  __custom_csr_restore_context __soc_esf_reg reg

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_PFT
	lr \reg, __soc_esf_t_mxstatus_OFFSET(\__soc_esf_reg)
	csrw NDS_MXSTATUS, \reg
#endif
#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_HWDSP
	lr \reg, __soc_esf_t_ucode_OFFSET(\__soc_esf_reg)
	csrw NDS_UCODE, \reg
#endif

#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC
	/* Restore plic_mcause to the value it had before this
	 * interrupt overwrote it.
	 */
	lr \reg, __soc_esf_t_plic_mcause_OFFSET(\__soc_esf_reg)
	la t1, plic_mcause
	sw \reg, 0(t1)
#endif

	.endm

#endif /* CONFIG_RISCV_SOC_CONTEXT_SAVE */
