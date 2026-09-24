/*
 * Copyright (c) 2025 Andes Technology Corporation
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Extra definitions required for CONFIG_RISCV_SOC_CONTEXT_SAVE.
 */

#ifndef ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_CSR_CONTEXT_H_
#define ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_CSR_CONTEXT_H_

#ifdef CONFIG_RISCV_SOC_CONTEXT_SAVE

/*
 * Andes Vectored PLIC. mcause is the CSR as this interrupt found it, which
 * tells on restore whether it was a vectored PLIC interrupt. plic_mcause holds
 * the value plic_mcause had before such an interrupt overwrote it, so it can
 * be restored once it is done.
 */
#ifdef CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC
	#define ANDES_VECTORED_PLIC_ESF_MEMBERS		\
		unsigned long mcause;			\
		uint32_t plic_mcause;

	#define ANDES_VECTORED_PLIC_ESF_INIT		\
		0,					\
		0,
#else
	#define ANDES_VECTORED_PLIC_ESF_MEMBERS

	#define ANDES_VECTORED_PLIC_ESF_INIT

#endif

/* Andes V5 specific registers. */
#if defined(CONFIG_RISCV_CUSTOM_CSR_ANDES_PFT) && \
	defined(CONFIG_RISCV_CUSTOM_CSR_ANDES_HWDSP)
	#define CUSTOM_CSR_ESF_MEMBERS			\
		ANDES_VECTORED_PLIC_ESF_MEMBERS		\
		uint32_t mxstatus;			\
		uint32_t ucode				\

	#define CUSTOM_CSR_ESF_INIT			\
		ANDES_VECTORED_PLIC_ESF_INIT		\
		0,					\
		0

#elif defined(CONFIG_RISCV_CUSTOM_CSR_ANDES_PFT)
	#define CUSTOM_CSR_ESF_MEMBERS			\
		ANDES_VECTORED_PLIC_ESF_MEMBERS		\
		uint32_t mxstatus

	#define CUSTOM_CSR_ESF_INIT			\
		ANDES_VECTORED_PLIC_ESF_INIT		\
		0

#elif defined(CONFIG_RISCV_CUSTOM_CSR_ANDES_HWDSP)
	#define CUSTOM_CSR_ESF_MEMBERS			\
		ANDES_VECTORED_PLIC_ESF_MEMBERS		\
		uint32_t ucode

	#define CUSTOM_CSR_ESF_INIT			\
		ANDES_VECTORED_PLIC_ESF_INIT		\
		0

#elif defined(CONFIG_RISCV_CUSTOM_CSR_ANDES_VECTORED_PLIC)
	#define CUSTOM_CSR_ESF_MEMBERS			\
		unsigned long mcause;			\
		uint32_t plic_mcause

	#define CUSTOM_CSR_ESF_INIT			\
		0,					\
		0

#else
	#define CUSTOM_CSR_ESF_MEMBERS

	#define CUSTOM_CSR_ESF_INIT

#endif

#endif /* CONFIG_RISCV_SOC_CONTEXT_SAVE */

#endif /* ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_CSR_CONTEXT_H_ */
