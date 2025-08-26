@echo off
REM AI Trading Expert Advisor - Repository Setup Script (Windows)
REM This script helps you upload your project to a private Git repository

title AI Trading Expert Advisor - Repository Setup

echo.
echo 🚀 AI Trading Expert Advisor - Repository Setup
echo ================================================
echo.

REM Check if we're in the right directory
if not exist "PROJECT_SUMMARY.md" (
    echo ❌ Error: Please run this script from the AI_Expert_Advisor directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo 📁 Current directory: %CD%
echo ✅ Project files detected
echo.

REM Check if git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Git is not installed. Please install Git first.
    echo Download from: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo ✅ Git is available
echo.

REM Initialize git repository if not already initialized
if not exist ".git" (
    echo 🔧 Initializing Git repository...
    git init
    echo ✅ Git repository initialized
) else (
    echo ✅ Git repository already exists
)

echo.

REM Add all files to git
echo 📋 Adding files to Git...
git add .

REM Check git status
echo.
echo 📊 Git Status:
git status --short

echo.

REM Create initial commit
echo 💾 Creating initial commit...
git commit -m "Initial commit: AI Trading Expert Advisor v1.0

🚀 Features:
- AI-powered news and sentiment analysis
- ATR Channel trading strategy with breakout/reversal signals
- Professional visual dashboard with real-time updates
- TradingView webhook integration with Python server
- Comprehensive risk management system
- MT4/MT5 cross-platform compatibility
- Enterprise-grade logging and error handling
- Complete documentation and configuration templates

📊 Components:
- Expert Advisor files for MT4 and MT5
- Modular include libraries (AI Engine, Risk Management, Utils, Visual)
- Python webhook server with Flask framework
- Configuration templates and documentation
- ATR Channel strategy implementation
- Professional dashboard with AI analysis display

🛡️ Security & Risk:
- Input validation and error handling
- Comprehensive risk management controls
- Secure webhook authentication options
- Trading disclaimers and safety guidelines

📚 Documentation:
- Complete installation and setup guide
- ATR Channel strategy documentation
- Configuration reference and examples
- Troubleshooting and best practices"

if %errorlevel% equ 0 (
    echo ✅ Initial commit created successfully
) else (
    echo ℹ️  No changes to commit (files may already be committed)
)

echo.
echo 🌐 Next Steps - Choose your Git hosting platform:
echo.
echo Option 1: GitHub (Recommended)
echo ===============================
echo 1. Go to https://github.com/new
echo 2. Repository name: ai-trading-expert-advisor
echo 3. Set to Private ✅
echo 4. Don't initialize with README (we have one)
echo 5. Create repository
echo 6. Copy the repository URL
echo 7. Run these commands:
echo.
echo    git remote add origin https://github.com/xnox-me/ai-trading-expert-advisor.git
echo    git branch -M main
echo    git push -u origin main
echo.

echo Option 2: GitLab
echo ================
echo 1. Go to https://gitlab.com/projects/new
echo 2. Project name: ai-trading-expert-advisor
echo 3. Visibility Level: Private ✅
echo 4. Don't initialize with README
echo 5. Create project
echo 6. Run these commands:
echo.
echo    git remote add origin https://gitlab.com/YOUR_USERNAME/ai-trading-expert-advisor.git
echo    git branch -M main
echo    git push -u origin main
echo.

echo Option 3: Bitbucket
echo ===================
echo 1. Go to https://bitbucket.org/repo/create
echo 2. Repository name: ai-trading-expert-advisor
echo 3. Access level: Private ✅
echo 4. Include a README: No
echo 5. Create repository
echo 6. Run these commands:
echo.
echo    git remote add origin https://YOUR_USERNAME@bitbucket.org/YOUR_USERNAME/ai-trading-expert-advisor.git
echo    git branch -M main
echo    git push -u origin main
echo.

echo 📋 Quick Command Reference:
echo ==========================
echo Check status:           git status
echo Add changes:            git add .
echo Commit changes:         git commit -m "Your message"
echo Push to remote:         git push
echo Pull from remote:       git pull
echo View commit history:    git log --oneline
echo.

echo 🔒 Security Reminders:
echo ======================
echo ✅ .gitignore file created to exclude sensitive files
echo ✅ No API keys or passwords in the code
echo ✅ Repository will be private
echo ⚠️  Always review changes before committing
echo ⚠️  Never commit real account credentials
echo ⚠️  Test on demo accounts first
echo.

echo 📚 Repository Contents:
echo ======================
echo ✅ Main README.md with comprehensive project overview
echo ✅ LICENSE file with MIT license and trading disclaimers
echo ✅ CHANGELOG.md for version tracking
echo ✅ CONTRIBUTING.md for development guidelines
echo ✅ .gitignore configured for MetaTrader and Python projects
echo ✅ Complete Expert Advisor implementation for MT4/MT5
echo ✅ All include libraries and modules
echo ✅ Python webhook server with dependencies
echo ✅ Configuration templates and documentation
echo.

echo 🎯 Ready for Upload!
echo ===================
echo Your AI Trading Expert Advisor is now ready to be uploaded
echo to your private Git repository. Follow the steps above for
echo your chosen platform.
echo.
echo Happy Trading! 🚀📈
echo.
pause