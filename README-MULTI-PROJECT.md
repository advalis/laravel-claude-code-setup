# Multi-Project Laravel Claude Code Setup 🚀

Setup Claude Code for projects with separate Laravel API and frontend directories.

## 🎯 What This Does

Configures Claude Code for projects structured like:
```
your-project/
├── api/        # Laravel backend
└── webapp/     # Vue/React frontend
```

The multi-project setup provides:
- ✅ **Unified workspace** - Work on both API and frontend from project root
- ✅ **Smart hooks** - Linting/testing runs based on which files you edit
- ✅ **Full-stack commands** - Shortcuts for common full-stack tasks
- ✅ **Integrated workflow** - API-first development patterns

## 🚀 Quick Install

From your project root (parent of `api/` and `webapp/`):

```bash
curl -fsSL https://raw.githubusercontent.com/advalis/laravel-claude-code-setup/main/install-multi.sh | bash
```

The installer will:
1. Detect your Laravel and frontend directories
2. Configure MCP servers for the entire project
3. Create hooks that understand both codebases
4. Set up commands for full-stack development

## 📁 Supported Structures

The installer looks for these common patterns:

### Laravel API directories:
- `api/`
- `backend/`
- `laravel-api/`
- `server/`

### Frontend directories:
- `webapp/`
- `frontend/`
- `client/`
- `vue-app/`
- `web/`
- `app/`

## 🔧 How It Works

### Smart Hook Detection
Hooks automatically detect which part of the project you're editing:
- Edit a file in `api/` → Runs Laravel linting/tests
- Edit a file in `webapp/` → Runs frontend linting/tests
- No file context → Runs both

### Unified Commands
Work from the project root:
```bash
# Start Claude Code from project root
claude

# Both codebases are accessible
# Commands like /check run on both
```

### Project-Aware CLAUDE.md
The generated CLAUDE.md understands your structure:
- Provides commands for both environments
- Suggests full-stack workflows
- Maintains quality standards for both

## 📋 Prerequisites

Same as regular setup plus:
- Your project must have the multi-directory structure
- Frontend directory must have `package.json`
- Laravel directory must have `artisan` and `.env`

## 🎮 Usage

After installation:
```bash
# From project root
claude
```

Then use commands like:
- `/check` - Runs all quality checks for both projects
- `/next` - Suggests next full-stack development steps

### Example Workflow
```
You: "Add a products API endpoint with frontend list view"

Claude will:
1. Create Laravel model, migration, controller, resource
2. Add API routes and write Pest tests  
3. Create TypeScript types matching API
4. Build Vue components with proper error handling
5. Test the complete integration
```

## 🛠️ What Gets Created

```
your-project/
├── .claude/
│   ├── CLAUDE.md           # Multi-project instructions
│   ├── hooks/
│   │   ├── lint.sh        # Smart linting for both
│   │   └── test.sh        # Smart testing for both
│   ├── commands/
│   │   ├── check.md       # Full-stack checks
│   │   └── next.md        # Development guidance
│   └── settings.local.json # Hook configuration
├── api/                    # Your Laravel code
└── webapp/                 # Your frontend code
```

## 🔧 Customization

### Different Directory Names
If your directories have different names, specify them:
```bash
# Download and run with custom paths
curl -fsSL https://raw.githubusercontent.com/advalis/laravel-claude-code-setup/main/scripts/setup-claude-code-multi.sh -o setup.sh
chmod +x setup.sh
./setup.sh backend frontend
```

### Adding More Directories
Edit `.claude/hooks/lint.sh` and `.claude/hooks/test.sh` to add more directories to check.

## 🐛 Troubleshooting

### Directory Not Found
The installer checks for:
- Laravel: `artisan` and `composer.json` files
- Frontend: `package.json` file

Make sure these exist in your directories.

### Hooks Not Running
Ensure you're running Claude Code from the project root, not from subdirectories.

### Wrong Directory Detected
Specify directories manually:
```bash
./setup.sh my-api-dir my-frontend-dir
```

## 🤝 Contributing

To improve multi-project support:
1. Fork the repository
2. Test with your project structure
3. Submit PR with improvements

## 📝 License

MIT License - same as the main project