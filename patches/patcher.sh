#!/bin/bash
set -e

patch_block_by_keywords() {
  local file="$1"
  local start_kw="$2"
  local end_kw="$3"
  local found=0

  # 줄 번호 추적
  local total_lines
  total_lines=$(wc -l < "$file")

  for ((i=1; i<=total_lines; i++)); do
    line=$(sed -n "${i}p" "$file")
    echo "$line" | grep -q "$start_kw" || continue

    # 시작 찾음
    start_line=$i
    for ((j=start_line+1; j<=total_lines; j++)); do
      next_line=$(sed -n "${j}p" "$file")
      echo "$next_line" | grep -q "$end_kw" || continue

      end_line=$j

      # 주석 안 된 줄만 주석 처리
      for ((k=start_line; k<=end_line; k++)); do
        target_line=$(sed -n "${k}p" "$file")
        if [[ "$target_line" =~ ^[[:space:]]*// ]]; then
          continue  # 이미 주석이면 스킵
        fi
        sed -i "${k}s|^|//|" "$file"
        echo "Patched in $file: line $k: $(echo "$target_line" | sed 's/^[[:space:]]*//')"
        found=1
      done
      break
    done
    [[ "$found" -eq 1 ]] && break
  done

  if [[ "$found" -eq 0 ]]; then
    echo "No matching block for '$start_kw' ~ '$end_kw' in $file, skipped"
  fi
}

patch_exact_line() {
  local file="$1"
  local pattern="$2"
  local found=0

  while IFS=: read -r lineno content; do
    if [[ "$content" =~ ^[[:space:]]*// ]]; then
      continue
    fi
    sed -i "${lineno}s|^|//|" "$file"
    echo "Patched in $file: line $lineno: $(echo "$content" | sed 's/^[[:space:]]*//')"
    found=1
  done < <(grep -nF "$pattern" "$file" || true)

  if [[ "$found" -eq 0 ]]; then
    echo "No line match for '$pattern' in $file, skipped"
  fi
}

# === 실제 대상들 ===

patch_acquire_item() {
  local file="apt-pkg/acquire-item.cc"
  patch_exact_line "$file" "if (Release.ValidUntil < now)"
  patch_exact_line "$file" "if (Release->ValidUntil < now)"
  patch_block_by_keywords "$file" "ValidUntil" "Stat::StatExpired"
}

patch_index_records() {
  local file="apt-pkg/indexrecords.cc"
  patch_block_by_keywords "$file" "VerifySignature" "throw IndexParseError"
}

patch_debsrcrecords() {
  local file="apt-pkg/deb/debsrcrecords.cc"
  patch_block_by_keywords "$file" "VerifySHA256" "throw BadDebException"
}

patch_acquire_item
patch_index_records
patch_debsrcrecords

echo "✅ All patch attempts complete"
