#!/bin/bash

# Multi-Project Laravel Claude Code Setup Script
# Configures Claude Code for projects with separate API and frontend directories
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script arguments
LARAVEL_DIR="${1:-api}"
FRONTEND_DIR="${2:-webapp}"

# Validate directories exist
if [ ! -d "$LARAVEL_DIR" ] || [ ! -f "$LARAVEL_DIR/artisan" ]; then
    print_error "Laravel directory '$LARAVEL_DIR' not found or invalid!"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ] || [ ! -f "$FRONTEND_DIR/package.json" ]; then
    print_error "Frontend directory '$FRONTEND_DIR' not found or invalid!"
    exit 1
fi

# Get absolute paths
LARAVEL_PATH=$(cd "$LARAVEL_DIR" && pwd)
FRONTEND_PATH=$(cd "$FRONTEND_DIR" && pwd)
PROJECT_ROOT=$(pwd)

print_success "Setting up multi-project Claude Code configuration"
echo "  Laravel API: $LARAVEL_PATH"
echo "  Frontend: $FRONTEND_PATH"
echo ""

# Better interactive detection
can_interact_with_user() {
    if [ -t 1 ] && [ -t 2 ]; then
        if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ] && [ -z "$JENKINS_URL" ]; then
            if [ -e /dev/tty ]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Helper function to read input from controlling terminal
read_from_user() {
    local prompt="$1"
    local variable_name="$2"
    
    if can_interact_with_user; then
        printf "%s" "$prompt" > /dev/tty
        read -r "$variable_name" < /dev/tty
        return 0
    else
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    command -v claude >/dev/null 2>&1 || missing_deps+=("Claude Code CLI (claude)")
    command -v node >/dev/null 2>&1 || missing_deps+=("Node.js")
    command -v npm >/dev/null 2>&1 || missing_deps+=("npm")
    command -v go >/dev/null 2>&1 || missing_deps+=("Go 1.22+")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Create .claude directory structure
create_claude_directory() {
    print_status "Creating .claude directory structure..."
    
    mkdir -p .claude/{hooks,commands}
    
    print_success ".claude directory created!"
}

# Setup global MCP servers (if not already configured)
setup_global_mcp_servers() {
    print_status "Setting up global MCP servers..."
    
    # Check if Claude config exists
    if [ ! -f "$HOME/.claude.json" ]; then
        echo "{}" > "$HOME/.claude.json"
    fi
    
    # Install global MCP servers (similar to original script)
    # This is a simplified version - you'd copy the logic from the original
    print_status "Installing global MCP servers..."
    
    # GitHub MCP
    if ! npm list -g @modelcontextprotocol/server-github >/dev/null 2>&1; then
        print_status "Installing GitHub MCP server..."
        npm install -g @modelcontextprotocol/server-github
    fi
    
    # Memory MCP
    if ! npm list -g @modelcontextprotocol/server-memory >/dev/null 2>&1; then
        print_status "Installing Memory MCP server..."
        npm install -g @modelcontextprotocol/server-memory
    fi
    
    print_success "Global MCP servers configured!"
}

# Configure project-specific MCP servers
configure_project_mcp() {
    print_status "Configuring project-specific MCP servers..."
    
    # Create local Claude configuration
    cat > .claude/claude_desktop_config.json << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${PROJECT_ROOT}"
      ]
    },
    "database": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-server-mysql-npx",
        "${LARAVEL_PATH}/.env"
      ]
    }
  }
}
EOF
    
    print_success "Project MCP servers configured!"
}

# Create multi-project hooks
create_multi_project_hooks() {
    print_status "Creating multi-project hooks..."
    
    # Create lint hook that handles both Laravel and Vue
    cat > .claude/hooks/lint.sh << 'EOF'
#!/usr/bin/env bash
# Multi-Project Lint Hook
# Runs linting for both Laravel and frontend code

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the project root and subdirectories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LARAVEL_DIR=""
FRONTEND_DIR=""

# Find Laravel directory
for dir in api backend laravel-api server; do
    if [ -d "$PROJECT_ROOT/$dir" ] && [ -f "$PROJECT_ROOT/$dir/artisan" ]; then
        LARAVEL_DIR="$PROJECT_ROOT/$dir"
        break
    fi
done

# Find frontend directory
for dir in webapp frontend client vue-app web app; do
    if [ -d "$PROJECT_ROOT/$dir" ] && [ -f "$PROJECT_ROOT/$dir/package.json" ]; then
        FRONTEND_DIR="$PROJECT_ROOT/$dir"
        break
    fi
done

# Error tracking
declare -a CLAUDE_HOOKS_SUMMARY=()
declare -i CLAUDE_HOOKS_ERROR_COUNT=0

add_error() {
    local message="$1"
    CLAUDE_HOOKS_ERROR_COUNT+=1
    CLAUDE_HOOKS_SUMMARY+=("${RED}❌${NC} $message")
}

# Check if edited file is in Laravel or frontend
FILE_PATH=""
if [ ! -t 0 ]; then
    INPUT=$(cat)
    if echo "$INPUT" | jq . >/dev/null 2>&1; then
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
        TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
        
        if [[ "$TOOL_NAME" =~ ^(Edit|Write|MultiEdit)$ ]]; then
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        fi
    fi
fi

# Determine which linter to run based on file path
run_laravel_lint=false
run_frontend_lint=false

if [[ -z "$FILE_PATH" ]]; then
    # No specific file, run both
    run_laravel_lint=true
    run_frontend_lint=true
elif [[ "$FILE_PATH" == *"$LARAVEL_DIR"* ]]; then
    run_laravel_lint=true
elif [[ "$FILE_PATH" == *"$FRONTEND_DIR"* ]]; then
    run_frontend_lint=true
fi

# Run Laravel linting
if [[ "$run_laravel_lint" == true ]] && [[ -n "$LARAVEL_DIR" ]]; then
    echo -e "\n${BLUE}🔍 Laravel Code Quality Check${NC}" >&2
    echo "──────────────────────────────────" >&2
    
    cd "$LARAVEL_DIR"
    
    # Run composer refactor
    if command -v composer >/dev/null 2>&1; then
        if composer run-script --list | grep -q "refactor:rector"; then
            echo -e "\n${BLUE}Running Laravel refactoring...${NC}" >&2
            if ! composer refactor:rector 2>&1; then
                add_error "Laravel refactoring failed (composer refactor:rector)"
            fi
        fi
        
        if composer run-script --list | grep -q "refactor:lint"; then
            echo -e "\n${BLUE}Running Laravel formatting...${NC}" >&2
            if ! composer refactor:lint 2>&1; then
                add_error "Laravel formatting failed (composer refactor:lint)"
            fi
        fi
        
        if composer run-script --list | grep -q "test:types"; then
            echo -e "\n${BLUE}Running Laravel static analysis...${NC}" >&2
            if ! composer test:types 2>&1; then
                add_error "Laravel static analysis failed (composer test:types)"
            fi
        fi
    fi
    
    cd "$PROJECT_ROOT"
fi

# Run frontend linting
if [[ "$run_frontend_lint" == true ]] && [[ -n "$FRONTEND_DIR" ]]; then
    echo -e "\n${BLUE}🔍 Frontend Code Quality Check${NC}" >&2
    echo "──────────────────────────────────" >&2
    
    cd "$FRONTEND_DIR"
    
    # Check for npm/yarn scripts
    if [ -f "package.json" ]; then
        # Try npm first
        if command -v npm >/dev/null 2>&1; then
            if npm run | grep -q "lint"; then
                echo -e "\n${BLUE}Running frontend linting...${NC}" >&2
                if ! npm run lint 2>&1; then
                    add_error "Frontend linting failed (npm run lint)"
                fi
            fi
            
            if npm run | grep -q "format"; then
                echo -e "\n${BLUE}Running frontend formatting...${NC}" >&2
                if ! npm run format 2>&1; then
                    add_error "Frontend formatting failed (npm run format)"
                fi
            fi
        fi
    fi
    
    cd "$PROJECT_ROOT"
fi

# Print summary
if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
    echo -e "\n${RED}═══ Issues Found ═══${NC}" >&2
    for item in "${CLAUDE_HOOKS_SUMMARY[@]}"; do
        echo -e "$item" >&2
    done
    echo -e "\n${RED}Found $CLAUDE_HOOKS_ERROR_COUNT issue(s) that MUST be fixed!${NC}" >&2
    echo -e "${RED}❌ Fix ALL issues above before continuing!${NC}" >&2
    echo -e "\n${RED}🛑 FAILED - Fix all issues above! 🛑${NC}" >&2
    exit 2
else
    echo -e "\n${YELLOW}👉 Style clean. Continue with your task.${NC}" >&2
    exit 2
fi
EOF
    
    # Create test hook for multi-project
    cat > .claude/hooks/test.sh << 'EOF'
#!/usr/bin/env bash
# Multi-Project Test Hook
# Runs tests for both Laravel and frontend code

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the project root and subdirectories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LARAVEL_DIR=""
FRONTEND_DIR=""

# Find Laravel directory
for dir in api backend laravel-api server; do
    if [ -d "$PROJECT_ROOT/$dir" ] && [ -f "$PROJECT_ROOT/$dir/artisan" ]; then
        LARAVEL_DIR="$PROJECT_ROOT/$dir"
        break
    fi
done

# Find frontend directory
for dir in webapp frontend client vue-app web app; do
    if [ -d "$PROJECT_ROOT/$dir" ] && [ -f "$PROJECT_ROOT/$dir/package.json" ]; then
        FRONTEND_DIR="$PROJECT_ROOT/$dir"
        break
    fi
done

# Error tracking
declare -a CLAUDE_HOOKS_SUMMARY=()
declare -i CLAUDE_HOOKS_ERROR_COUNT=0

add_error() {
    local message="$1"
    CLAUDE_HOOKS_ERROR_COUNT+=1
    CLAUDE_HOOKS_SUMMARY+=("${RED}❌${NC} $message")
}

# Check if edited file is in Laravel or frontend
FILE_PATH=""
if [ ! -t 0 ]; then
    INPUT=$(cat)
    if echo "$INPUT" | jq . >/dev/null 2>&1; then
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
        TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
        
        if [[ "$TOOL_NAME" =~ ^(Edit|Write|MultiEdit)$ ]]; then
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        fi
    fi
fi

# Determine which tests to run
run_laravel_tests=false
run_frontend_tests=false

if [[ -z "$FILE_PATH" ]]; then
    run_laravel_tests=true
    run_frontend_tests=true
elif [[ "$FILE_PATH" == *"$LARAVEL_DIR"* ]]; then
    run_laravel_tests=true
elif [[ "$FILE_PATH" == *"$FRONTEND_DIR"* ]]; then
    run_frontend_tests=true
fi

# Run Laravel tests
if [[ "$run_laravel_tests" == true ]] && [[ -n "$LARAVEL_DIR" ]]; then
    echo -e "\n${BLUE}🧪 Laravel Test Suite${NC}" >&2
    echo "────────────────────────" >&2
    
    cd "$LARAVEL_DIR"
    
    if composer run-script --list | grep -q "test:pest"; then
        echo -e "\n${BLUE}Running Laravel tests...${NC}" >&2
        if ! composer test:pest 2>&1; then
            add_error "Laravel tests failed"
        fi
    elif [ -f "vendor/bin/pest" ]; then
        echo -e "\n${BLUE}Running Laravel tests...${NC}" >&2
        if ! ./vendor/bin/pest 2>&1; then
            add_error "Laravel tests failed"
        fi
    fi
    
    cd "$PROJECT_ROOT"
fi

# Run frontend tests
if [[ "$run_frontend_tests" == true ]] && [[ -n "$FRONTEND_DIR" ]]; then
    echo -e "\n${BLUE}🧪 Frontend Test Suite${NC}" >&2
    echo "────────────────────────" >&2
    
    cd "$FRONTEND_DIR"
    
    if [ -f "package.json" ]; then
        if npm run | grep -q "test"; then
            echo -e "\n${BLUE}Running frontend tests...${NC}" >&2
            if ! npm run test 2>&1; then
                add_error "Frontend tests failed"
            fi
        fi
    fi
    
    cd "$PROJECT_ROOT"
fi

# Print summary and exit
if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
    echo -e "\n${RED}═══ Issues Found ═══${NC}" >&2
    for item in "${CLAUDE_HOOKS_SUMMARY[@]}"; do
        echo -e "$item" >&2
    done
    echo -e "\n${RED}Found $CLAUDE_HOOKS_ERROR_COUNT issue(s) that MUST be fixed!${NC}" >&2
    echo -e "${RED}❌ Fix ALL issues above before continuing!${NC}" >&2
    echo -e "\n${RED}🛑 FAILED - Fix all issues above! 🛑${NC}" >&2
    exit 2
else
    echo -e "\n${YELLOW}👉 Tests pass. Continue with your task.${NC}" >&2
    exit 2
fi
EOF
    
    chmod +x .claude/hooks/*.sh
    
    print_success "Multi-project hooks created!"
}

# Create Claude settings for hooks
create_claude_settings() {
    print_status "Creating Claude settings..."
    
    cat > .claude/settings.local.json << EOF
{
  "hooks": {
    "pre-write": ".claude/hooks/lint.sh",
    "post-edit": ".claude/hooks/lint.sh",
    "post-write": ".claude/hooks/test.sh"
  }
}
EOF
    
    print_success "Claude settings created!"
}

# Create multi-project CLAUDE.md
create_claude_md() {
    print_status "Creating multi-project CLAUDE.md..."
    
    # Get Laravel database config
    DB_CONNECTION=$(grep "^DB_CONNECTION=" "$LARAVEL_PATH/.env" | cut -d'=' -f2 | tr -d '"' || echo "mysql")
    
    cat > .claude/CLAUDE.md << EOF
# Multi-Project Development Partnership

This is a multi-project repository containing:
- **Laravel API**: ${LARAVEL_DIR}/
- **Frontend**: ${FRONTEND_DIR}/

## Project Structure

\`\`\`
$(basename "$PROJECT_ROOT")/
├── ${LARAVEL_DIR}/           # Laravel API (PHP/Laravel)
│   ├── app/           # Application logic
│   ├── routes/        # API routes
│   ├── database/      # Migrations, seeders
│   └── tests/         # Pest tests
└── ${FRONTEND_DIR}/         # Frontend (Vue.js)
    ├── src/           # Vue components
    ├── composables/   # Vue composables
    └── tests/         # Frontend tests
\`\`\`

## Commands

### Laravel API (run from ${LARAVEL_DIR}/)
\`\`\`bash
cd ${LARAVEL_DIR}

# Development
php artisan serve              # Start development server
php artisan migrate            # Run migrations
php artisan db:seed           # Seed database

# Quality checks
composer refactor:rector      # Run Rector refactoring
composer refactor:lint        # Run Pint formatting
composer test:types          # Run PHPStan analysis
composer test:pest           # Run Pest tests

# Common artisan commands
php artisan make:model ModelName -mfsc  # Model with migration, factory, seeder, controller
php artisan make:livewire ComponentName # Create Livewire component
php artisan make:filament-resource ResourceName --generate # Create Filament resource
\`\`\`

### Frontend (run from ${FRONTEND_DIR}/)
\`\`\`bash
cd ${FRONTEND_DIR}

# Development
npm run dev           # Start development server
npm run build        # Build for production

# Quality checks
npm run lint         # Run ESLint
npm run format       # Format code
npm run test         # Run tests
npm run type-check   # TypeScript checking (if applicable)
\`\`\`

## Development Workflow

### 1. API Development
When working on API features:
- Navigate to ${LARAVEL_DIR}/ for Laravel code
- Follow Laravel conventions and best practices
- All API endpoints should be in routes/api.php
- Use proper validation and resources
- Write Pest tests for new features

### 2. Frontend Development
When working on frontend features:
- Navigate to ${FRONTEND_DIR}/ for Vue code
- Follow Vue 3 composition API patterns
- Use TypeScript for type safety
- Implement proper error handling for API calls
- Write component tests

### 3. Full-Stack Features
When implementing features that span both:
1. Start with API endpoint design
2. Implement and test the API
3. Create frontend components
4. Integrate with API using composables
5. Test the full flow

## Database

- **Connection**: ${DB_CONNECTION}
- **Migrations**: ${LARAVEL_DIR}/database/migrations/
- **Seeders**: ${LARAVEL_DIR}/database/seeders/

## API Integration

Frontend API calls should:
- Use a centralized API client
- Handle authentication tokens properly
- Implement proper error handling
- Use TypeScript interfaces matching API responses

## Quality Standards

### Laravel/PHP
- PSR-12 coding standards
- Type declarations on all methods
- Pest tests for business logic
- Resources for API responses
- Proper validation rules

### Vue/TypeScript
- Composition API with \`<script setup>\`
- TypeScript for type safety
- Composables for reusable logic
- Proper component organization
- Tailwind CSS for styling

## Hooks

This project has automated quality checks:
- **Linting**: Runs after file edits
- **Testing**: Runs after file writes

All checks must pass (✅ GREEN) before continuing work.

## Common Tasks

### Adding a new API endpoint
1. Define route in ${LARAVEL_DIR}/routes/api.php
2. Create controller method
3. Add validation
4. Return resource
5. Write Pest test
6. Update API documentation

### Adding a new frontend page
1. Create Vue component in ${FRONTEND_DIR}/src/pages/
2. Add route configuration
3. Create necessary composables
4. Implement API integration
5. Add proper error handling
6. Write component tests

Remember: This is a feature branch - no backwards compatibility needed. Focus on clean, maintainable code.
EOF
    
    print_success "Multi-project CLAUDE.md created!"
}

# Create command shortcuts
create_command_shortcuts() {
    print_status "Creating command shortcuts..."
    
    # Check command
    cat > .claude/commands/check.md << 'EOF'
Run comprehensive checks on the multi-project codebase:

## Laravel API Checks
```bash
cd ${LARAVEL_DIR} && composer refactor:rector && composer refactor:lint && composer test:types && composer test:pest
```

## Frontend Checks
```bash
cd ${FRONTEND_DIR} && npm run lint && npm run format && npm run test
```

## Full Project Check
```bash
# Run all Laravel checks
(cd ${LARAVEL_DIR} && composer refactor:rector && composer refactor:lint && composer test:types && composer test:pest)

# Run all frontend checks
(cd ${FRONTEND_DIR} && npm run lint && npm run format && npm run test)
```

Review all output and fix any issues before proceeding.
EOF
    
    # Next command
    cat > .claude/commands/next.md << 'EOF'
Analyze the current state and suggest next development steps:

1. Check for failing tests in both Laravel and frontend
2. Review recent changes
3. Identify incomplete features
4. Suggest logical next implementation steps
5. Consider both API and UI aspects

Provide a prioritized list of next actions.
EOF
    
    print_success "Command shortcuts created!"
}

# Main setup function
main() {
    print_status "Starting multi-project Claude Code setup..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create .claude directory
    create_claude_directory
    
    # Setup global MCP servers
    setup_global_mcp_servers
    
    # Configure project-specific MCP
    configure_project_mcp
    
    # Create hooks
    create_multi_project_hooks
    
    # Create settings
    create_claude_settings
    
    # Create CLAUDE.md
    create_claude_md
    
    # Create command shortcuts
    create_command_shortcuts
    
    print_success "Multi-project setup complete!"
    echo ""
    echo "Your project structure:"
    echo "  - Laravel API: $LARAVEL_DIR/"
    echo "  - Frontend: $FRONTEND_DIR/"
    echo ""
    echo "To start using Claude Code:"
    echo "  1. Make sure Claude Code is running"
    echo "  2. From this directory, run: claude"
    echo ""
    echo "Claude Code will have access to both codebases with:"
    echo "  - Automated linting for both PHP and JavaScript"
    echo "  - Test running for both backend and frontend"
    echo "  - Database access for the Laravel API"
    echo "  - Full filesystem access to the entire project"
}

# Run main
main "$@"