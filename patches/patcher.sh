#!/bin/bash
set -e

patch_line_by_keyword() {
  local file="$1"
  local keyword="$2"
  local found=0

  grep -n "$keyword" "$file" | while IFS=: read -r lineno line; do
    if [[ ! "$line" =~ ^[[:space:]]*// ]]; then
      sed -i "${lineno}s|^|//|" "$file"
      echo "Patched in $file: line $lineno: $(echo "$line" | sed 's/^[[:space:]]*//')"
      found=1
    fi
  done

  [[ "$found" -eq 0 ]] && echo "No match or already patched for '$keyword' in $file"
}

patch_block_near_keyword() {
  local file="$1"
  local keyword="$2"
  local context=2
  local found=0

  grep -n "$keyword" "$file" | while IFS=: read -r lineno line; do
    start=$((lineno - context))
    end=$((lineno + context))

    [[ $start -lt 1 ]] && start=1

    for ((i=start; i<=end; i++)); do
      original_line=$(sed -n "${i}p" "$file")
      if [[ ! "$original_line" =~ ^[[:space:]]*// ]]; then
        sed -i "${i}s|^|//|" "$file"
        echo "Patched in $file: line $i: $(echo "$original_line" | sed 's/^[[:space:]]*//')"
        found=1
      fi
    done
  done

  [[ "$found" -eq 0 ]] && echo "No nearby block found for '$keyword' in $file"
}

patch_acquire_item() {
  local file="apt-pkg/acquire-item.cc"
  echo "Patching $file..."

  # 날짜 무시
  patch_line_by_keyword "$file" "GetValidUntil"

  # GPG 관련 로그 제거
  patch_block_near_keyword "$file" "OpenPGP"
  patch_block_near_keyword "$file" "Release.gpg"
  patch_block_near_keyword "$file" "_error->Error"
  patch_block_near_keyword "$file" "_error->Warning"
  patch_block_near_keyword "$file" "signature verification"

  # 그 외 의미 있는 주석
  patch_line_by_keyword "$file" "FinalReleasegpg"
  patch_line_by_keyword "$file" "MetaIndexParser"
}

patch_acquire_item

echo "✅ All patches complete"
