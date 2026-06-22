# Post-Refactoring Optimization Opportunities

**Date**: 2026-06-22  
**Current Status**: Phase 1-5 complete (tool manifest + hooks)  
**Next Frontier**: Runtime performance, startup analysis, tool health, configuration validation

---

## A. Runtime Performance & Startup Analysis

### 1. **Enhanced Startup Profiler** (Medium Effort)
**Problem**: `dotfiles bench` only shows total time, not where time is spent  
**Current**: `cmd_bench` measures full zsh startup  
**Improvement**: Break down startup by module/phase

```bash
# dotfiles profile --detailed [--sort time|module]
# Output:
#   Module                 Time    % of total
#   00-options.zsh         1.2ms   2%
#   02-zmodload.zsh        0.8ms   1%
#   20-completion.zsh      8.5ms   15%  ← Slow
#   90-defer.zsh           0.3ms   1%
#   95-plugins.zsh         2.1ms   4%
#   conf.d/*.sh            5.2ms   9%
#   ...
```

**Implementation**:
- Wrap each module load with timing
- Report per-module startup cost
- Identify slowest modules
- Cache results to avoid slowdown

### 2. **Startup Bottleneck Detector** (Medium Effort)
```bash
# dotfiles profile --analyze
# Identifies:
# - Slow completion dump regeneration
# - Missing cached files
# - Tool init() calls that fork subshells
# - Unnecessary re-evaluations
```

**Benefits**:
- Spot opportunities for parallelization
- Identify modules to defer
- Find expensive tool hooks

---

## B. Tool Health & Validation (Post-Install)

### 3. **Tool Health Check** (`dotfiles doctor-tools`) (Medium Effort)
**Problem**: No way to verify tool installation integrity after install  

**Checks**:
```bash
Tool Health Report
─────────────────
fzf
  ✓ Binary exists: /var/tools/bin/fzf
  ✓ Version: 0.54.0 (manifest: 0.54.0)
  ✓ Hook loaded: conf.d/30-fzf.sh
  ✓ Cache valid: $HOME/.cache/dotfiles/init/fzf.zsh (fresh)

bat
  ⚠ Version mismatch: installed 0.23.0, manifest expects 0.24.0 (outdated)
  ✓ Binary works: `bat --version` OK
  ✓ Hook loaded

atuin
  ✘ Binary NOT found in PATH
  ✘ conf.d hook failed to initialize
  ⚠ Suggestions: Run `dotfiles update-tools atuin`

Missing from manifest:
  - fzf-tab (manual plugin, not in manifest)
```

**Implementation**:
```bash
cmd_doctor_tools() {
  # For each tool in manifest:
  # 1. Check binary exists
  # 2. Compare versions (install-time vs runtime)
  # 3. Verify hook initialization
  # 4. Check cache validity
  # 5. Suggest fixes
}
```

### 4. **Configuration Integrity Check** (Easy)
```bash
# dotfiles check-config
# Verify:
# - All profile files readable
# - No broken symlinks in stow packages
# - DOTFILES_DIR accessible
# - Required core modules present
# - No duplicate aliases (warn)
```

### 5. **Tool Dependency Tracker** (Hard)
**Problem**: No way to know if removing a tool breaks others  
**Example**: `broot` is optional, but if removed, nothing breaks  

```toml
# In config/tools.toml - add optional depends field
[[tool]]
name = "fzf"
depends = []

[[tool]]
name = "lazygit"
description = "git UI"
optional = true

[[tool]]
name = "fzf-tab"
depends = ["fzf", "zsh"]  # Requires both
install_method = "plugin"  # Not in manifest, installed via sheldon
```

**Implementation**:
```bash
# dotfiles check-deps [--fix]
# Report dependency tree
# Suggest removals safely
```

---

## C. Version Tracking & Management

### 6. **Version Pinning & Lock File** (Medium Effort)
**Problem**: Tools auto-update to latest, may break things  

**New**: `config/tools.lock` (generated after install)
```toml
# Auto-generated after install, tracks exact installed versions
[tool.fzf]
version = "0.54.0"
repo = "junegunn/fzf"
installed_at = "2026-06-22T14:30:00Z"
checksum = "sha256:abc123..."  # For reproducibility

[tool.bat]
version = "0.23.0"
installed_at = "2026-06-21T10:15:00Z"
```

**Usage**:
```bash
# Install with version pinning
DOTFILES_LOCK_FILE=config/tools.lock ./install.sh

# Auto-generate lock file after install
dotfiles lock-tools  # Creates config/tools.lock

# Verify installed tools match lock
dotfiles verify-lock
```

### 7. **Tool Update Strategy** (Medium Effort)
```bash
# Current: dotfiles update-tools [--all]
# Enhanced:

# Show available updates
dotfiles update-tools --check
# Output:
#   fzf         0.54.0 → 0.55.0 (available)
#   bat         0.23.0 (current)
#   atuin       0.17.0 → 0.18.0 (available)

# Update with rollback capability
dotfiles update-tools --dry-run fzf bat
# Pre-test before applying

dotfiles update-tools --roll-back
# Restore from previous version

# Auto-update in background
dotfiles update-tools --schedule daily
```

---

## D. Shell Session Optimization

### 8. **Lazy Loading Functions** (Medium Effort)
**Problem**: All functions loaded even if rarely used  

**Current**: `config/shell/functions/` autoloaded at startup  
**Improvement**: Lazy load on first call

```bash
# config/shell/zsh/45-functions.zsh
# Current: autoload all functions immediately
# New: Load only on demand

# Faster startup:
# - Define stub for expensive functions
# - Load real implementation on first call
# - Cache for subsequent calls

# Example:
autoload -U add-zsh-hook
add-zsh-hook precmd _lazy_load_functions

_lazy_load_functions() {
  # Load functions on first prompt
  # Remove this hook after first load
}
```

### 9. **Module Enable/Disable Cache** (Easy)
**Problem**: `dotfiles disable` requires parsing disabled file each shell  

**Improvement**: Cache disabled modules
```bash
# config/zsh/.zsh_modules_cache (generated)
# Contains: DOTFILES_DISABLE="company foo bar"
# Updated only when `dotfiles disable/enable` runs
```

### 10. **Session State Tracking** (Medium Effort)
**Problem**: Can't tell which tools/modules have been initialized  

**Improvement**: Maintain session state
```bash
# Runtime tracking
declare -gA DOTFILES_LOADED  # Track loaded modules
declare -gA DOTFILES_TOOLS   # Track initialized tools

_init_tool_hook() {
  # ... existing code ...
  DOTFILES_TOOLS[$tool]="loaded"
}

# Usage:
dotfiles list-loaded      # Show what's been initialized
dotfiles reload-module fzf  # Hot-reload specific module
```

---

## E. Configuration & Error Handling

### 11. **Configuration Validation** (Easy)
```bash
# On shell startup: validate config

# Check:
# - All referenced tools in PATH (warn if not)
# - Stow symlinks valid
# - Profile files readable
# - No circular dependencies
# - No conflicting aliases

# Non-fatal warnings only (don't break shell)
```

### 12. **Better Error Messages** (Easy)
**Current**: Silent failures if tool hook fails  
**Improvement**: Helpful error reporting

```bash
_init_tool_hook() {
  # ... 
  if ! output=$(eval "$init_cmd" 2>&1); then
    warn "Tool '$tool' failed to initialize: $output"
    warn "Suggestion: dotfiles doctor-tools | grep $tool"
    return 1
  fi
  # ...
}
```

### 13. **Alias Conflict Detection** (Easy)
```bash
# dotfiles check-aliases
# Warn if alias is redefined multiple times
# Suggest which file defines it

# Example output:
#   alias grep redefined 5 times:
#   1. core/20-aliases.sh (grep --color=auto)
#   2. conf.d/rg.sh      (rg --smart-case) ← Wins
#   3. profile/aliases.sh (grep -n)  ← Shadowed
```

---

## F. Advanced Startup Features

### 14. **Shell Event Hooks** (Hard)
**Problem**: No way to run code at specific shell lifecycle points  

```bash
# New hook system:

# Pre-prompt hook (after all modules loaded, before first prompt)
add-dotfiles-hook pre-prompt "some-command"

# Post-command hook (after each command)
add-dotfiles-hook post-command "some-command"

# Module loaded hook (when a module loads)
add-dotfiles-hook module-loaded:fzf "initialize-fzf-extras"
```

### 15. **Interactive Mode Detection & Optimization** (Medium Effort)
```bash
# Profile different shell modes:
dotfiles bench --modes all
# Output:
#   Login shell:        245ms
#   Interactive:        180ms
#   Script execution:   50ms
#   SSH forwarding:     15ms

# Optimize each mode separately
```

### 16. **Completion Cache Optimization** (Easy)
```bash
# dotfiles clean-caches
# Remove:
# - Stale zcompdump files (> 30 days)
# - Old tool init caches
# - Unused completion functions
```

---

## G. Tool Management Enhancements

### 17. **Background Tool Auto-Update** (Hard)
```bash
# Run in background without blocking shell
dotfiles update-tools --schedule hourly --background

# Check for updates, notify user
# Download in background
# Verify before applying
# Swap atomically (no downtime)
```

### 18. **Tool Removal with Cleanup** (Medium Effort)
```bash
# dotfiles remove-tool fzf [--cleanup]
# 
# Checks:
# - Is fzf depended on by anything?
# - Remove from tools.toml
# - Remove cached init
# - Remove symlinks if applicable
# - Confirm cleanup

# Safe removal (warns before breaking things)
```

### 19. **Tool Compatibility Matrix** (Hard)
```bash
# tools.compat
# Define which tool versions are compatible with this OS

[[tool.fzf.compat]]
min_version = "0.40.0"
max_version = "latest"
platforms = ["linux", "macos"]
note = "v0.39 has a bug with --multi flag"
```

---

## H. Documentation & Discovery

### 20. **Auto-Generated Module Reference** (Medium Effort)
```bash
# dotfiles doc modules [--format markdown|html]
# 
# Generate documentation for:
# - Each module (purpose, load order, options)
# - Each tool (description, category, config)
# - Load order diagram
# - Dependency graph
# - Configuration flow chart
```

### 21. **Interactive Shell Setup Wizard** (Hard)
```bash
# dotfiles init-interactive
# 
# Walks through:
# - Select tools to install
# - Configure profiles
# - Set up work machine links
# - Run first-time health check
```

---

## I. Testing & Validation

### 22. **Configuration Smoke Tests** (Medium Effort)
```bash
# dotfiles test --extended
# 
# Run comprehensive tests:
# - All modules parse correctly
# - No syntax errors in tools.toml
# - All symlinks valid
# - Tools in PATH work
# - Completion dump valid
# - Shell startup completes
```

### 23. **Performance Regression Testing** (Hard)
```bash
# Track startup time across commits
# Warning if startup degrades > 10%

dotfiles bench --baseline
# Creates benchmark/baseline.txt

# On each install/reload:
# dotfiles bench --compare
# Fails if > 10% slower than baseline
```

---

## Prioritized Implementation Roadmap

### Quick Wins (1-2 hours each)
1. ✨ Alias conflict detection
2. ✨ Configuration validation
3. ✨ Better error messages for tool hooks
4. ✨ Module disable cache
5. ✨ Completion cache cleanup

### Medium Effort (2-4 hours each)
6. 📊 Enhanced startup profiler
7. 🏥 Tool health check
8. 🔒 Version pinning & lock file
9. 🔄 Tool update strategy enhancements
10. 📈 Session state tracking
11. 🎯 Startup bottleneck detector
12. 📋 Auto-generated module reference

### High Effort (4+ hours each)
13. 🎣 Shell event hooks system
14. 🚀 Background auto-update
15. 🧪 Performance regression testing
16. 🪄 Interactive setup wizard
17. 🔗 Tool dependency tracker

---

## Which Should We Tackle First?

**Recommended Phase 6 (Quick Impact)**:
1. **Enhanced startup profiler** — understand where time goes
2. **Tool health check** — validate installations
3. **Alias conflict detection** — catch errors early
4. **Better error messages** — improve debugging
5. **Module disable cache** — squeeze out ms from startup

**These give immediate value with modest implementation time.**

---

## Architecture Notes

### `config/tools.lock` (New)
Auto-generated after install, tracks exact versions installed

### `config/tools-manifest` (Extended)
Add optional fields:
- `depends: []` — dependencies
- `categories: []` — discovery
- `notes: ""`— compatibility info
- `min_version`, `max_version` — ranges

### New Commands
```
dotfiles doctor-tools          # Tool health
dotfiles profile --detailed    # Startup breakdown  
dotfiles verify-lock          # Version check
dotfiles check-config         # Comprehensive validation
dotfiles list-loaded          # Session state
dotfiles check-aliases        # Conflict detection
dotfiles clean-caches         # Cache management
```

### New Runtime Features
```
DOTFILES_LOADED[]             # Track what's initialized
_lazy_load_functions()        # Defer expensive stuff
add-dotfiles-hook             # Event system
_session_state_init()         # Initialize tracking
```

---

## Estimated Total Impact

| Phase | Impact | Startup | Build Time |
|-------|--------|---------|------------|
| Current | Baseline | 180ms | ~30s |
| +Profiler | Insights | - | - |
| +Lazy loading | 10-15% faster | 153ms | - |
| +Caching | 5-10% faster | 160ms | - |
| +Event hooks | Framework | - | - |
| **Total** | **Full insights + perf** | **~150ms** | **~25s** |

---

## Next Steps

1. **Profile current startup** (`dotfiles bench --detailed`)
2. **Identify slowest modules**
3. **Implement quick wins** (5 items above)
4. **Measure improvement**
5. **Plan Phase 6** based on findings

Would you like me to implement any of these optimizations?

