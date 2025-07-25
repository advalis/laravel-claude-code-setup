# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **Laravel Claude Code Setup** project - a tool that automates the configuration of Claude Code with MCP servers for Laravel development. It provides one-command setup for AI-powered Laravel development with quality control through automated hooks.

## Commands

### Installation and Setup
```bash
# Install the setup tool in a Laravel project
curl -fsSL https://raw.githubusercontent.com/advalis/laravel-claude-code-setup/main/install.sh | bash

# Run tests after changes
./test-setup.sh

# Uninstall the setup from a Laravel project
./uninstall.sh
```

### Development Commands
When working on the setup scripts themselves:
```bash
# Test the installation process
./test-setup.sh

# Check hook functionality
./hooks/lint.sh
./hooks/test.sh
```

## Architecture

This project provides automated setup scripts for Laravel projects to work with Claude Code. The key components are:

### Core Scripts
- **install.sh**: Main installer that downloads and runs the setup script
- **scripts/setup-claude-code-laravel.sh**: The actual setup logic that configures MCP servers and creates project files
- **test-setup.sh**: Tests the installation in a temporary directory
- **uninstall.sh**: Removes the setup from a Laravel project

### Templates
All content files are maintained as templates in the `templates/` directory:
- **CLAUDE.md.template**: Laravel development guidelines for Claude Code
- **commands/*.md.template**: Custom slash commands for Laravel development workflow

### Hooks
Quality control hooks that run automatically in Laravel projects:
- **hooks/lint.sh**: Runs Laravel linting (Rector, Pint, PHPStan)
- **hooks/test.sh**: Runs Pest tests and checks for missing test files

### What Gets Installed

The setup script configures:

1. **Global MCP Servers** (shared across projects):
   - GitHub integration (with token configuration)
   - Memory system
   - Context7 (Laravel/PHP documentation)
   - Web fetch

2. **Project-Specific MCP Servers**:
   - Filesystem access
   - Database integration (based on Laravel .env)

3. **Project Files** (in `.claude/`):
   - Custom instructions and context
   - Development shortcuts
   - Hook configurations
   - Custom commands

## Key Implementation Details

- All content is maintained in template files for easier updates
- The installer detects existing configurations and updates intelligently
- Hooks use exit code 2 to ensure Claude Code sees their output
- Interactive prompts work correctly even when piped through curl
- Database configuration is extracted from Laravel's .env file
- The setup supports MySQL, PostgreSQL, and SQLite databases