// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2026 dere3046
 */

#include <linux/init.h>
#include <linux/module.h>

extern int rust_mymod_init_module(void);
extern void rust_mymod_cleanup_module(void);

/*
 * the rust object renames its init_module/cleanup_module symbols, so the
 * entry points are declared here and module_init/module_exit alias them,
 * which emits the cfi jump table entry the right way for the kernel at hand
 */
static int __init rustmod_init(void)
{
	return rust_mymod_init_module();
}

static void __exit rustmod_exit(void)
{
	rust_mymod_cleanup_module();
}

module_init(rustmod_init);
module_exit(rustmod_exit);
