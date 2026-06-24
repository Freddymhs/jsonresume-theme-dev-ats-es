#!/usr/bin/env bash
# Release flow: bump patch, publish to npm (2FA), push tags.
# Usage: ./release.sh <OTP>   (OTP = 6-digit authenticator code or a recovery code)
set -euo pipefail

OTP="${1:-}"
if [ -z "$OTP" ]; then
  echo "ERROR: missing OTP. Usage: ./release.sh <OTP>" >&2
  exit 1
fi

# 1. Tree must be clean (npm version refuses a dirty tree).
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: uncommitted changes. Commit first, then release." >&2
  git status --short
  exit 1
fi

# 2. Bump patch (creates commit + tag).
npm version patch

# 3. Publish with OTP. If it fails, roll back the bump so we don't leave a gap.
if ! npm publish --otp="$OTP"; then
  echo "Publish failed — rolling back version bump." >&2
  git tag -d "v$(node -p "require('./package.json').version")" 2>/dev/null || true
  git reset --hard HEAD~1
  exit 1
fi

# 4. Push commit + tags.
git push --follow-tags

echo "Released v$(node -p "require('./package.json').version") ✅"
