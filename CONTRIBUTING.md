# Contributing to ZeppNightscout

Thank you for your interest in contributing to ZeppNightscout! This document provides guidelines for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Code Style](#code-style)
- [Commit Guidelines](#commit-guidelines)

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ZeppNightscout.git
   # Replace YOUR_USERNAME with your GitHub username
   cd ZeppNightscout
   ```
3. **Install dependencies** (if any):
   ```bash
   npm install
   ```
4. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

1. Make your changes in your feature branch
2. Test your changes locally (see [Testing Requirements](#testing-requirements))
3. Commit your changes with clear commit messages
4. Push to your fork
5. Open a Pull Request

## Pull Request Process

### Before Submitting a PR

✅ **Run all tests locally**:

```bash
# Check JavaScript syntax
npm run test:syntax

# Run unit tests
npm test

# Test help command
npm run help
```

✅ **Verify your changes**:
- Code works as expected
- No breaking changes to existing functionality
- Documentation is updated if needed
- Code follows project style guidelines

### Opening a PR

1. Go to the main repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill in the PR template with:
   - **Title**: Clear, concise description of changes
   - **Description**: What changes were made and why
   - **Testing**: How you tested the changes
   - **Screenshots**: For UI changes

### Automated Testing

When you open a PR, GitHub Actions will automatically run:

- **JavaScript Syntax Check**: Validates all JS files
- **Unit Tests**: Runs the data parser test suite (26 assertions)
- **Help Command Test**: Verifies the help script works

**All tests must pass before your PR can be merged.**

You can view test results in the PR's "Checks" section.

### PR Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Tests will re-run automatically after each push
4. Once approved and all tests pass, your PR will be merged

## Testing Requirements

### Minimum Testing Standards

All contributions must include appropriate tests:

#### For Code Changes

- [ ] Run `npm run test:syntax` - No syntax errors
- [ ] Run `npm test` - All tests pass
- [ ] Add new tests for new functionality
- [ ] Update existing tests if behavior changes

#### For Documentation Changes

- [ ] Preview markdown formatting
- [ ] Check all links work
- [ ] Verify code examples are correct

### Running Tests

See [TESTING.md](TESTING.md) for comprehensive testing instructions.

Quick commands:

```bash
# Run all tests
npm test

# Check syntax
npm run test:syntax

# View help
npm run help

# Test in simulator (requires Zeus CLI)
zeus dev
```

## Code Style

### JavaScript

- Use ES6+ syntax
- Use meaningful variable names
- Add comments for complex logic
- Follow existing code style in the file
- Use semicolons consistently

### File Organization

```
ZeppNightscout/
├── app-side/       # App-side service (phone)
├── page/           # Device-side UI (watch)
├── shared/         # Shared code
├── scripts/        # Build and utility scripts
├── assets/         # Images and resources
└── .github/        # GitHub workflows and templates
```

### Documentation

- Use clear, concise language
- Include code examples where helpful
- Keep documentation up-to-date with code changes
- Follow markdown best practices

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add URL verification before data fetch

- Implement /api/v1/status endpoint check
- Display verification status to user
- Prevent fetching with invalid URLs

Closes #42
```

```
fix: Prevent array mutation in data parsing

The dataPoints.reverse() was mutating the original array.
Changed to use slice().reverse() to avoid side effects.
```

```
docs: Update testing guide with CI/CD information

Added section explaining GitHub Actions automated testing
and how to view test results in PRs.
```

## Questions or Issues?

- **Documentation**: Check [TESTING.md](TESTING.md), [DEVELOPMENT.md](DEVELOPMENT.md), and [README.md](README.md)
- **Bugs**: Open an issue with details and steps to reproduce
- **Features**: Open an issue to discuss before implementing
- **Questions**: Open a discussion or issue

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the project
- Welcome newcomers and help them get started

## License

By contributing to ZeppNightscout, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to ZeppNightscout! 🎉
