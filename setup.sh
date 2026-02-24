#!/bin/bash
set -e

echo "=== Statvis Dev Setup ==="
echo ""

# ============================================================
# STEP 1: Install Homebrew
# ============================================================
echo "▶ Step 1: Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "  Already installed"
fi

SHELL_CONFIG="$HOME/.zshrc"

# ============================================================
# STEP 2: Install Claude Code
# ============================================================
echo ""
echo "▶ Step 2: Claude Code"
if ! command -v node &>/dev/null; then
  echo "  Installing Node (needed for Claude Code)..."
  brew install node
fi
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
else
  echo "  Already installed"
fi

# ============================================================
# STEP 3: Install mise (runtime version manager)
# ============================================================
echo ""
echo "▶ Step 3: mise"
if ! command -v mise &>/dev/null; then
  brew install mise
fi
if ! grep -q "mise activate" "$SHELL_CONFIG" 2>/dev/null; then
  echo '' >> "$SHELL_CONFIG"
  echo '# mise - runtime version manager' >> "$SHELL_CONFIG"
  echo 'eval "$(mise activate zsh)"' >> "$SHELL_CONFIG"
fi
eval "$(mise activate bash 2>/dev/null || true)"

# ============================================================
# STEP 4: Install Ruby 3.3.2 and Node 20.14.0 via mise
# ============================================================
echo ""
echo "▶ Step 4: Ruby 3.3.2 + Node 20.14.0 (via mise)"
mise install ruby@3.3.2
mise use -g ruby@3.3.2
mise install node@20.14.0
mise use -g node@20.14.0

# ============================================================
# STEP 5: Core tools
# ============================================================
echo ""
echo "▶ Step 5: Core tools"
brew install tmux overmind gh go

# ============================================================
# STEP 6: PostgreSQL 16 (Homebrew, no Docker)
# ============================================================
echo ""
echo "▶ Step 6: PostgreSQL 16"
brew install postgresql@16

PG_PATH="/opt/homebrew/opt/postgresql@16/bin"
if ! grep -q "postgresql@16" "$SHELL_CONFIG" 2>/dev/null; then
  echo '' >> "$SHELL_CONFIG"
  echo '# PostgreSQL 16' >> "$SHELL_CONFIG"
  echo "export PATH=\"$PG_PATH:\$PATH\"" >> "$SHELL_CONFIG"
fi
export PATH="$PG_PATH:$PATH"

brew services start postgresql@16
"$PG_PATH/createuser" -s postgres 2>/dev/null || echo "  postgres user already exists"

brew install postgis

# ============================================================
# STEP 7: Redis
# ============================================================
echo ""
echo "▶ Step 7: Redis"
brew install redis
brew services start redis

# ============================================================
# STEP 8: OpenSearch
# ============================================================
echo ""
echo "▶ Step 8: OpenSearch"
brew tap opensearch-project/tap 2>/dev/null || true
brew install opensearch-project/tap/opensearch
brew services start opensearch-project/tap/opensearch

# ============================================================
# STEP 9: MinIO
# ============================================================
echo ""
echo "▶ Step 9: MinIO"
brew install minio/stable/minio
mkdir -p ~/statvis-dev/minio-data
echo "  MinIO installed. Run manually: minio server ~/statvis-dev/minio-data --console-address :9001"

# ============================================================
# STEP 10: GIS libraries
# ============================================================
echo ""
echo "▶ Step 10: GIS libraries"
brew install geos proj gdal

# ============================================================
# STEP 11: Image/PDF processing
# ============================================================
echo ""
echo "▶ Step 11: Image/PDF processing"
brew install imagemagick poppler vips libyaml

# ============================================================
# STEP 12: Other dependencies
# ============================================================
echo ""
echo "▶ Step 12: Other dependencies"
brew install icu4c rust
brew install --cask chromium

# ============================================================
# STEP 13: Shell environment
# ============================================================
echo ""
echo "▶ Step 13: Shell environment"

# ICU4C (needed for charlock_holmes gem)
if ! grep -q "icu4c" "$SHELL_CONFIG" 2>/dev/null; then
  echo '' >> "$SHELL_CONFIG"
  echo '# ICU4C (charlock_holmes)' >> "$SHELL_CONFIG"
  echo 'export PATH="/opt/homebrew/opt/icu4c/bin:/opt/homebrew/opt/icu4c/sbin:$PATH"' >> "$SHELL_CONFIG"
  echo 'export LDFLAGS="$LDFLAGS -L/opt/homebrew/opt/icu4c/lib"' >> "$SHELL_CONFIG"
  echo 'export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/opt/icu4c/include"' >> "$SHELL_CONFIG"
fi
export PATH="/opt/homebrew/opt/icu4c/bin:/opt/homebrew/opt/icu4c/sbin:$PATH"

# Fork safety (required for Puma + ActiveRecord)
if ! grep -q "OBJC_DISABLE_INITIALIZE_FORK_SAFETY" "$SHELL_CONFIG" 2>/dev/null; then
  echo '' >> "$SHELL_CONFIG"
  echo 'export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES' >> "$SHELL_CONFIG"
fi

# ============================================================
# STEP 14: Clone and set up Statvis
# ============================================================
echo ""
echo "▶ Step 14: Statvis Rails app"

gh auth login

mkdir -p ~/statvis-dev

if [ ! -d ~/statvis-dev/3001 ]; then
  gh repo clone statvis/statvis ~/statvis-dev/3001
else
  echo "  ~/statvis-dev/3001 already exists, skipping clone"
fi

cd ~/statvis-dev/3001

if [ -f .env.local.example ] && [ ! -f .env.local ]; then
  cp .env.local.example .env.local
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^DB_SUFFIX=.*/DB_SUFFIX=_3001/" .env.local
    sed -i '' "s/^PORT=.*/PORT=3001/" .env.local
  else
    sed -i "s/^DB_SUFFIX=.*/DB_SUFFIX=_3001/" .env.local
    sed -i "s/^PORT=.*/PORT=3001/" .env.local
  fi
fi

gem install bundler
bundle install

echo ""
echo "Setting up database..."
if bundle exec rails db:setup; then
  echo "  Database ready!"
else
  echo "  ⚠️  DB setup failed - run 'bundle exec rails db:setup' manually"
fi

# ============================================================
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Restart your terminal, then:"
echo "  cd ~/statvis-dev/3001 && bin/dev"
echo ""
echo "Services running: postgresql@16, redis, opensearch"
echo "MinIO: minio server ~/statvis-dev/minio-data --console-address :9001"
