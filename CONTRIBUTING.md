# Contributing to AI Trading Expert Advisor

Thank you for your interest in contributing to the AI Trading Expert Advisor project! This document provides guidelines for contributing to the codebase.

## 🤝 How to Contribute

### Reporting Issues
1. **Search existing issues** first to avoid duplicates
2. **Use demo account** to reproduce the issue
3. **Provide detailed information**:
   - MetaTrader version and build
   - Operating system
   - EA version and configuration
   - Steps to reproduce
   - Expected vs actual behavior
   - Log files (remove sensitive data)

### Suggesting Features
1. **Check existing requests** in issues
2. **Describe the use case** and business value
3. **Consider compatibility** with both MT4 and MT5
4. **Think about risk implications** for trading features

## 🔧 Development Setup

### Prerequisites
- MetaTrader 4 and/or MetaTrader 5
- MetaEditor (comes with MetaTrader)
- Python 3.8+ for webhook server development
- Git for version control
- Text editor or IDE (VS Code recommended)

### Environment Setup
```bash
# Clone the repository
git clone https://github.com/xnox-me/DEA.git
cd DEA

# Set up Python environment
cd Webhook_Server
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
pip install -r requirements.txt

# Copy to MetaTrader for testing
# Copy MQL files to respective MetaTrader directories
```

## 📋 Development Guidelines

### Code Style

#### MQL4/MQL5 Standards
```mql4
// Use clear, descriptive names
bool CalculateATRChannel(int shift = 0);

// Document complex functions
//+------------------------------------------------------------------+
//| Calculate ATR Channel                                            |
//| Parameters: shift - bar index for calculation                   |
//| Returns: true if calculation successful                         |
//+------------------------------------------------------------------+

// Use consistent indentation (4 spaces)
if(condition)
{
    DoSomething();
    return true;
}

// Group related variables
struct SATRChannelData
{
    double top_line;
    double bottom_line;
    double middle_line;
    // ... more fields
};
```

#### Python Standards
```python
# Follow PEP 8
def process_webhook_signal(signal_data: dict) -> bool:
    """
    Process incoming webhook signal.
    
    Args:
        signal_data: Dictionary containing signal information
        
    Returns:
        True if signal processed successfully
    """
    if not validate_signal(signal_data):
        logger.error("Invalid signal format")
        return False
    
    return execute_signal(signal_data)
```

### Testing Requirements

#### For MQL Code
1. **Strategy Tester**: Test with historical data
2. **Demo Account**: Validate with live demo trading
3. **Error Simulation**: Test error handling scenarios
4. **Cross-Platform**: Verify MT4 and MT5 compatibility

#### For Python Code
```python
# Include unit tests
import unittest

class TestWebhookHandler(unittest.TestCase):
    def test_signal_validation(self):
        valid_signal = {"action": "BUY", "symbol": "EURUSD"}
        self.assertTrue(validate_signal(valid_signal))
        
    def test_invalid_signal(self):
        invalid_signal = {"action": "INVALID"}
        self.assertFalse(validate_signal(invalid_signal))
```

### Documentation Standards

#### Code Documentation
- **Function headers**: Describe purpose, parameters, return values
- **Complex logic**: Explain non-obvious code sections
- **Configuration**: Document all input parameters
- **Examples**: Provide usage examples for complex features

#### User Documentation
- **Clear instructions**: Step-by-step procedures
- **Screenshots**: Visual guides for UI components
- **Examples**: Real-world configuration examples
- **Troubleshooting**: Common issues and solutions

## 🔀 Git Workflow

### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `docs/description` - Documentation updates

### Commit Messages
```
type(scope): short description

Longer description if needed

- Bullet points for details
- Reference issues: Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Process
1. **Create feature branch** from `main`
2. **Make changes** following coding standards
3. **Test thoroughly** on demo account
4. **Update documentation** if needed
5. **Create pull request** with detailed description
6. **Address review feedback** promptly

## 🧪 Testing Guidelines

### Before Submitting
- [ ] Code compiles without errors in MetaEditor
- [ ] All functions have proper error handling
- [ ] Demo account testing completed
- [ ] Documentation updated
- [ ] No sensitive data in code
- [ ] Cross-platform compatibility verified

### Testing Checklist
```markdown
## Testing Checklist
- [ ] EA initializes without errors
- [ ] Dashboard displays correctly
- [ ] AI analysis functions work
- [ ] ATR Channel calculations accurate
- [ ] Webhook signals processed correctly
- [ ] Risk management enforced
- [ ] Logging functions properly
- [ ] Error scenarios handled gracefully
```

## 🛡️ Security Guidelines

### Sensitive Information
- **Never commit**: API keys, passwords, account numbers
- **Use environment variables**: For configuration secrets
- **Sanitize logs**: Remove sensitive data from log files
- **Review carefully**: Check commits for leaked information

### Code Security
- **Input validation**: Validate all external inputs
- **Error handling**: Don't expose internal details in errors
- **Access control**: Implement proper authentication where needed
- **Safe defaults**: Use secure default configurations

## 📝 Code Review Guidelines

### For Reviewers
- **Functionality**: Does the code work as intended?
- **Testing**: Has it been properly tested?
- **Documentation**: Is it adequately documented?
- **Security**: Are there any security concerns?
- **Performance**: Is it efficient and optimized?
- **Style**: Does it follow project conventions?

### For Contributors
- **Small changes**: Keep PRs focused and manageable
- **Clear description**: Explain what and why
- **Test evidence**: Provide testing screenshots/logs
- **Responsive**: Address feedback promptly
- **Patient**: Allow time for thorough review

## 🎯 Feature Development Process

### Planning Phase
1. **Issue discussion**: Discuss approach in GitHub issue
2. **Design review**: For significant features
3. **Breaking changes**: Discuss impact on existing users
4. **Testing strategy**: Plan comprehensive testing approach

### Implementation Phase
1. **Incremental commits**: Small, logical changes
2. **Regular testing**: Test frequently during development
3. **Documentation**: Update docs as you code
4. **Feedback loops**: Seek early feedback on approach

### Release Phase
1. **Final testing**: Comprehensive testing on demo
2. **Performance check**: Verify no performance regression
3. **Documentation review**: Ensure all docs are current
4. **Version update**: Update version numbers appropriately

## 🏷️ Versioning Strategy

### Version Numbers
- **Major (X.0.0)**: Breaking changes or major rewrites
- **Minor (X.Y.0)**: New features, backward compatible
- **Patch (X.Y.Z)**: Bug fixes, minor improvements

### Release Process
1. **Feature freeze**: Stop adding new features
2. **Testing phase**: Comprehensive testing period
3. **Documentation update**: Finalize all documentation
4. **Version tag**: Create git tag with version number
5. **Release notes**: Document changes and improvements

## ❓ Getting Help

### Resources
- **Documentation**: Check `/Documentation/` folder first
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Code examples**: Reference existing implementations

### Contact
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: For security-related concerns (if provided)

Thank you for contributing to the AI Trading Expert Advisor project! 🚀