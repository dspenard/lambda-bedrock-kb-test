# Contributing to Bedrock Agent Test Bed

Thank you for your interest in contributing to this project! This guide will help you get started.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Follow the setup instructions in the README.md
4. Create a new branch for your feature or bug fix

## Development Setup

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- Python 3.9+ for Lambda functions
- `jq` for JSON processing (optional, for testing)

### Local Development
```bash
# Clone your fork
git clone https://github.com/your-username/bedrock-agent-testbed.git
cd bedrock-agent-testbed

# Make your changes
# Test your changes using the provided scripts
./test-lambda.sh both Tokyo
```

## Making Changes

### Code Style
- Follow existing code formatting
- Add comments for complex logic
- Update documentation for any new features

### Testing
- Test all Lambda functions after changes
- Verify Terraform configurations with `terraform plan`
- Test both direct and agent-based approaches

### Documentation
- Update README.md for new features
- Add examples for new functionality
- Update inline code comments

## Submitting Changes

1. **Create a Pull Request**
   - Use a clear, descriptive title
   - Describe what your changes do
   - Reference any related issues

2. **Pull Request Guidelines**
   - Keep changes focused and atomic
   - Include tests for new functionality
   - Update documentation as needed

3. **Review Process**
   - Maintainers will review your PR
   - Address any feedback promptly
   - Be patient during the review process

## Areas for Contribution

### High Priority
- Additional data sources for knowledge base
- Enhanced error handling and logging
- API Gateway integration
- Monitoring and alerting setup

### Medium Priority
- Additional Lambda function examples
- More comprehensive testing
- Performance optimizations
- Documentation improvements

### Low Priority
- UI/dashboard for testing
- Additional AWS regions support
- Alternative vector databases

## Reporting Issues

When reporting issues, please include:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- AWS region and Terraform version
- Relevant log outputs

## Questions?

Feel free to open an issue for questions about:
- How to contribute
- Architecture decisions
- Feature requests
- General usage questions

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to learn and build something useful together.