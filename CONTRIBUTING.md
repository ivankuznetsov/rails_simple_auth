# Contributing to RailsSimpleAuth

Thank you for your interest in contributing!

## How to Contribute

### Reporting Bugs

1. Check existing [issues](https://github.com/ivankuznetsov/rails_simple_auth/issues) first
2. Use the bug report template
3. Include Ruby/Rails versions, steps to reproduce, and expected vs actual behavior

### Suggesting Features

1. Open an issue using the feature request template
2. Explain the use case and why it benefits the gem

### Pull Requests

1. **Open an issue first** to discuss the change
2. Fork the repository
3. Create a feature branch (`git checkout -b feature/my-feature`)
4. Write tests for your changes
5. **Run local CI before submitting:**
   ```bash
   bin/ci
   ```
   This runs RuboCop and all unit tests.
6. Update CHANGELOG.md under `[Unreleased]`
7. Submit a pull request

### Local Development

```bash
# Install dependencies
bundle install

# Run local CI (linter + tests)
bin/ci

# Run only tests
bundle exec rake test

# Run only linter
bundle exec rubocop

# Run generator E2E tests (optional, requires Rails + Playwright)
bin/test_generator
```

### Code Style

- Follow existing code patterns
- Use RuboCop for linting
- Write clear commit messages
- Add tests for new functionality

## Review Process

This is a solo-maintained project. PRs are reviewed and merged by the maintainer. Please be patient - response times may vary.

## Questions?

Open an issue with the question label.
