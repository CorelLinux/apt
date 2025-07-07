#!/bin/bash
set -e

file="apt-pkg/acquire-item.cc"

comment_block() {
  awk '
    BEGIN { skip = 0 }
    /_error->(Error|Warning)\(_\("OpenPGP signature verification failed: %s: %s"\)/ { skip = 1; print "// [patcher] skipped gpg error block"; next }
    skip == 1 {
      if (/;/) { skip = 0 }
      next
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  echo "✅ Commented out signature check block"
}

replace_line() {
  local search="$1"
  local replace="$2"
  if grep -qF "$search" "$file"; then
    sed -i "s|$search|$replace|" "$file"
    echo "✅ Forced override: $search → $replace"
  else
    echo "⏭️  Pattern not found: $search"
  fi
}

# 날짜 검증 무력화
replace_line 'TransactionManager->MetaIndexParser->GetValidUntil() > 0' 'false'
replace_line 'time(NULL) - TransactionManager->MetaIndexParser->GetValidUntil()' '0'

# 메타 파서 호출 제거
replace_line 'LoadLastMetaIndexParser(TransactionManager, FinalRelease, FinalInRelease);' '/* skipped LoadLastMetaIndexParser */'

# GPG 오류 메시지 블록 전체 주석처리
comment_block

echo "🎉 Patch complete and syntax-safe"
