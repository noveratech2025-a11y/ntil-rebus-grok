# GitHub Setup Guide - NTIL REBUS-GROK

## 🚀 Quick Setup

### 1. Create GitHub Repository

```bash
# Initialize git in your project
cd ntil-rebus-grok
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: NTIL REBUS-GROK v5.0.0"

# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/ntil-rebus-grok.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 2. Enable GitHub Packages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **General**
3. Under "Workflow permissions", select:
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### 3. Repository Secrets (Optional)

For deployment, you may need to add secrets:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:
   - `GROK_API_KEY` - Your xAI Grok API key
   - `KUBE_CONFIG` - Kubernetes config for deployment (if using K8s)
   - `DB_PASSWORD` - Database password for production

### 4. Branch Protection (Recommended)

Protect your main branch:

1. Go to **Settings** → **Branches**
2. Click **Add branch protection rule**
3. Branch name pattern: `main`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging

---

## 📦 Image Registry

Your images will be available at:

```
ghcr.io/YOUR_USERNAME/ntil-rebus-grok/backend:latest
ghcr.io/YOUR_USERNAME/ntil-rebus-grok/frontend:latest
```

### Pull Images

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull backend
docker pull ghcr.io/YOUR_USERNAME/ntil-rebus-grok/backend:latest

# Pull frontend
docker pull ghcr.io/YOUR_USERNAME/ntil-rebus-grok/frontend:latest
```

---

## 🔄 Workflow Triggers

The workflow runs on:

- **Push to main/develop**: Full build and push
- **Pull requests**: Build and test only (no push)
- **Version tags** (`v*`): Build, push, and deploy to production
- **Manual trigger**: Via GitHub Actions UI

### Create a Release

```bash
# Tag a version
git tag -a v5.0.0 -m "Release v5.0.0"
git push origin v5.0.0

# This triggers production deployment
```

---

## ✅ Verification Checklist

- [ ] Repository created on GitHub
- [ ] Workflow file added to `.github/workflows/`
- [ ] GitHub Actions enabled with write permissions
- [ ] First commit pushed successfully
- [ ] Workflow ran and completed successfully
- [ ] Docker images visible in Packages tab
- [ ] Branch protection rules configured
- [ ] Secrets added (if needed)
