#!/usr/bin/ucode -S
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * "Core only" mode runs the user's own raw sing-box config file
 * as-is. Unlike HomeProxy's own generated client config (see
 * generate_client.uc), it never gets an automatic
 * "experimental.cache_file" - so unless the user's config already
 * sets one, every single start has to re-fetch remote rule-sets
 * from scratch instead of reusing a cached copy, even on the 2nd,
 * 3rd, ... restart within the same boot.
 *
 * This copies the selected core config into a working copy and,
 * only if "experimental.cache_file" is completely absent, fills in
 * a cache_file pointing under HP_DIR (a persistent path, so it also
 * survives reboots) so restarts can skip the re-download. If the
 * user already set "experimental.cache_file" themselves - even just
 * "enabled": false - that choice is left untouched.
 *
 * Usage: ucode -S inject_core_cache.uc <input_config> <output_config>
 */

'use strict';

import { readfile, writefile } from 'fs';
import { HP_DIR } from 'homeproxy';

const input = ARGV[0], output = ARGV[1];

let raw = readfile(input);
let conf;
try {
	conf = json(raw);
} catch (e) {
	conf = null;
}

if (type(conf) == 'object') {
	if (type(conf.experimental) != 'object')
		conf.experimental = {};

	if (conf.experimental.cache_file == null) {
		/* User didn't set cache_file at all - turn it on with a
		 * persistent path. */
		conf.experimental.cache_file = {
			enabled: true,
			path: `${HP_DIR}/core_cache.db`
		};
	} else if (type(conf.experimental.cache_file) == 'object' &&
	           conf.experimental.cache_file.path == null) {
		/* User already set cache_file (e.g. just "enabled": true)
		 * but left "path" unset - sing-box then falls back to a
		 * relative "cache.db" in procd's cwd, which isn't a
		 * meaningful persistent location. Only the path is filled
		 * in here; enabled/store_fakeip/etc. are left exactly as
		 * the user set them. */
		conf.experimental.cache_file.path = `${HP_DIR}/core_cache.db`;
	}

	writefile(output, sprintf('%.J\n', conf));
} else {
	/* Not valid JSON (or empty/unreadable) - fall back to a
	 * verbatim copy so startup still gets a clear "wrong core
	 * configuration detected" error from `sing-box check` below,
	 * instead of silently failing here with no explanation. */
	writefile(output, raw || '');
}
