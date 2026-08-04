#!/usr/bin/ucode -S
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Fetch one "custom_profile" (Subscription) entry: downloads its "url"
 * as a raw sing-box JSON config, saves it under
 * <HP_DIR>/custom/.subscriptions/<section_id>.json, and (if the server
 * sends a "Subscription-Userinfo" header) records used/total/expire
 * traffic info back into uci, same as HomeProxy's node subscriptions.
 *
 * Usage:
 *   ucode -S update_custom_config.uc [profile_section_id]
 *
 * With no argument, config.main_core_profile is checked: if it points
 * at a "sub:<id>" entry, that entry is refreshed. This is what the
 * auto-update cron job and "Core only" startup call.
 * With an argument, that specific profile is refreshed regardless of
 * whether it is the active one (used by the per-row "Update" button).
 */

'use strict';

import { writefile } from 'fs';
import { cursor } from 'uci';

import { executeCommand, shellQuote, wGET, getTime, isEmpty, HP_DIR } from 'homeproxy';

const uci = cursor();
const uciconfig = 'homeproxy';
uci.load(uciconfig);

const CUSTOM_DIR = `${HP_DIR}/custom`;
/* Hidden (dot-prefixed) so it doesn't show up in the "Upload Profile"
 * file browser, which only lists user-uploaded files by default. */
const SUB_DIR = `${CUSTOM_DIR}/.subscriptions`;

function formatFilesize(bytes) {
	if (isEmpty(bytes))
		return null;

	const units = [ 'B', 'KB', 'MB', 'GB', 'TB', 'PB' ];
	let size = +bytes, i = 0;
	while (size >= 1024 && i < length(units) - 1) {
		size /= 1024;
		i++;
	}

	return sprintf('%.2f %s', size, units[i]);
}

/* Best-effort only: dumps response headers via "wget -S" to try and
 * read a "Subscription-Userinfo" header for traffic stats. Not every
 * wget build (e.g. some BusyBox variants) supports -S, so any
 * failure here is silently ignored - it must never block or fail the
 * actual config download below, which uses the plain, always-working
 * wGET() that HomeProxy's node subscriptions already rely on. */
function fetchHeaders(url, ua) {
	if (isEmpty(url))
		return null;

	const result = executeCommand(
		`/usr/bin/wget -O /dev/null -S --user-agent ${shellQuote(ua || 'sing-box/1.13.16')} --timeout=10 ${shellQuote(url)}`
	);

	return result?.stderr || null;
}

function parseUserinfo(headers) {
	if (isEmpty(headers))
		return {};

	const line = match(headers, /[Ss]ubscription-[Uu]serinfo:[^\r\n]+/);
	if (!line)
		return {};

	const info = line[0];
	const expireM = match(info, /expire=([0-9]+)/),
	      uploadM = match(info, /upload=([0-9]+)/),
	      downloadM = match(info, /download=([0-9]+)/),
	      totalM = match(info, /total=([0-9]+)/);

	let ret = {};
	if (expireM)
		ret.expire = int(expireM[1]);
	if (uploadM)
		ret.upload = int(uploadM[1]);
	if (downloadM)
		ret.download = int(downloadM[1]);
	if (totalM)
		ret.total = int(totalM[1]);

	return ret;
}

let profile_id = ARGV[0];
if (isEmpty(profile_id)) {
	const active = uci.get(uciconfig, 'config', 'main_core_profile');
	if (active && index(active, 'sub:') === 0)
		profile_id = substr(active, 4);
}

if (isEmpty(profile_id)) {
	warn('Error: no subscription profile specified and "Core only" is not currently using one.\n');
	exit(1);
}

const label = uci.get(uciconfig, profile_id, 'label') || profile_id,
      info_url = uci.get(uciconfig, profile_id, 'info_url'),
      url = uci.get(uciconfig, profile_id, 'url'),
      user_agent = uci.get(uciconfig, profile_id, 'user_agent');

if (isEmpty(url)) {
	warn(`Error: profile "${label}" has no subscription URL configured.\n`);
	exit(1);
}

/* Reset stale info first, same as HomeProxy's node subscriptions */
uci.delete(uciconfig, profile_id, 'used');
uci.delete(uciconfig, profile_id, 'total');
uci.delete(uciconfig, profile_id, 'expire');
uci.delete(uciconfig, profile_id, 'success');

system(`mkdir -p ${SUB_DIR}`);

/* Traffic info (used/total/expire) is best-effort only, tried first
 * from a dedicated info_url if set, else from the main url's own
 * headers. Its failure (unsupported wget build, no such header,
 * network hiccup, ...) must never stop the actual config download
 * below. */
let userinfo = parseUserinfo(fetchHeaders(!isEmpty(info_url) ? info_url : url, user_agent));

const body = wGET(url, user_agent);
if (isEmpty(body)) {
	warn(`Error: failed to fetch subscription "${label}" from ${url}.\n`);
	exit(1);
}

if (!writefile(`${SUB_DIR}/${profile_id}.json`, body)) {
	warn(`Error: failed to save subscription "${label}".\n`);
	exit(1);
}

if (userinfo.expire)
	uci.set(uciconfig, profile_id, 'expire', getTime(userinfo.expire));
if (!isEmpty(userinfo.upload) && !isEmpty(userinfo.download))
	uci.set(uciconfig, profile_id, 'used', formatFilesize(userinfo.upload + userinfo.download));
if (userinfo.total)
	uci.set(uciconfig, profile_id, 'total', formatFilesize(userinfo.total));

uci.set(uciconfig, profile_id, 'update', getTime());
uci.set(uciconfig, profile_id, 'success', '1');
uci.commit(uciconfig);

print(`Subscription "${label}" fetched successfully.\n`);
