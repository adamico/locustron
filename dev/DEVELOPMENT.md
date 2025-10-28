# Locustron Development Guide

## Development Environment Setup

### Prerequisites

For development and testing, you'll need to set up a Lua development environment:

1. **Install Lua 5.4+** (required for development and testing)
2. **Install LuaRocks** (Lua package manager)
3. **Install Busted** (BDD testing framework)
4. **Install Yotta** (Picotron package manager)

```bash
# Install LuaRocks (varies by system)
# Ubuntu/Debian:
sudo apt-get install luarocks

# macOS (with Homebrew):
brew install luarocks

# Install Busted for BDD testing
luarocks install busted

# Verify installation
busted --version
lua -v
```

### Picotron Package Management

For Picotron development and testing, you'll need yotta (Picotron's package manager):

#### Installing Yotta

**Initial Installation:**

```bash
# In Picotron terminal:
load #yotta -u
# Ctrl+R to run installer cartridge
# Press X to install
```

**Upgrading from v1.0:**

```bash
# In Picotron terminal:
yotta util install #yotta
yotta version  # Should show "yotta version v1.1"
```

**Note:** Use `load #yotta -u` (with `-u` flag) to avoid sandboxing issues that prevent installation.

#### Using Yotta with Locustron

Once yotta is installed, you can install locustron as a package for testing:

```bash
# Install locustron from BBS as a dependency
yotta add #locustron
yotta apply

# This will install locustron to lib/locustron/ for local testing
# Note: lib/ folder is excluded from git as it contains installed packages
```

#### Yotta Commands Reference

```bash
# Dependency management (for your cartridge projects)
yotta init              # Initialize yottafile for current directory
yotta add #cart_id      # Add BBS cartridge as dependency
yotta add /path/file    # Add local cartridge as dependency
yotta apply             # Install all dependencies to lib/ folder
yotta remove #cart_id   # Remove dependency
yotta list              # List current dependencies

# Package management (global system utilities)
yotta util install #cart_id     # Install system package globally
yotta util uninstall #cart_id   # Uninstall system package
yotta util list                 # List installed packages
yotta util update #cart_id      # Update system package
```

### Running Tests

```bash
# Run cross-platform BDD tests
busted tests/

# Run specific test file
busted tests/setup_spec.lua

# Run with verbose output
busted --verbose tests/
```

## Project Structure

Locustron follows a unified architecture with modular components:

``` markdown
src/
├── locustron.lua              # Main library entry point
├── require.lua                 # Custom module system
├── integration/                # Game engine integration utilities
│   └── viewport_culling.lua    # Viewport culling implementation
└── strategies/                 # Spatial partitioning strategies
    ├── doubly_linked_list.lua  # Memory management utility
    ├── fixed_grid.lua          # Fixed Grid strategy
    ├── init.lua                # Strategy registration
    └── interface.lua           # Strategy interface contract
demo/
├── demo_scenarios.lua          # Demo scenario definitions
├── debugging/                  # Debug utilities and visualization
│   ├── debug_console.lua       # Interactive debugging console
│   ├── performance_profiler.lua # Performance analysis tools
│   └── visualization_system.lua # Spatial partitioning visualization
└── scenarios/                  # Individual demo scenario implementations
    ├── survivor_like.lua       # Survivor-like game scenario
    ├── space_battle.lua        # Space battle scenario
    ├── platformer.lua          # Platformer level scenario
    └── dynamic_ecosystem.lua   # Dynamic ecosystem scenario
lib/                            # Yotta package installations (excluded from git)
exports/                        # Build artifacts (excluded from git)
tests/                          # BDD test suite
benchmarks/                     # Performance benchmarking tools
```

## Development Workflows

### Core Development

1. **Main Implementation**: Edit `src/locustron.lua` and related files
2. **Strategy Development**: Work in `src/strategies/` for new spatial partitioning algorithms
3. **Integration**: Add utilities in `src/integration/` for game engine integration
4. **Testing**: Run `busted tests/` from project root
5. **Demo**: Run the demo locustron.p64 cartridge in Picotron
6. **Benchmarking**: Use `lua benchmark.lua` CLI tools

### Package Export

The `export_package.lua` script manages the export workflow:

- **Directory setup**: Automatically creates `lib/locustron/` and `exports/` directories if they don't exist
- **Build artifacts**: Both `lib/` and `exports/` folders contain generated files and are excluded from git
- **File sync**: Copies source files to both `lib/locustron/` (for local yotta simulation) and `exports/` (for BBS distribution)
- **Validation**: Verifies package integrity and file presence
- **BBS preparation**: Prepares cartridge for publication with proper metadata

**Publishing Methods:**

1. **GitHub Repository**: Contains the complete source code in `src/` with development files
2. **Lexaloffle BBS**: Contains the exported `locustron.p64.png` cartridge as a yotta package (generated from `exports/` folder)

**Package Management:**

- **lib/**: Managed by yotta package manager (install packages here with `yotta add`)
- **exports/**: Generated by export script for BBS publication

## Testing Strategy

- **BDD Tests** (`tests/`): Comprehensive behavior-driven tests with Busted
- **Integration**: Tests validate API behavior and spatial partitioning correctness
- **Coverage**: Tests cover strategy implementations, utilities, and integration patterns

## Contributing

1. **Code Organization**: Keep related functionality together in appropriate directories
2. **Strategy Pattern**: Implement new spatial partitioning algorithms in `src/strategies/`
3. **Integration**: Add game engine integration utilities in `src/integration/`
4. **Testing**: Add comprehensive tests for new features in `tests/`
5. **Documentation**: Update documentation for structural changes
6. **Performance**: Include benchmarks for performance-critical changes

## Git Commit Message Enforcement

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for consistent commit messages. To enable automatic validation of your commit messages:

```bash
# After cloning the repository, enable the commit-msg hook:
chmod +x .git/hooks/commit-msg
```

This will enforce the following commit message format:

``` bash
<type>[optional scope]: <description>
```

**Valid commit types:**

- `feat` - A new feature
- `fix` - A bug fix  
- `docs` - Documentation changes
- `test` - Adding or updating tests
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `chore` - Build process or auxiliary tool changes

**Examples:**

```bash
git commit -m "feat(locustron): add spatial hash optimization"
git commit -m "fix(tests): handle unknown object error in delete tests"  
git commit -m "docs: update README with setup instructions"
```

If your commit message doesn't follow this format, the commit will be rejected with helpful guidance.
