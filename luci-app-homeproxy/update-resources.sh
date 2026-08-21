#!/bin/sh

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/root/etc/homeproxy/resources"
DASHBOARD_DIR="$SCRIPT_DIR/root/etc/homeproxy/dashboard"

GH_API="https://api.github.com"

log() {
	printf '[homeproxy] %s\n' "$*"
}

curl_get() {
	if [ -n "$GITHUB_TOKEN" ]; then
		curl -fsSL --connect-timeout 8 --max-time 20 --retry 2 --retry-delay 2 \
			-H "Authorization: Bearer $GITHUB_TOKEN" "$1"
	else
		curl -fsSL --connect-timeout 8 --max-time 20 --retry 2 --retry-delay 2 "$1"
	fi
}

json_first_sha() {
	if command -v jq >"/dev/null" 2>&1; then
		jq -r '.[0].sha // empty' 2>"/dev/null"
	else
		grep -o '"sha"[[:space:]]*:[[:space:]]*"[0-9a-f]*"' | head -n1 | sed -E 's/.*"([0-9a-f]+)"$/\1/'
	fi
}

json_first_message() {
	if command -v jq >"/dev/null" 2>&1; then
		jq -r '.[0].commit.message // empty' 2>"/dev/null"
	else
		grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"//;s/"$//'
	fi
}

if ! command -v curl >"/dev/null" 2>&1; then
	log "curl not found, skipping resource update and using local fallback version."
	exit 0
fi
if ! command -v unzip >"/dev/null" 2>&1; then
	log "unzip not found, dashboard update will be skipped; using local fallback version."
fi

mkdir -p "$RESOURCES_DIR" "$DASHBOARD_DIR" 2>"/dev/null"

update_list() {
	listtype="$1"
	listrepo="$2"
	listref="$3"
	listname="$4"

	list_info="$(curl_get "$GH_API/repos/$listrepo/commits?sha=$listref&path=$listname&per_page=1")"
	if [ -z "$list_info" ]; then
		log "[$listtype] Failed to access GitHub API, keeping local fallback version."
		return 0
	fi

	list_sha="$(printf '%s' "$list_info" | json_first_sha)"
	list_ver="$(printf '%s' "$list_info" | json_first_message | grep -Eo '[0-9-]+' | tr -d '-' | head -n1)"
	if [ -z "$list_sha" ] || [ -z "$list_ver" ]; then
		log "[$listtype] Failed to parse latest version, keeping local fallback version."
		return 0
	fi

	local_ver="$(cat "$RESOURCES_DIR/$listtype.ver" 2>"/dev/null")"
	if [ "$local_ver" = "$list_ver" ]; then
		log "[$listtype] Already up to date ($list_ver), skipping."
		return 0
	fi

	tmpfile="$(mktemp)"
	if ! curl -fsSL --connect-timeout 8 --max-time 30 --retry 2 --retry-delay 2 \
		"https://fastly.jsdelivr.net/gh/$listrepo@$list_sha/$listname" -o "$tmpfile" \
		|| [ ! -s "$tmpfile" ]; then
		log "[$listtype] Download failed, keeping local fallback version."
		rm -f "$tmpfile"
		return 0
	fi

	mv -f "$tmpfile" "$RESOURCES_DIR/$listtype.${listname##*.}"
	printf '%s\n' "$list_ver" >"$RESOURCES_DIR/$listtype.ver"
	log "[$listtype] Updated to version $list_ver."

	if [ "$listtype" = "china_list" ]; then
		sed -i -e 's/full://g' -e '/:/d' "$RESOURCES_DIR/china_list.txt"
	fi
}

update_dashboard() {
	if ! command -v unzip >"/dev/null" 2>&1; then
		return 0
	fi

	repo="SagerNet/sing-box-dashboard"
	branch="gh-pages"

	commit_info="$(curl_get "$GH_API/repos/$repo/commits?sha=$branch&per_page=1")"
	if [ -z "$commit_info" ]; then
		log "[dashboard] Failed to access GitHub API, keeping local fallback version."
		return 0
	fi

	commit_sha="$(printf '%s' "$commit_info" | json_first_sha)"
	if [ -z "$commit_sha" ]; then
		log "[dashboard] Failed to parse latest version, keeping local fallback version."
		return 0
	fi
	dashboard_ver="$(printf '%.7s' "$commit_sha")"

	local_ver="$(cat "$RESOURCES_DIR/dashboard.ver" 2>"/dev/null")"
	if [ "$local_ver" = "$dashboard_ver" ] && [ -s "$DASHBOARD_DIR/index.html" ]; then
		log "[dashboard] Already up to date ($dashboard_ver), skipping."
		return 0
	fi

	tmp_zip="$(mktemp)"
	tmp_extract="$(mktemp -d)"

	if ! curl -fsSL --connect-timeout 8 --max-time 60 --retry 2 --retry-delay 2 \
		"https://codeload.github.com/$repo/zip/$commit_sha" -o "$tmp_zip" \
		|| [ ! -s "$tmp_zip" ]; then
		log "[dashboard] Download failed, keeping local fallback version."
		rm -f "$tmp_zip"
		rm -rf "$tmp_extract"
		return 0
	fi

	if ! unzip -q -o "$tmp_zip" -d "$tmp_extract"; then
		log "[dashboard] Unzip failed, keeping local fallback version."
		rm -f "$tmp_zip"
		rm -rf "$tmp_extract"
		return 0
	fi

	index_file="$(find "$tmp_extract" -maxdepth 2 -name 'index.html' | head -n1)"
	if [ -z "$index_file" ]; then
		log "[dashboard] Invalid archive content (index.html not found), keeping local fallback version."
		rm -f "$tmp_zip"
		rm -rf "$tmp_extract"
		return 0
	fi
	src_dir="$(dirname "$index_file")"

	rm -rf "$DASHBOARD_DIR"
	mkdir -p "$DASHBOARD_DIR"
	cp -a "$src_dir"/. "$DASHBOARD_DIR"/
	find "$DASHBOARD_DIR" -type d -exec chmod 755 {} \;
	find "$DASHBOARD_DIR" -type f -exec chmod 644 {} \;

	printf '%s\n' "$dashboard_ver" >"$RESOURCES_DIR/dashboard.ver"
	log "[dashboard] Updated to version $dashboard_ver."

	rm -f "$tmp_zip"
	rm -rf "$tmp_extract"
}

update_list "china_ip4" "1715173329/IPCIDR-CHINA" "master" "ipv4.txt"
update_list "china_ip6" "1715173329/IPCIDR-CHINA" "master" "ipv6.txt"
update_list "gfw_list" "Loyalsoldier/v2ray-rules-dat" "release" "gfw.txt"
update_list "china_list" "Loyalsoldier/v2ray-rules-dat" "release" "direct-list.txt"
update_dashboard

log "All checks completed."
exit 0
