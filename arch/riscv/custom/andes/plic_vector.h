/*
 * Copyright (c) 2026 Analog Devices, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_PLIC_VECTOR_H
#define ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_PLIC_VECTOR_H

/*
 * Should be added as part of the SOC_ESF_MEMBERS definition. Holds the
 * value plic_mcause had before this interrupt overwrote it, so it can
 * be restored once this interrupt is done.
 */
#define ANDES_PLIC_SOC_ESF_MEMBERS uint32_t plic_mcause

/*
 * Should be added as part of the SOC_ESF_INIT definition
 */
#define ANDES_PLIC_SOC_ESF_INIT 0

/*
 * Should be added as part of the GEN_SOC_OFFSET_SYMS definition
 */
#define ANDES_PLIC_GEN_SOC_OFFSET_SYMS() \
	GEN_OFFSET_SYM(soc_esf_t, plic_mcause);

#endif /* ZEPHYR_ARCH_RISCV_CUSTOM_ANDES_PLIC_VECTOR_H */
