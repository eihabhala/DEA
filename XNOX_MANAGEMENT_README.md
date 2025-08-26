# 🚀 xnox-me Repository Management Tools

## 📋 Overview

This directory contains comprehensive tools for managing and maintaining all repositories under the xnox-me GitHub organization. These scripts help ensure code quality, consistency, and proper maintenance across all projects.

## 🛠️ Tools Included

### 1. xnox-repo-checker.sh - Repository Health Checker
A comprehensive script that checks all xnox-me repositories for:
- Git status and uncommitted changes
- Missing README, LICENSE, and .gitignore files
- Broken links in documentation
- TODO/FIXME comments indicating incomplete work
- Python syntax errors
- Large files that shouldn't be in the repository
- General repository health metrics

### 2. xnox-update-all.sh - Repository Update Tool
A script that clones or updates all xnox-me repositories to ensure you have the latest versions.

## 🚀 Quick Start

### Running the Health Checker
```bash
# Basic check of all xnox-me repositories
./xnox-repo-checker.sh

# Verbose output with detailed reporting
./xnox-repo-checker.sh -v -r

# Check a different organization
./xnox-repo-checker.sh -o myorganization
```

### Updating All Repositories
```bash
# Update all xnox-me repositories
./xnox-update-all.sh

# Update to a custom directory
./xnox-update-all.sh -d /path/to/my/repos

# Verbose output
./xnox-update-all.sh -v
```

## 📊 Features

### Repository Health Checker Features:
- **Multi-Repository Support**: Checks all repositories in an organization
- **Comprehensive Validation**: Multiple checks for code quality and consistency
- **Colorized Output**: Easy-to-read colored terminal output
- **Detailed Logging**: Comprehensive logs for auditing and debugging
- **Report Generation**: Optional detailed HTML/text reports
- **Error Tracking**: Tracks repositories with issues for follow-up

### Repository Update Features:
- **Smart Cloning**: Only clones repositories that don't exist locally
- **Intelligent Updates**: Only pulls changes when updates are available
- **Progress Tracking**: Shows update progress for each repository
- **Error Handling**: Graceful handling of network and git errors
- **Customizable Paths**: Configurable working directories

## ⚙️ Configuration Options

### Health Checker Options:
```
-o, --org NAME      GitHub organization name (default: xnox-me)
-d, --dir PATH      Working directory (default: /tmp/xnox-check)
-v, --verbose       Verbose output
-q, --quiet         Quiet mode (only errors)
-r, --report        Generate detailed report
-h, --help          Show help message
```

### Update Tool Options:
```
-o, --org NAME      GitHub organization name (default: xnox-me)
-d, --dir PATH      Working directory (default: $HOME/xnox-repos)
-v, --verbose       Verbose output
-q, --quiet         Quiet mode (only errors)
-h, --help          Show help message
```

## 📁 Output Files

### Health Checker Output:
- **General Log**: `/tmp/xnox-check.log` - Complete operation log
- **Error Log**: `/tmp/xnox-errors.log` - Summary of repositories with errors
- **Report File**: `/tmp/xnox-report.txt` - Detailed report (when -r flag used)

### Update Tool Output:
- **Update Log**: `/tmp/xnox-update.log` - Repository update log
- **Repositories**: Stored in `$HOME/xnox-repos` by default

## 🎯 Use Cases

### For Repository Maintainers:
1. **Regular Health Checks**: Run weekly to ensure repository quality
2. **Pre-Release Validation**: Check all repositories before major releases
3. **Team Code Reviews**: Use reports for team-wide code quality discussions
4. **CI/CD Integration**: Integrate checks into continuous integration pipelines

### For Contributors:
1. **Local Development**: Keep all xnox-me repositories up to date
2. **Quality Assurance**: Check your forked repositories for issues
3. **Documentation Review**: Identify broken links and missing documentation
4. **Code Cleanup**: Find and address TODO/FIXME comments

## 🔧 Requirements

- **Git**: For repository operations
- **curl**: For GitHub API requests
- **jq**: For JSON parsing of GitHub API responses
- **Python 3**: For Python syntax checking
- **Bash 4+**: For advanced scripting features

Install requirements on Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install git curl jq python3
```

Install requirements on CentOS/RHEL:
```bash
sudo yum install git curl jq python3
```

## 📈 Health Check Categories

### Critical Errors:
- Git clone/pull failures
- Python syntax errors
- Missing essential files (README, LICENSE, .gitignore)

### Warnings:
- Uncommitted changes
- TODO/FIXME comments
- Large files in repository
- Broken links (basic detection)

### Informational:
- Repository status
- Update availability
- File counts and sizes

## 🔄 Workflow Integration

### Automated Weekly Checks:
```bash
# Add to crontab for weekly checks
0 0 * * 0 /path/to/xnox-repo-checker.sh -r >> /var/log/xnox-weekly.log 2>&1
```

### Continuous Integration:
```bash
# Add to CI pipeline
./xnox-repo-checker.sh -q
```

### Pre-Commit Hooks:
```bash
# Add to pre-commit for local development
./xnox-repo-checker.sh --repo $(basename $(pwd)) --quick
```

## 📊 Sample Output

```
=== xnox-me Repository Error Checker ===
[INFO] Checking dependencies...
[SUCCESS] All dependencies available
[INFO] Fetching repository list for organization: xnox-me
[SUCCESS] Found 3 repositories

=== Checking Repository: DEA ===
[INFO] Updating repository...
[SUCCESS] Repository is up to date
[INFO] Checking git status...
[SUCCESS] Clean git status
[INFO] Checking README...
[SUCCESS] README file present
[INFO] Checking license...
[WARNING] No license file found
[INFO] Checking .gitignore...
[SUCCESS] .gitignore file present
[INFO] Checking for broken links...
[SUCCESS] Link check completed
[INFO] Checking for common error patterns...
[WARNING] Found 2 TODO comments
[INFO] Running Python syntax check...
[SUCCESS] All Python files syntax correct
[INFO] Checking for large files...
[SUCCESS] No large files found

=== Repository Summary: DEA ===
Errors: 0 | Warnings: 2

=== Final Summary ===
Total Repositories: 3
Checked Repositories: 3
Repositories with Errors: 0
Repositories with Warnings: 1
[SUCCESS] All repositories checked successfully with no errors!
```

## 🤝 Contributing

### Adding New Checks:
1. Fork the repository
2. Add your check function to the appropriate section
3. Update the documentation
4. Submit a pull request

### Improving Existing Features:
1. Open an issue describing the improvement
2. Fork and implement the changes
3. Add tests if applicable
4. Submit a pull request

## 📞 Support

For issues, feature requests, or questions:
1. Check the existing issues on GitHub
2. Open a new issue with detailed information
3. Include error messages and steps to reproduce
4. Tag maintainers if needed

## 📄 License

These management tools are provided as open-source software under the MIT License. See the LICENSE file in the main repository for details.

---

**Built with ❤️ for the xnox-me community** • **Making repository management easier for everyone**