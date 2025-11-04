# CRUSH.md - Adminer Development Guide

This document helps agents work effectively with the Adminer codebase.

## Project Overview

Adminer is a full-featured database management tool written in PHP. It's designed as a single-file deployment but consists of multiple source files that are compiled into a single file for distribution.

**Key Characteristics:**
- Database management tool supporting MySQL, MariaDB, PostgreSQL, SQLite, MS SQL, Oracle, and more via plugins
- Single PHP file deployment (after compilation)
- PHP 7.4+ required for source, PHP 5.3+ for compiled version
- Minimalist design philosophy
- Extensive plugin system

## Essential Commands

### Development Setup
```bash
# Initialize git submodules (required after fresh clone)
git submodule update --init

# Compile single-file version
make compile
# or directly:
php compile.php

# Start development server
make server
# Runs on http://127.0.0.1:8000

# Clean compiled files
make clean
```

### Quality Assurance
```bash
# PHP CodeSniffer check
vendor/bin/phpcs --standard=phpcs.xml adminer/

# PHPStan static analysis
vendor/bin/phpstan

# JavaScript linting (requires external dependencies)
# ESLint config in eslint.config.mjs
```

### Docker Development
```bash
# Build and run with Docker Compose
docker-compose up --build

# Access at http://localhost:3000
```

## Code Organization

### Core Structure
- `adminer/` - Main Adminer source code
  - `include/` - Core classes and shared functionality
  - `drivers/` - Database-specific drivers (mysql, pgsql, sqlite, etc.)
  - `lang/` - Translation files (50+ languages)
  - `static/` - CSS, JS, images
  - `*.inc.php` - Page handlers for different operations
- `editor/` - Adminer Editor (data manipulation only)
- `plugins/` - Plugin system and bundled plugins
- `externals/` - Git submodules (JsShrink, PhpShrink, jush)
- `designs/` - CSS themes
- `tests/` - End-to-end tests

### Key Files
- `adminer/index.php` - Main entry point and routing
- `adminer/include/bootstrap.inc.php` - Bootstrap and initialization
- `adminer/include/adminer.inc.php` - Main Adminer class
- `adminer/include/driver.inc.php` - Database driver interface
- `compile.php` - Compilation script

## Coding Standards

### PHP Style
- Follow PSR-12 with custom exceptions (see `phpcs.xml`)
- Use `snake_case` for functions and variables
- Use `camelCase` for method names and parameters in classes
- Always wrap `if/else` blocks in `{}` (removed during minification)
- Use `elseif` not `else if`
- Line length limit: 250 characters
- Tabs for indentation (configured in `.editorconfig`)

### JavaScript Style
- No frameworks - vanilla JS only
- ESLint configuration in `eslint.config.mjs`
- Use `const`/`let`, never `var`
- Event handlers registered immediately after relevant HTML elements
- Functions split between `functions.js` (utilities) and `editing.js` (specific)

### Naming Conventions
- Global functions: `snake_case`
- Class methods: `camelCase`
- Variables: `snake_case`
- Return values: `$return` variable name
- HTML output: always escape with `h()`

## Development Workflow

### Request Lifecycle
1. Bootstrap includes and driver loading
2. Authentication via POST with CSRF tokens
3. URL parameter routing (e.g., `indexes=table_name` loads `indexes.inc.php`)
4. Session stopped before rendering
5. Output with proper escaping

### Compilation Process
- Includes all PHP files into single file
- Minifies PHP code (removes whitespace, comments, shortens variables)
- Inlines CSS/JS files (served via `?file=` route)
- Compresses translations using LZW
- Outputs binary PHP file (not valid UTF-8)

### Translation System
- All user strings must use `lang('String')` function
- Translations updated via `php lang.php`
- Plugins can use `$this->lang()` method
- Plurals handled as arrays with selection logic

## Important Patterns

### Security
- Never use `$_REQUEST` - choose appropriate superglobal
- Always escape output with `h()` (HTMLspecialchars)
- Use `q()` for SQL strings, `idf_escape()` for identifiers
- CSRF tokens for all state-changing operations
- POST actions redirect to GET on success

### Error Handling
- Strict variable initialization
- Relies on undefined array items being empty (not using `isset`)
- Silences E_NOTICE/E_WARNING for this pattern
- Uses `@` operator only for unavoidable errors (file operations)

### Database Abstraction
- Drivers in `adminer/drivers/` implement common interface
- Each driver creates appropriate `Db` class based on available extensions
- URL parameters select driver (e.g., `pgsql=` loads PostgreSQL driver)
- Driver functions ideally belong to `Driver` class but remain separate historically

## Testing

- **No unit tests** - uses extensive end-to-end tests only
- Tests in `tests/*.html` (Katalon Recorder format)
- Takes ~10 minutes to run full test suite
- Tests verify UI functionality and JavaScript behavior
- Run before releases

## Plugins

### Plugin Architecture
- Plugins extend `Adminer` class and override methods
- `Plugins` class calls all plugins until one returns non-null
- Plugin files in `plugins/` directory
- Driver plugins in `plugins/drivers/`

### Creating Plugins
```php
class MyPlugin extends Adminer\Plugin {
    var $translations = array('en' => array('' => 'My Plugin'));
    
    function name() {
        return 'Custom Adminer';
    }
}
```

## Gotchas & Non-obvious Patterns

### Variable Access
- `$table != ""` instead of `!$table` (table names can be "0")
- Array keys accessed directly without `isset()` checks
- Static variables minified to random strings during compilation

### HTML Generation
- Optional closing tags omitted (`</li>`, `</html>`, etc.)
- Minimal HTML structure
- Class names added only when necessary for styling

### Development Notes
- Git submodules used for dependencies (not Composer)
- PHP 5.3 compatibility maintained for compiled version
- Version checks via adminer.org/version/ (can be disabled via plugin)
- Commits should be small and single-purpose
- User-visible changes must be documented in CHANGELOG.md

## Quality Tools Configuration

- **PHP CodeSniffer**: `phpcs.xml` (PSR-12 + custom rules)
- **PHPStan**: `phpstan.neon` (level 6, extensive ignore list)
- **ESLint**: `eslint.config.mjs` (vanilla JS focused)
- **PHP Version**: 7.4+ source, 5.3+ compiled
- **Line Length**: 250 characters (unusually high)

## Build Targets (Makefile)

```bash
make default     # Compile (default target)
make compile     # Create single-file version
make server      # Start PHP dev server on port 8000
make initialize  # Update git submodules
make clean       # Remove compiled files
```

This documentation captures the essential patterns and conventions needed to work effectively with the Adminer codebase. Always refer to `developing.md` for detailed explanations from the original author.