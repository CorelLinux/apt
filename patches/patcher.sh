#!/bin/bash
set -e

patch_file_with_patterns() {
  local file="$1"
  shift
  local patched=0

  for pattern in "$@"; do
    # grep으로 패턴 찾고 라인번호 추출
    local lines
    lines=$(grep -n -F "$pattern" "$file" || true)

    if [[ -n "$lines" ]]; then
      while IFS= read -r line; do
        local lineno="${line%%:*}"
        local code="${line#*:}"

        # 해당 라인만 주석 처리
        sed -i "${lineno}s/^/\/\//" "$file"
        echo "Patched \"$code\" in line $lineno of $file"
        patched=1
      done <<< "$lines"
    fi
  done

  if [[ "$patched" -eq 0 ]]; then
    echo "No matching patterns found in $file, skipped"
  fi
}

patch_acquire_item() {
  local file="apt-pkg/acquire-item.cc"
  patch_file_with_patterns "$file" \
    "if (Release.ValidUntil < now)" \
    "if (Header.ValidUntil < now)" \
    "if (Release->ValidUntil < now)"
}

patch_index_records() {
  local file="apt-pkg/indexrecords.cc"
  patch_file_with_patterns "$file" \
    "throw IndexParseError"
}

patch_debsrcrecords() {
  local file="apt-pkg/deb/debsrcrecords.cc"
  patch_file_with_patterns "$file" \
    "throw BadDebException"
}

patch_acquire_item
patch_index_records
patch_debsrcrecords

echo "All patches applied (or skipped if not found)"
