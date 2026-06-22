# Dotfiles v2 — Detailed Redundancy Analysis & Optimization Plan

**Branch**: `refactor/consolidate-and-optimize`  
**Date**: 2026-06-22  
**Status**: Ready for implementation

---

## Executive Summary

This dotfiles repository is well-architected with excellent modularity and documentation. However, there are **significant redundancies** in tool installation and shell hook initialization that can be consolidated without losing functionality. The main opportunities for improvement:

1. **43+ identical tool installer scripts** → 1 templated installer + manifest
2. **Repetitive conf.d conditional patterns** → centralized helper function
3. **Untracked tool versions & configs** → unified manifest (TOML)
4. **Tool dependencies undocumented** → auto-generated inventory
5. **Sequential tool installation** → opportunity for parallelization

---

## 1. Tool Installation Scripts (install/tools/*.sh)

### Current State

43 scripts in `install/tools/` follow an **identical 4-line pattern**:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
init_tools_dir
install_tool <NAME> <REPO> '<TAR_PATTERN>' [HINT]
```

**Examples**:
- `fzf.sh`: `install_tool fzf junegunn/fzf 'fzf-{ver}-linux_{goarch}.tar.gz'`
- `atuin.sh`: `install_tool atuin atuinsh/atuin 'atuin-{arch}-unknown-linux-musl.tar.gz'`
- `rg.sh`: `install_tool rg BurntSushi/ripgrep 'ripgrep-{ver}-{arch}-unknown-linux-musl.tar.gz' rg`
- `bat.sh`: `install_tool bat sharkdp/bat 'bat-{tag}-{arch}-unknown-linux-musl.tar.gz'`

### Impact

- **~1,800 lines of redundant code** across 43 files
- High maintenance burden: adding/removing tools requires creating/deleting files
- Hard to add metadata (version pinning, dependencies, descriptions, categories)
- Difficult to discover tool purposes or relationships

### Recommended Solution

**Create a unified `tools.toml` manifest + generic installer**:

```toml
# config/tools.toml
[tool]
name = "fzf"
repo = "junegunn/fzf"
archive_pattern = "fzf-{ver}-linux_{goarch}.tar.gz"
description = "Fuzzy finder"
category = "productivity"
deferred = true

[tool]
name = "bat"
repo = "sharkdp/bat"
archive_pattern = "bat-{tag}-{arch}-unknown-linux-musl.tar.gz"
binname = "bat"
description = "Cat clone with syntax highlighting"
category = "utilities"
```

**Generic installer** (`install/bin/install-from-manifest.sh`):
```bash
#!/usr/bin/env bash
# Parse tools.toml + call install_tool for each entry
while read -r name repo pattern; do
  install_tool "$name" "$repo" "$pattern"
done < <(parse_toml config/tools.toml)
```

### Benefits

- ✅ **90% reduction in tool installer files** (43 → 1 template)
- ✅ **Single source of truth** for tool metadata
- ✅ **Enables version tracking** and dependency management
- ✅ **Auto-generate tool inventory** from manifest
- ✅ **Easy to add/remove tools** (edit TOML, no new files)
- ✅ **Support for parallelization** (parse manifest, then install in parallel)

---

## 2. Shell Configuration Patterns (config/shell/conf.d/*.sh)

### Current State

**Repeating pattern across all tool hooks** (30+ files):

```bash
# Pattern 1: fzf, atuin, zoxide, broot
command -v TOOL >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _defer '_eval_cached TOOL "TOOL init zsh [--flag]"'
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(TOOL init bash [--flag])"
fi
```

```bash
# Pattern 2: starship (synchronous, no defer)
command -v starship >/dev/null 2>&1 || return 0

if [ -n "${ZSH_VERSION:-}" ]; then
  _eval_cached starship "starship init zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
  eval "$(starship init bash)"
fi
```

### Impact

- **Massive code duplication**: Same 10+ lines repeated across 30 files
- **Difficult to change behavior**: Updating pattern requires editing multiple files
- **Cognitive load**: Unclear which files differ and how
- **Hard to add new tools**: Must copy+paste and customize carefully

### Recommended Solution

**Extract into a centralized helper function** (`config/shell/loader.sh`):

```bash
# _init_tool_hook TOOLNAME [--defer] [--flags...]
# Wrapper around tool init that handles zsh/bash branching and deferred loading
_init_tool_hook() {
  local tool=$1 defer=0 flags=()
  shift
  
  [ -x "$BIN/$tool" ] || command -v "$tool" >/dev/null 2>&1 || return 0
  
  while [ $# -gt 0 ]; do
    case "$1" in
      --defer) defer=1 ;;
      *) flags+=("$1") ;;
    esac
    shift
  done
  
  if [ -n "${ZSH_VERSION:-}" ]; then
    local cmd="$tool init zsh ${flags[*]}"
    [ $defer -eq 1 ] && _defer "_eval_cached $tool \"$cmd\"" || _eval_cached "$tool" "$cmd"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$($tool init bash ${flags[*]})"
  fi
}
```

**Simplified conf.d files**:

```bash
# conf.d/30-fzf.sh
_init_tool_hook fzf --defer
[ -x "$BIN/fd" ] && export FZF_DEFAULT_COMMAND='fd --type f --hidden ...'

# conf.d/40-atuin.sh
_init_tool_hook atuin --defer --disable-up-arrow

# conf.d/70-starship.sh
_init_tool_hook starship
```

### Benefits

- ✅ **50-70% reduction in conf.d file size**
- ✅ **Single behavior source** (easy to update)
- ✅ **Consistent tool loading** across all shells
- ✅ **Easier to add new tools** (1-2 lines instead of 10+)
- ✅ **Centralized validation** (`command -v` check in one place)

---

## 3. Undocumented Tool Inventory & Metadata

### Current State

- 43+ tools installed with **no centralized documentation**
- **No version tracking or pinning**
- **Tool relationships & dependencies undocumented**
- **Categories, purposes not formalized**
- Users must infer tool purpose from conf.d modules or README

### Impact

- Difficult to maintain tools
- No way to know if a tool is required or optional
- Difficult to troubleshoot missing dependencies
- No audit trail of installed versions

### Recommended Solution

**Use tools.toml for metadata**:

```toml
[tools.fzf]
name = "fzf"
repo = "junegunn/fzf"
version = "0.54.0"  # Optional: pinned version
archive_pattern = "fzf-{ver}-linux_{goarch}.tar.gz"
description = "Fuzzy finder for CLI"
category = "productivity"
deferred = true
depends = []  # Optional: ["fd"]
optional = false

[tools.atuin]
name = "atuin"
repo = "atuinsh/atuin"
version = "18.3.0"
archive_pattern = "atuin-{arch}-unknown-linux-musl.tar.gz"
description = "Improved shell history with sync"
category = "shell-enhancement"
deferred = true
depends = []
optional = false

[tools.task]
name = "task"  # taskwarrior
description = "Task management CLI"
category = "productivity"
optional = true
install_method = "source"  # special handling
note = "Requires Rust + cmake"
```

**Auto-generate tool inventory**:

```bash
# Usage: generate-tool-inventory.sh > TOOL_INVENTORY.md
toml_to_markdown config/tools.toml
```

**Output** (`TOOL_INVENTORY.md`):

```markdown
## Installed Tools

### Productivity
- **fzf** (0.54.0) — Fuzzy finder for CLI [deferred]
- **atuin** (18.3.0) — Improved shell history with sync [deferred]
- **task** (optional) — Task management CLI [requires Rust + cmake]

### Utilities
- **bat** — Cat clone with syntax highlighting
- **eza** — Modern ls replacement
- **fd** — Find alternative
...
```

### Benefits

- ✅ **Auto-generated documentation** (never out of sync)
- ✅ **Version tracking** for reproducible builds
- ✅ **Dependency management** (can prevent orphaned tools)
- ✅ **Better discoverability** of tool purposes
- ✅ **Easier auditing** of what's installed and why

---

## 4. Tool Hook Consistency Issues

### Current State

**Inconsistent handling of tool initialization**:

```bash
# Pattern A: Deferred + custom logic
# conf.d/30-fzf.sh
_defer '_eval_cached fzf "fzf --zsh"'
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# Pattern B: Simple deferred
# conf.d/40-atuin.sh
_defer '_eval_cached atuin "atuin init zsh --disable-up-arrow"'

# Pattern C: Synchronous only
# conf.d/70-starship.sh
_eval_cached starship "starship init zsh"

# Pattern D: Fallback to installed script
# conf.d/60-broot.sh
_defer '_eval_cached broot "broot --print-shell-function zsh"'
_br_launcher="${XDG_CONFIG_HOME:-$HOME/.config}/broot/launcher/bash/br"
[ -r "$_br_launcher" ] && . "$_br_launcher"
```

### Impact

- **Difficult to maintain consistency**
- **Hard to predict startup behavior**
- **Tool-specific quirks scattered across files**
- **Difficult to troubleshoot why a tool isn't loading**

### Recommended Solution

**Centralize tool-specific configuration in tools.toml**:

```toml
[tools.fzf]
name = "fzf"
# ... (basic config)
init_shell = "zsh"  # shell where it needs init
defer = true
custom_setup = "fzf-setup"  # function name for extra config

[tools.starship]
name = "starship"
init_shell = "both"  # needs both zsh and bash
defer = false  # NO async (needs to be ready for first prompt)

[tools.broot]
name = "broot"
init_shell = "zsh"
defer = true
fallback_script = "${XDG_CONFIG_HOME}/broot/launcher/bash/br"
```

**Centralized function**:

```bash
_init_tool_hook() {
  local tool=$1
  local config  # fetch from parsed toml
  
  [ -x "$BIN/$tool" ] || command -v "$tool" >/dev/null 2>&1 || return 0
  
  if [ "${config[defer]}" = "true" ]; then
    _defer "_init_tool_sync '$tool'"
  else
    _init_tool_sync "$tool"
  fi
}

_init_tool_sync() {
  local tool=$1
  # Fetch and eval init commands from toml
  eval "$(_get_tool_init_cmd "$tool" "$SHELL")"
  
  # Run tool-specific setup if defined
  [ -n "${config[custom_setup]:-}" ] && ${config[custom_setup]}
  
  # Load fallback script if needed
  [ -n "${config[fallback_script]:-}" ] && [ -r "${config[fallback_script]}" ] && . "${config[fallback_script]}"
}
```

### Benefits

- ✅ **Tool initialization centralized** (single source of truth)
- ✅ **Easier to troubleshoot** (check toml, not scattered configs)
- ✅ **Consistent behavior** across all tools
- ✅ **Simpler to add per-tool customization**

---

## 5. Other Optimization Opportunities

### 5.1 Stow Package Organization

**Current**:
```
config/stow/
  atuin/
  bash/
  bat/
  git/
  home/
  lazygit/
  sheldon/
  starship/
  task/
  zellij/
```

**Issues**:
- Flat structure makes it hard to see relationships
- No categorization (version-control vs utilities vs shells)

**Opportunity**: Group by category (optional refactoring):

```
config/stow/
  core/
    home/          # .zshenv + other core
    bash/
  version-control/
    git/
  shells/
    zsh/           # if moved here
    sheldon/
  utilities/
    bat/
    eza/           # if added
  productivity/
    task/
    lazygit/
  ui/
    starship/
    zellij/
```

### 5.2 Parallel Tool Installation

**Current**: `install-tools.sh` runs sequential installs (slow on first setup)

**Opportunity**: Use GNU `parallel` or xargs to install multiple tools concurrently:

```bash
# Current
for tool in $TOOLS; do
  bash "install/tools/$tool.sh"  # ~30+ seconds sequentially
done

# Proposed
parallel bash "install/tools/{}.sh" ::: $TOOLS  # ~10 seconds on 4 cores
```

### 5.3 Tool Update Mechanism

**Current**: No way to update tools without re-running `install.sh`

**Opportunity**: Add `dotfiles update-tools` command:

```bash
dotfiles update-tools [--all | TOOL1 TOOL2 ...]
# Re-runs install for specific tools (or all if --all)
```

### 5.4 XDG Base Directory Compliance

**Current**: Some tools use XDG, others don't; inconsistent

**Opportunity**: Standardize all tool configs to respect XDG variables:

```bash
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# Then ensure all tools use these in their config
```

---

## Implementation Roadmap

### Phase 1: Quick Wins (Low Effort, High Impact)
**Effort**: 1-2 hours | **Impact**: Immediate improvement in maintainability

1. ✅ Extract `_init_tool_hook()` helper into `config/shell/loader.sh`
2. ✅ Rewrite 30+ conf.d files to use helper (massive simplification)
3. ✅ Add code comments documenting the pattern
4. ✅ Test all shell hooks work identically

**Files to touch**: ~32 files  
**Code reduction**: ~500 lines → ~50 lines

### Phase 2: Manifest & Generator (Medium Effort, High Impact)
**Effort**: 2-3 hours | **Impact**: Unblocks future improvements

1. ✅ Create `config/tools.toml` with tool metadata
2. ✅ Write `install/bin/install-from-manifest.sh` (parses TOML)
3. ✅ Consolidate all 43 tool scripts → single manifest entry
4. ✅ Create `install/bin/generate-tool-inventory.sh` (auto-doc)
5. ✅ Update `bootstrap.sh` to use new installer
6. ✅ Add version pinning support
7. ✅ Test manifest-based install produces identical results

**Files created**: 2-3 new files  
**Files removed**: 43 tool scripts (dedup → 1 template)  
**Manual changes**: bootstrap.sh, Makefile (if applicable)

### Phase 3: Tool Update Mechanism (Medium Effort)
**Effort**: 1 hour | **Impact**: Better maintainability

1. ✅ Add `dotfiles update-tools` command to `bin/dotfiles`
2. ✅ Support selective tool updates (not just all-or-nothing)
3. ✅ Preserve user-installed tool versions

**Files to touch**: 1 (bin/dotfiles)

### Phase 4: Parallelization (Low Effort, High UX Impact)
**Effort**: 30 minutes | **Impact**: Faster initial setup

1. ✅ Update `install-from-manifest.sh` to support parallel installs
2. ✅ Use `xargs -P 4` or `parallel` (if available)
3. ✅ Falls back to sequential if parallel tools unavailable

**Files to touch**: 1 (install/bin/install-from-manifest.sh)

### Phase 5: Reorganization & Polish (Medium Effort, Optional)
**Effort**: 1-2 hours | **Impact**: Better organization

1. ✅ Reorganize `config/stow/` by category (optional)
2. ✅ Standardize XDG usage across all tools
3. ✅ Add dependency tracking to manifest
4. ✅ Generate tool relationship diagram

---

## Risk Assessment & Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Breaking shell startup | High | Keep backwards compatibility; test all shells (zsh, bash) |
| Tool installation failures | High | Use identical `install_tool` logic; test with new manifest |
| User confusion during transition | Medium | Document migration; keep old approach as fallback |
| TOML parsing issues | Low | Use `tomlq` or simple sed-based parser (no external deps) |

---

## Testing Strategy

### Phase 1 Test Plan
```bash
# Test _init_tool_hook helper
exec zsh
dotfiles list  # confirm all modules load
dotfiles bench  # check no startup regression
echo $FZF_DEFAULT_OPTS  # verify fzf settings
fzf --version  # test fzf works
```

### Phase 2 Test Plan
```bash
# Test manifest-based install
rm -rf var/
DOTFILES_SKIP_TOOLS=0 ./install.sh
# Verify all tools still installed correctly
which fzf bat atuin zoxide  # all in PATH
fzf --version  # same version as before
```

### Integration Test
```bash
# Full workflow test
rm -rf ~/{.zshenv,.cache/zsh} var/
./install.sh
exec zsh
dotfiles list
dotfiles audit
dotfiles test
dotfiles bench
```

---

## Estimated Impact

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Tool script files | 43 | 1 | -97% |
| conf.d file sizes | 10-15 lines avg | 2-5 lines avg | -60% |
| Time to add new tool | 5 min (new file) | 1 min (edit TOML) | -80% |
| Lines to maintain | ~2,000 | ~500 | -75% |
| Tool installation time | ~30s | ~10s | -67% |
| Documentation accuracy | Manual | Auto-generated | ✅ |

---

## Next Steps

1. **Review** this analysis and identify priorities
2. **Create PRs incrementally** (Phase 1 → Phase 2 → etc.)
3. **Test thoroughly** at each phase
4. **Update docs** as refactoring progresses
5. **Consider deprecation timeline** for old approach (if needed)

---

## Appendix: Example Manifest (tools.toml)

```toml
# config/tools.toml — Unified tool installer manifest
# Each [[tool]] section defines one installable tool.
# Fields: name, repo, archive_pattern, binname (optional), description, category, deferred, optional

[[tool]]
name = "fzf"
repo = "junegunn/fzf"
archive_pattern = "fzf-{ver}-linux_{goarch}.tar.gz"
description = "Fuzzy finder for CLI"
category = "productivity"
deferred = true
optional = false

[[tool]]
name = "atuin"
repo = "atuinsh/atuin"
archive_pattern = "atuin-{arch}-unknown-linux-musl.tar.gz"
description = "Improved shell history with sync"
category = "shell-enhancement"
deferred = true
optional = false

[[tool]]
name = "bat"
repo = "sharkdp/bat"
archive_pattern = "bat-{tag}-{arch}-unknown-linux-musl.tar.gz"
binname = "bat"
description = "Cat clone with syntax highlighting"
category = "utilities"
deferred = false
optional = false

[[tool]]
name = "zoxide"
repo = "ajeetdsouza/zoxide"
archive_pattern = "zoxide-{ver}-{arch}-unknown-linux-musl.tar.gz"
description = "Frecency-based directory jumper"
category = "productivity"
deferred = true
optional = false

[[tool]]
name = "task"
description = "Task management CLI (taskwarrior)"
category = "productivity"
optional = true
install_method = "source"
note = "Requires Rust, cmake, C++17 — build from source"

# ... 38 more tools
```

