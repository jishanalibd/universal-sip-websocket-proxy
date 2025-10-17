# Contributing to Universal SIP WebSocket Proxy

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

1. **Clear title** - Brief description of the issue
2. **Environment details**:
   - OS version (Ubuntu 22.04/24.04)
   - Kamailio version
   - rtpengine version
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Logs** - Relevant log excerpts
7. **Configuration** - Sanitized config files (remove sensitive data)

### Suggesting Features

Feature requests are welcome! Please:

1. Check if the feature already exists or is planned
2. Describe the use case
3. Explain the expected behavior
4. Consider implementation complexity

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages**
6. **Push to your fork**
7. **Create a Pull Request**

#### Pull Request Guidelines

- **One feature per PR** - Keep PRs focused
- **Update documentation** - If you change functionality
- **Test your changes** - On Ubuntu 22.04 or 24.04
- **Follow existing code style**
- **Add comments** - For complex logic
- **Update README** - If adding new features

## Development Setup

### Testing Locally

1. Set up a test VM (Ubuntu 22.04/24.04)
2. Clone your fork
3. Run installation script
4. Test your changes
5. Check logs for errors

### Code Style

#### Shell Scripts

- Use bash shebang: `#!/bin/bash`
- Add error handling: `set -e`
- Use functions for reusability
- Add comments for complex logic
- Use meaningful variable names
- Follow existing formatting

Example:
```bash
#!/bin/bash
set -e

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Main logic
main() {
    log_info "Starting process..."
    # Your code here
}

main "$@"
```

#### Kamailio Configuration

- Add comments for non-obvious settings
- Group related configurations
- Use meaningful route names
- Follow existing structure

#### Documentation

- Use Markdown
- Keep lines under 100 characters
- Use code blocks with language tags
- Add table of contents for long documents
- Include examples

## Testing

### Before Submitting PR

Test the following scenarios:

1. **Fresh installation**
   - Ubuntu 22.04
   - Ubuntu 24.04

2. **Basic functionality**
   - WebSocket connection
   - SIP registration
   - Audio call

3. **Edge cases**
   - SSL certificate renewal
   - Service restart
   - Configuration reload

4. **Documentation**
   - All commands work as documented
   - Examples are accurate
   - Links are valid

## Documentation

### What to Document

- New features
- Configuration changes
- Breaking changes
- Migration guides

### Where to Document

- `README.md` - Overview and quick start
- `docs/INSTALLATION.md` - Installation steps
- `docs/CLIENT-EXAMPLES.md` - Client configuration
- `docs/TROUBLESHOOTING.md` - Common issues
- Code comments - Complex logic

## Commit Messages

Use clear, descriptive commit messages:

**Good examples:**
```
Add support for IPv6 in rtpengine configuration
Fix WebSocket timeout issue on slow connections
Update installation docs for Ubuntu 24.04
```

**Bad examples:**
```
fix bug
update
wip
```

### Commit Message Format

```
<type>: <short description>

<detailed description if needed>

<issue reference if applicable>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `config`: Configuration changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

## Security

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities.

Instead:
1. Email the maintainers directly
2. Provide details of the vulnerability
3. Allow time for a fix before public disclosure

### Security Best Practices

- Never commit credentials
- Sanitize logs of sensitive data
- Use secure defaults
- Follow least privilege principle
- Keep dependencies updated

## Code Review Process

1. **Automated checks** - Must pass
2. **Maintainer review** - Code quality and functionality
3. **Testing** - On clean Ubuntu installation
4. **Documentation review** - Completeness and accuracy
5. **Merge** - When all checks pass

## Community Guidelines

- Be respectful and constructive
- Help others learn
- Share knowledge
- Give credit where due
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md)

## Questions?

- Check existing documentation
- Search existing issues
- Ask in discussions
- Create a new issue if needed

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort!
