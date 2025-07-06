#!/bin/bash
set -e

patch_acquire_item() {
  local file="apt-pkg/acquire-item.cc"
  if grep -q 'if (Release.ValidUntil < now)' "$file"; then
    sed -i '/if (Release.ValidUntil < now)/,/}/ s/^/\/\//' "$file"
    echo "Patched ValidUntil check in $file"
  else
    echo "No ValidUntil check found in $file, skipped"
  fi
}

patch_index_records() {
  local file="apt-pkg/indexrecords.cc"
  if grep -q 'throw IndexParseError' "$file"; then
    sed -i '/if (!Record.VerifySignature/,/throw IndexParseError/ s/^/\/\//' "$file"
    echo "Patched signature verification in $file"
  else
    echo "No signature verification found in $file, skipped"
  fi
}

patch_debsrcrecords() {
  local file="apt-pkg/deb/debsrcrecords.cc"
  if grep -q 'throw BadDebException' "$file"; then
    sed -i '/if (!VerifySHA256/,/throw BadDebException/ s/^/\/\//' "$file"
    echo "Patched SHA256 verification in $file"
  else
    echo "No SHA256 verification found in $file, skipped"
  fi
}

patch_acquire_item
patch_index_records
patch_debsrcrecords

echo "All patches applied (or skipped if not found)"
