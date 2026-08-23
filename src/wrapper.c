// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2026 dere3046
 */

#include <linux/init.h>

extern int rust_mymod_init_module(void);
extern void rust_mymod_cleanup_module(void);

int __init init_module(void)
{
	return rust_mymod_init_module();
}

void __exit cleanup_module(void)
{
	rust_mymod_cleanup_module();
}
