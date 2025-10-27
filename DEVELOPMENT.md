# Locustron Development Guide

## Project Structure

Locustron uses a clear separation between platform-specific and cross-platform code:

```
lib/
├── picotron/              # Picotron-specific implementation
│   ├── locustron.lua      # Main userdata-based implementation
│   └── require.lua        # Picotron module system
└── vanilla/               # Cross-platform implementation
    ├── strategy_interface.lua    # Abstract strategy pattern
    ├── fixed_grid_strategy.lua   # Vanilla Lua Fixed Grid
    ├── doubly_linked_list.lua    # Memory-efficient cell management
    ├── benchmark_suite.lua       # Performance benchmarking
    └── [additional strategies]   # Future implementations
tests/
├── picotron/              # Picotron unitron tests
└── vanilla/               # Cross-platform BDD tests
benchmarks/
├── picotron/              # Picotron performance tests
└── vanilla/               # Cross-platform benchmarks
```

## Development Workflows

### Picotron Development

1. **Main Implementation**: Edit `lib/picotron/locustron.lua`
2. **Testing**: Run `tests/picotron/test_locustron_unit.lua` in unitron
3. **Demo**: Run `include("main.lua")` in Picotron console
4. **Benchmarks**: Run `benchmarks/picotron/run_all_benchmarks.lua`

### Cross-Platform Development

1. **Strategy Development**: Work in `lib/vanilla/`
2. **Testing**: Run `busted tests/vanilla/` from project root
3. **Benchmarking**: Use `lua benchmark.lua` CLI tools

### Package Export

The `export_package.lua` script manages the export workflow:
- Syncs `lib/picotron/` to `exports/` for yotta distribution
- Validates package integrity
- Prepares for BBS publication

## Testing Strategy

- **Picotron Tests** (`tests/picotron/`): Validate userdata implementation
- **Vanilla Tests** (`tests/vanilla/`): Cross-platform BDD tests with Busted
- **Integration**: Both test suites validate identical API behavior

## Contributing

1. Follow the platform separation: Picotron-specific code in `lib/picotron/`, cross-platform in `lib/vanilla/`
2. Maintain API compatibility between implementations
3. Add tests for both platforms when adding features
4. Update documentation for structural changes

## Git Commit Message Enforcement

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for consistent commit messages. To enable automatic validation of your commit messages:

```bash
# After cloning the repository, enable the commit-msg hook:
chmod +x .git/hooks/commit-msg
```

This will enforce the following commit message format:
```
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