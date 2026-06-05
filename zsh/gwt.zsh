# ─── Private: repo detection ────────────────────────────────────────────────

_gwt_root() {
  local root git_dir

  # Bare repo containers look like normal directories with a nested .git dir.
  if [[ -d .git && -f .git/HEAD && -f .git/config ]]; then
    pwd
    return 0
  fi

  root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$root" ]]; then
    echo "$root"
    return 0
  fi

  git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || return 1
  if [[ "${git_dir:t}" == ".git" ]]; then
    echo "${git_dir:h}"
    return 0
  fi

  return 1
}

_gwt_ensure_remote_tracking() {
  local remote fetch_refspec

  remote="${1:-origin}"
  git remote get-url "$remote" >/dev/null 2>&1 || return 0

  # Bare clones need an explicit heads->remotes fetch refspec for worktree flows.
  fetch_refspec="+refs/heads/*:refs/remotes/$remote/*"
  if ! git config --get-all "remote.$remote.fetch" 2>/dev/null | grep -Fqx "$fetch_refspec"; then
    if git config --get-all "remote.$remote.fetch" >/dev/null 2>&1; then
      git config --add "remote.$remote.fetch" "$fetch_refspec" || return 1
    else
      git config "remote.$remote.fetch" "$fetch_refspec" || return 1
    fi
  fi

  git fetch "$remote" --prune >/dev/null 2>&1 || return 1
  git remote set-head "$remote" -a >/dev/null 2>&1 || true
}

# ─── Private: branch resolution ─────────────────────────────────────────────

_gwt_infer_default_branch() {
  local head_ref branch
  local -a branches

  # Prefer the remote's advertised default branch when available.
  head_ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  if [[ -n "$head_ref" ]]; then
    echo "${head_ref#refs/remotes/origin/}"
    return 0
  fi

  head_ref=$(git symbolic-ref HEAD 2>/dev/null)
  if [[ -n "$head_ref" ]]; then
    branch="${head_ref#refs/heads/}"
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      echo "$branch"
      return 0
    fi
  fi

  branches=("${(@f)$(git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin 2>/dev/null)}")
  if (( ${#branches[@]} == 1 )); then
    echo "${branches[1]}"
    return 0
  fi

  branches=("${(@f)$(git for-each-ref --format='%(refname:strip=2)' refs/heads 2>/dev/null)}")
  if (( ${#branches[@]} == 1 )); then
    echo "${branches[1]}"
    return 0
  fi

  return 1
}

_gwt_default_branch_name() {
  local default_branch

  default_branch=$(_gwt_infer_default_branch)
  if [[ -n "$default_branch" ]]; then
    echo "$default_branch"
    return 0
  fi

  default_branch=$(git config --get init.defaultBranch 2>/dev/null)
  if [[ -n "$default_branch" ]]; then
    echo "$default_branch"
    return 0
  fi

  echo "main"
}

_gwt_default_base() {
  local default_branch

  default_branch=$(_gwt_default_branch_name)
  if git show-ref --verify --quiet "refs/remotes/origin/$default_branch"; then
    echo "origin/$default_branch"
    return 0
  fi

  echo "$default_branch"
}

# ─── Private: worktree listing ───────────────────────────────────────────────

_gwt_home() {
  local common_git_dir root

  if [[ -n "$WORKTREE_HOME" ]]; then
    echo "$WORKTREE_HOME"
    return 0
  fi

  # Use the shared git dir so linked worktrees resolve the same home as the repo container.
  common_git_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [[ -n "$common_git_dir" && "${common_git_dir:t}" == ".git" ]]; then
    echo "${common_git_dir:h}"
    return 0
  fi

  root=$(_gwt_root) || return 1
  echo "$root"
}

_gwt_entries() {
  # Porcelain output is stable enough for scripting; human output is not.
  git worktree list --porcelain | awk '
    /^worktree / { path = substr($0, 10); next }
    /^branch refs\/heads\// { print substr($0, 19) "\t" path; next }
    /^detached$/ { print "(detached)\t" path; next }
  '
}

_gwt_pick() {
  local action line
  local -a entries

  action="${1:-select}"
  entries=("${(@f)$(_gwt_entries)}")

  if (( ${#entries[@]} == 0 )); then
    echo "No worktrees found"
    return 1
  fi

  if command -v fzf >/dev/null 2>&1; then
    line=$(printf '%s\n' "${entries[@]}" | fzf --prompt="${action}> " --delimiter=$'\t' --with-nth=1,2 --height=40% --reverse) || return 1
    echo "$line"
    return 0
  fi

  local PS3="Select worktree to ${action}: "
  select line in "${entries[@]}"; do
    if [[ -n "$line" ]]; then
      echo "$line"
      return 0
    fi
    echo "Invalid selection"
  done
}

_gwt_resolve_path() {
  local target line branch worktree_path

  target="$1"
  [[ -z "$target" ]] && return 1

  if [[ -d "$target" ]]; then
    echo "$target"
    return 0
  fi

  while IFS=$'\t' read -r branch worktree_path; do
    if [[ "$branch" == "$target" || "$worktree_path" == "$target" || "${worktree_path:t}" == "$target" ]]; then
      echo "$worktree_path"
      return 0
    fi
  done < <(_gwt_entries)

  return 1
}

# ─── Private: actions ────────────────────────────────────────────────────────

_gwt_new() {
  local branch base worktree_path home default_branch

  branch="$1"

  if [[ -z "$branch" ]]; then
    echo "usage: _gwt_new <branch> [base]"
    return 1
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    _gwt_ensure_remote_tracking origin || return 1
  fi

  base="${2:-$(_gwt_default_base)}"
  default_branch=$(_gwt_default_branch_name)

  home=$(_gwt_home) || return 1
  worktree_path="$home/$branch"

  # Branch names may contain slashes, so create parent directories first.
  mkdir -p "${worktree_path:h}" || return 1

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$worktree_path" "$branch" || return 1
  else
    git worktree add -b "$branch" "$worktree_path" "$base" || return 1
  fi

  # If the branch exists on origin, always track it.
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$worktree_path" branch --set-upstream-to="origin/$branch" "$branch" >/dev/null 2>&1 || true
  elif [[ "$base" == origin/* && "$branch" != "$default_branch" ]]; then
    git -C "$worktree_path" branch --unset-upstream "$branch" >/dev/null 2>&1 || true
  fi
}

_gwt_remove_worktree() {
  local force worktree_path

  force="$1"
  worktree_path="$2"

  if [[ -n "$force" ]]; then
    git worktree remove "$force" "$worktree_path" || return 1
  else
    git worktree remove "$worktree_path" || return 1
  fi

  git worktree prune
}

_gwt_apply_sparse_from_default() {
  local branch home worktree_path default_branch default_wt_path patterns cone_mode

  branch="$1"
  if [[ -z "$branch" ]]; then
    echo "usage: _gwt_apply_sparse_from_default <branch>"
    return 1
  fi

  home=$(_gwt_home) || return 1
  worktree_path="$home/$branch"
  default_branch=$(_gwt_default_branch_name)
  default_wt_path="$home/$default_branch"

  if [[ ! -d "$default_wt_path" ]]; then
    echo "No default branch worktree found at $default_wt_path — run gwt-sparse-init first, then: git sparse-checkout add <path>"
    return 1
  fi

  # Sparse-checkout config is per-worktree, so feature worktrees must copy patterns.
  patterns=$(git -C "$default_wt_path" sparse-checkout list 2>/dev/null)
  if [[ -z "$patterns" ]]; then
    echo "No sparse patterns in $default_branch — run: git sparse-checkout add <path> in that worktree first"
    return 1
  fi

  cone_mode=$(git -C "$default_wt_path" config core.sparseCheckoutCone 2>/dev/null)
  if [[ "$cone_mode" == "false" ]]; then
    echo "$patterns" | xargs git -C "$worktree_path" sparse-checkout set --no-cone >/dev/null 2>&1 || return 1
  else
    echo "$patterns" | xargs git -C "$worktree_path" sparse-checkout set >/dev/null 2>&1 || return 1
  fi

  echo "Sparse patterns copied from $default_branch to $branch"
}

_gwt_toggle_lock() {
  local action branch worktree_path

  action="$1"
  branch="$2"
  if [[ -z "$action" || -z "$branch" ]]; then
    echo "usage: _gwt_toggle_lock <lock|unlock> <branch>"
    return 1
  fi

  worktree_path=$(_gwt_resolve_path "$branch") || return 1
  git worktree "$action" "$worktree_path" && echo "${action:u}ed: $worktree_path"
}

# ─── Public: navigation ──────────────────────────────────────────────────────

# gwt() {
#   local cmd="${1:-}"
#   case "$cmd" in
#     branch)            gwt-branch ;;
#     clean)             gwt-clean ;;
#     clone)             shift; gwt-clone "$@" ;;
#     clone-full)        shift; gwt-clone-full "$@" ;;
#     clone-sparse)      shift; gwt-clone-sparse "$@" ;;
#     copy-local)        shift; gwt-copy-local "$@" ;;
#     go|go-full)        shift; gwt-go "$@" ;;
#     go-sparse)         shift; gwt-go-sparse "$@" ;;
#     help)              gwt-help ;;
#     lock)              shift; gwt-lock "$@" ;;
#     ls)                gwt-ls ;;
#     prune)             gwt-prune ;;
#     pull)              gwt-pull ;;
#     rm)                shift; gwt-rm "$@" ;;
#     sparse-init)       shift; gwt-sparse-init "$@" ;;
#     unlock)            shift; gwt-unlock "$@" ;;
#     "")                gwt-help ;;
#     *)                 gwt-go "$@" ;;
#   esac
# }

gwt-go() {
  local branch worktree_path home

  branch="$1"
  if [[ -z "$branch" ]]; then
    local selection
    selection=$(_gwt_pick open) || return 1
    worktree_path="${selection#*$'\t'}"
    cd "$worktree_path"
    return 0
  fi

  home=$(_gwt_home) || return 1
  worktree_path="$home/$branch"

  if [[ ! -d "$worktree_path" ]]; then
    _gwt_new "$@" || return 1
  fi

  cd "$worktree_path"
}

gwt-go-full() {
  gwt-go "$@"
}

gwt-go-sparse() {
  local branch home worktree_path

  branch="$1"
  if [[ -z "$branch" ]]; then
    echo "usage: gwt-go-sparse <branch> [base]"
    return 1
  fi

  _gwt_new "$@" || return 1

  home=$(_gwt_home) || return 1
  worktree_path="$home/$branch"

  _gwt_apply_sparse_from_default "$branch" || return 1
  builtin cd "$worktree_path"
}

# ─── Public: info ────────────────────────────────────────────────────────────

gwt-pull() {
  local default_branch home worktree_path
  default_branch=$(_gwt_default_branch_name) || return 1
  home=$(_gwt_home) || return 1
  worktree_path="$home/$default_branch"
  if [[ ! -d "$worktree_path" ]]; then
    echo "Default branch worktree not found: $worktree_path"
    return 1
  fi
  git -C "$worktree_path" pull
}

gwt-ls() {
  _gwt_entries | awk -F '\t' '{ printf "%-50s %s\n", $1, $2 }'
}

gwt-branch() {
  local default worktree_branches
  default=$(_gwt_default_branch_name 2>/dev/null)
  # collect branches checked out in any worktree as newline-separated list
  worktree_branches=$(git worktree list --porcelain | awk '/^branch refs\/heads\// { print substr($0,19) }')
  git branch -vv | while IFS= read -r line; do
    [[ "$line" =~ '^[*+ ]  ?([^ ]+)' ]] || continue
    local branch=$match[1]
    local matched=0
    while IFS= read -r wt_branch; do
      [[ "$wt_branch" == "$branch" ]] && matched=1 && break
    done <<< "$worktree_branches"
    if [[ $matched -eq 1 || "$branch" == "$default" ]]; then
      echo "$line"
    fi
  done
}

gwt-copy-local() {
  local src_branch src_path home
  home=$(_gwt_home) || return 1
  src_branch="${1:-$(_gwt_default_branch_name)}"
  src_path="$home/$src_branch"
  if [[ ! -d "$src_path" ]]; then
    echo "Source worktree not found: $src_path"
    return 1
  fi
  git -C "$src_path" ls-files --others --ignored --exclude-standard | \
    rsync -a --files-from=- "$src_path/" "$PWD/"
}

# ─── Public: management ──────────────────────────────────────────────────────

gwt-rm() {
  local force target worktree_path selection

  if [[ "$1" == "-f" || "$1" == "--force" ]]; then
    force="--force"
    shift
  fi

  target="$1"
  if [[ -z "$target" ]]; then
    selection=$(_gwt_pick remove) || return 1
    worktree_path="${selection#*$'\t'}"
  else
    worktree_path=$(_gwt_resolve_path "$target") || {
      echo "Unknown worktree: $target"
      return 1
    }
  fi

  _gwt_remove_worktree "$force" "$worktree_path"
}

gwt-clean() {
  local branch worktree_path entry
  local -a gone_branches to_remove

  # Match the same gone-upstream detection as the git 'cl' alias.
  git fetch -p >/dev/null 2>&1

  gone_branches=("${(@f)$(git branch -vv | awk '/: gone]/{print ($1=="+" || $1=="*") ? $2 : $1}')}" )

  if (( ${#gone_branches[@]} == 0 )); then
    echo "No branches with gone upstream found"
    return 0
  fi

  while IFS=$'\t' read -r branch worktree_path; do
    if (( ${gone_branches[(Ie)$branch]} )); then
      to_remove+=("${branch}"$'\t'"${worktree_path}")
    fi
  done < <(_gwt_entries)

  if (( ${#to_remove[@]} == 0 )); then
    echo "No worktrees found for gone branches"
    echo "Gone branches: ${gone_branches[*]}"
    return 0
  fi

  echo "Worktrees with gone upstream:"
  for entry in "${to_remove[@]}"; do
    printf "  %-32s %s\n" "${entry%%$'\t'*}" "${entry#*$'\t'}"
  done

  if command -v fzf >/dev/null 2>&1; then
    local selected
    selected=$(printf '%s\n' "${to_remove[@]}" | \
      fzf --prompt='remove> ' --delimiter=$'\t' --with-nth=1,2 --height=40% --reverse --multi) || return 0
    while IFS=$'\t' read -r branch worktree_path; do
      echo "Removing worktree: $branch ($worktree_path)"
      git worktree remove "$worktree_path" && git worktree prune
    done <<< "$selected"
  else
    echo
    read -r "reply?Remove all listed worktrees? [y/N] "
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      for entry in "${to_remove[@]}"; do
        branch="${entry%%$'\t'*}"
        worktree_path="${entry#*$'\t'}"
        echo "Removing worktree: $branch ($worktree_path)"
        git worktree remove "$worktree_path" && git worktree prune
      done
    fi
  fi
}

gwt-prune() {
  git worktree prune -v
}

gwt-lock() {
  local branch=${1:?usage: gwt-lock <branch>}
  _gwt_toggle_lock lock "$branch"
}

gwt-unlock() {
  local branch=${1:?usage: gwt-unlock <branch>}
  _gwt_toggle_lock unlock "$branch"
}

# ─── Public: clone / bootstrap ───────────────────────────────────────────────

_gwt_clone_bare() {
  local repo_url target_dir repo_name

  repo_url="$1"
  target_dir="$2"

  if [[ -z "$repo_url" ]]; then
    echo "usage: _gwt_clone_bare <repo-url> [directory]"
    return 1
  fi

  if [[ -z "$target_dir" ]]; then
    repo_name="${repo_url:t}"
    target_dir="${repo_name%.git}"
  fi

  if [[ -e "$target_dir" && -n "$(command ls -A "$target_dir" 2>/dev/null)" ]]; then
    echo "Target directory exists and is not empty: $target_dir"
    return 1
  fi

  mkdir -p "$target_dir" || return 1
  git clone --bare "$repo_url" "$target_dir/.git" || return 1
}

gwt-clone() {
  local repo_url target_dir repo_name default_branch home worktree_path

  repo_url="$1"
  target_dir="$2"

  if [[ -z "$repo_url" ]]; then
    echo "usage: gwt-clone <repo-url> [directory]"
    return 1
  fi

  if [[ -z "$target_dir" ]]; then
    repo_name="${repo_url:t}"
    target_dir="${repo_name%.git}"
  fi

  _gwt_clone_bare "$repo_url" "$target_dir" || return 1
  builtin cd "$target_dir" || return 1

  if git remote get-url origin >/dev/null 2>&1; then
    _gwt_ensure_remote_tracking origin || return 1
  fi

  default_branch=$(_gwt_infer_default_branch)
  if [[ -z "$default_branch" ]]; then
    default_branch=$(git config --get init.defaultBranch 2>/dev/null)
  fi

  if [[ -z "$default_branch" ]]; then
    echo "Could not determine default branch."
    echo "Run one of: gwt-go main | gwt-go master | gwt-go <branch>"
    return 1
  fi

  _gwt_new "$default_branch" || return 1

  home=$(_gwt_home) || return 1
  worktree_path="$home/$default_branch"
  echo "Default worktree ready: $worktree_path"
  echo "Next: cd $worktree_path"
}

gwt-clone-full() {
  gwt-clone "$@"
}

gwt-clone-sparse() {
  local repo_url target_dir repo_name

  repo_url="$1"
  target_dir="$2"

  if [[ -z "$repo_url" ]]; then
    echo "usage: gwt-clone-sparse <repo-url> [directory]"
    return 1
  fi

  if [[ -z "$target_dir" ]]; then
    repo_name="${repo_url:t}"
    target_dir="${repo_name%.git}"
  fi

  _gwt_clone_bare "$repo_url" "$target_dir" || return 1
  builtin cd "$target_dir" || return 1
  gwt-sparse-init || return 1
}

gwt-sparse-init() {
  local branch default_branch home worktree_path

  # This bootstraps the default branch worktree with an empty sparse checkout.
  default_branch=$(_gwt_default_branch_name)
  branch="${1:-$default_branch}"

  _gwt_new "$branch" || return 1

  home=$(_gwt_home) || return 1
  worktree_path="$home/$branch"

  git -C "$worktree_path" sparse-checkout set || return 1
  echo "Sparse worktree ready: $worktree_path"
  echo "Next: cd $worktree_path && git sparse-checkout add <path> [<path>...]"
}

# ─── Help ────────────────────────────────────────────────────────────────────

gwt-help() {
  cat <<'EOF'
git worktree helpers
────────────────────────────────────────────────────────────────
All gwt-* commands can also be called as: gwt <subcommand> [args]
e.g.  gwt clone <url>  ·  gwt go <branch>  ·  gwt ls

setup
  gwt-clone <repo-url> [dir]         bare clone + default worktree (alias: gwt-clone-full)
                                      if default branch is unclear, prints manual gwt-go options
  gwt-clone-sparse <repo-url> [dir]  bare clone + sparse init

daily workflow
  gwt-go                       pick a worktree interactively and cd into it
  gwt-go <branch>              cd into worktree with full checkout (creates if missing)
  gwt-go-sparse <branch>       cd into worktree with sparse checkout (copies patterns from default branch)
  gwt-pull                     pull the default branch worktree
  gwt-copy-local [branch]      copy ignored/untracked files from a worktree into the current one (default: default branch)
  gwt-ls                       list all worktrees
  gwt-branch                   list only HEAD, default, and worktree branches (with upstream status)

cleanup
  gwt-rm [-f] [branch]         remove a worktree (interactive picker if no arg)
  gwt-clean                    find worktrees with gone upstream, remove interactively
  gwt-prune                    prune stale worktree records
  gwt-lock <branch>            lock a worktree (prevent pruning)
  gwt-unlock <branch>          unlock a worktree

────────────────────────────────────────────────────────────────
Worktrees are created under: ${WORKTREE_HOME:-<repo-root>}/<branch>
EOF
}
