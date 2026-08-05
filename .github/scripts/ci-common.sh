#!/usr/bin/env bash

CI_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CI_REPO_ROOT="${REPO_ROOT:-$(cd -- "$CI_SCRIPT_DIR/../.." && pwd)}"

ci_sync_branch() {
	local branch="$1"
	local target

	cd "$CI_REPO_ROOT" || return 1
	git fetch origin "$branch"
	target="$(git rev-parse "origin/$branch")"
	printf '同步仓库：%s，分支：%s，目标提交：%s\n' \
		"$CI_REPO_ROOT" "$branch" "$target"
	git reset --hard "origin/$branch"
}

ci_commit_and_push() {
	local branch="$1"
	local message="$2"
	local local_head remote_head
	shift 2

	[[ "$message" =~ ^[a-z]+:\ .+ ]] || {
		printf '提交信息格式无效：%s\n' "$message" >&2
		return 1
	}
	(( $# > 0 )) || {
		printf '未提供提交路径。\n' >&2
		return 1
	}

	cd "$CI_REPO_ROOT" || return 1
	local_head="$(git rev-parse HEAD)"
	git fetch origin "$branch"
	remote_head="$(git rev-parse "origin/$branch")"
	if [[ "$local_head" != "$remote_head" ]]; then
		printf '远端分支已更新，为避免提交冲突，本次任务停止：%s -> %s\n' \
			"$local_head" "$remote_head" >&2
		return 75
	fi

	git add -- "$@"
	if git diff --cached --quiet; then
		printf '没有需要提交的变更。\n'
		return 0
	fi
	git diff --cached --check

	git config user.name 'github-actions[bot]'
	git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
	git commit -m "$message"
	git push origin "HEAD:$branch"
}
