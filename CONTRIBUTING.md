# Contributing to rails_simple_auth

Thank you for your interest in contributing to rails_simple_auth! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone git@github.com:YOUR_USERNAME/rails_simple_auth.git`
3. Install dependencies: `bundle install`
4. Run tests: `bundle exec rake test`

## Development Setup

```bash
# Clone the repository
git clone git@github.com:ivankuznetsov/rails_simple_auth.git
cd rails_simple_auth

# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run linting
bundle exec rubocop
```

## Making Changes

1. Create a new branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Write tests for new functionality
4. Ensure all tests pass: `bundle exec rake test`
5. Ensure code passes linting: `bundle exec rubocop`
6. Commit your changes with a descriptive message
7. Push to your fork: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Pull Request Guidelines

- **One feature per PR**: Keep pull requests focused on a single change
- **Write tests**: All new features and bug fixes should include tests
- **Update documentation**: Update README if adding new features
- **Update CHANGELOG**: Add your changes under `[Unreleased]`
- **Follow code style**: Run `bundle exec rubocop` before submitting

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(oauth): add support for Apple Sign In`
- `fix(sessions): handle expired tokens gracefully`
- `docs(readme): add configuration examples`

## Code Style

- Follow Ruby community style guidelines
- Use RuboCop for linting
- Write clear, self-documenting code
- Add comments for complex logic

## Testing

- Write tests for all new functionality
- Use MiniTest (the default Rails testing framework)
- Test both success and failure cases
- Test edge cases and error handling

```bash
# Run all tests
bundle exec rake test

# Run a specific test file
bundle exec ruby -Itest test/path/to/test_file.rb
```

## Reporting Issues

When reporting issues, please include:

1. Ruby and Rails versions
2. Steps to reproduce the issue
3. Expected behavior
4. Actual behavior
5. Error messages (if any)

## Security Issues

For security vulnerabilities, please see [SECURITY.md](SECURITY.md) for responsible disclosure guidelines.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue for questions or discussions about potential changes.

Thank you for contributing!
