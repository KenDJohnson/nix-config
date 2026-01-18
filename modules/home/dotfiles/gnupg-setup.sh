#!/usr/bin/env sh

export GNUPGHOME="$(mktemp -d)"

cat >keybatch <<'EOF'
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: certify
Expire-Date: 0
Name-Real: Ken Johnson
Name-Email: ken.johnso93@gmail.com
%commit
EOF

gpg --batch --full-generate-key keybatch
rm keybatch
