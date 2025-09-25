# 🚀 GitHub Actions CI/CD Workflows

This directory contains the CI/CD workflows for the Inputly project. These workflows ensure code quality, run tests, and verify builds automatically.

## 📋 Available Workflows

### 1. **lint-and-format.yml** - Code Quality
**Triggers**: Push and PR to `main`, `staging` branches

**What it does**:
- ✅ Runs ESLint to check for code issues
- ✅ Runs Prettier to verify code formatting
- ✅ Provides clear error messages and fix suggestions
- ✅ Uses Node.js 20.x with npm caching for performance

**Fix suggestions provided**:
- `npm run lint:fix` - Auto-fix ESLint issues
- `npm run format` - Fix code formatting

### 2. **tests.yml** - Test Suite
**Triggers**: Push and PR to `main`, `staging` branches

**What it does**:
- ✅ Runs the complete Jest test suite
- ✅ Generates and uploads coverage reports
- ✅ Sets proper environment variables for testing
- ✅ Creates GitHub step summaries with test results
- ✅ Provides annotations for test failures
- ✅ Uploads coverage artifacts (30-day retention)

**Environment Variables Set**:
- `NODE_ENV=test`
- `NODE_OPTIONS=--experimental-vm-modules`
- `DATABASE_URL=postgres://test:test@localhost:5432/inputly_test`
- `JWT_SECRET=test-jwt-secret`
- `ARCJET_KEY=test-arcjet-key`

### 3. **ci.yml** - Comprehensive CI Pipeline
**Triggers**: Push and PR to `main`, `staging`, `develop` branches

**What it does**:
- ✅ **Code Quality**: ESLint, Prettier, Security audit
- ✅ **Build Verification**: Production dependency check
- ✅ **Comprehensive reporting**: Detailed summaries and artifacts

## 🔧 Workflow Features

### **Performance Optimizations**
- **Node.js caching**: Speeds up dependency installation
- **Job dependencies**: Efficient pipeline execution order
- **Artifact management**: Proper retention policies

### **Error Handling & Feedback**
- **Clear error messages**: Actionable feedback for developers
- **GitHub annotations**: In-line code suggestions
- **Step summaries**: Visual reports in PR/commit view
- **Fix suggestions**: Exact commands to resolve issues

### **Artifacts & Reports**
- **Coverage reports**: 30-day retention
- **ESLint results**: JSON format for analysis
- **Test outputs**: Complete logs and results

## 🚦 Workflow Status Examples

### ✅ Success
```
✅ All linting and formatting checks passed!
✅ All tests passed successfully!
✅ Application build completed successfully
```

### ❌ Failure with Fix Suggestions
```
❌ ESLint found issues! Run 'npm run lint:fix' to automatically fix some issues.
❌ Code formatting issues found! Run 'npm run format' to fix formatting.
❌ Some tests failed! Check the test output above for details.
```

## 📊 Coverage Reports

The test workflow generates detailed coverage reports including:
- **Statements coverage**
- **Branch coverage** 
- **Function coverage**
- **Line coverage**

Reports are available as:
- Artifacts in GitHub Actions
- Step summaries in the workflow run
- JSON format for CI integration

## 🛠️ Local Development

Run the same checks locally before pushing:

```bash
# Code quality checks
npm run lint        # Check for linting issues
npm run lint:fix    # Auto-fix linting issues
npm run format:check # Check formatting
npm run format      # Fix formatting

# Run tests
npm test           # Run test suite with coverage

# Security check
npm audit          # Check for vulnerabilities
npm audit fix      # Fix vulnerabilities
```

## 📈 Workflow Optimization

These workflows are optimized for:
- **Speed**: Caching and parallel jobs
- **Reliability**: Comprehensive error handling
- **Feedback**: Clear, actionable error messages
- **Maintainability**: Well-structured and documented

## 🔐 Environment Variables

Test environment variables are safely configured in the workflows:
- Database connections use test-specific values
- JWT secrets use test-only values
- No production credentials are exposed

## 🛡️ Branch Protection & Auto-Delete

### Branch Protection Rules

To maximize the effectiveness of these workflows, configure branch protection rules:

**For `main` branch:**
```yaml
# Repository Settings > Branches > Add rule
Branch name pattern: main
✅ Require a pull request before merging
  ✅ Require approvals (1-2 recommended)
  ✅ Dismiss stale PR approvals when new commits are pushed
  ✅ Require review from code owners
✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
  Required status checks:
    - lint-and-format
    - test
    - code-quality (from CI workflow)
    - build (from CI workflow)
✅ Require conversation resolution before merging
✅ Require signed commits (optional, recommended)
✅ Require linear history (optional)
✅ Include administrators (apply rules to admins)
```

**For `staging` branch:**
```yaml
Branch name pattern: staging
✅ Require a pull request before merging
  ✅ Require approvals (1 minimum)
✅ Require status checks to pass before merging
  Required status checks:
    - lint-and-format
    - test
    - code-quality
    - build
```

### Auto-Delete Head Branches

Enable automatic cleanup of merged branches:

**Repository Settings > General > Pull Requests:**
```yaml
✅ Automatically delete head branches
```

**Benefits:**
- Keeps repository clean and organized
- Reduces clutter from merged feature branches
- Prevents confusion about active branches
- Reduces repository size over time

### Workflow Integration with Branch Protection

The workflows are designed to work seamlessly with branch protection:

1. **Status Check Names**: Each workflow job provides a status that can be required
2. **Parallel Execution**: Multiple checks run concurrently for faster feedback
3. **Clear Failure Reasons**: Failed checks show exactly what needs fixing
4. **Retry Capability**: Re-run failed workflows without new commits

### Branch Protection Configuration Commands

Using GitHub CLI to set up branch protection:

```bash
# Protect main branch
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint-and-format","test","code-quality","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null

# Protect staging branch  
gh api repos/:owner/:repo/branches/staging/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint-and-format","test","code-quality"]}' \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null

# Enable auto-delete head branches
gh api repos/:owner/:repo \
  --method PATCH \
  --field delete_branch_on_merge=true
```

## 📝 Best Practices

1. **Always run local checks** before pushing
2. **Read error messages carefully** - they contain fix suggestions
3. **Check coverage reports** to maintain code quality
4. **Review workflow summaries** for detailed status information

## 🚀 Getting Started

1. Merge code to `main`, `staging`, or create a PR
2. Workflows run automatically
3. Check the Actions tab for results
4. Address any issues using the provided fix suggestions
5. Coverage reports are available as artifacts

---

**💡 Pro Tip**: Enable GitHub notifications for workflow failures to stay informed about CI status!