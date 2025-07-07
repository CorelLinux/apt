#!/bin/bash
set -e

file="apt-pkg/acquire-item.cc"

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

# GPG 오류 메시지 제거 (더 안전하게 전체 줄 주석처리)
comment_line_contains() {
  local pattern="$1"
  if grep -qF "$pattern" "$file"; then
    sed -i "/$pattern/ s|^|// |" "$file"
    echo "✏️ Commented out line containing: $pattern"
  else
    echo "⏭️  Pattern not found: $pattern"
  fi
}

comment_line_contains 'OpenPGP signature verification failed'

# 메타 파서 호출 제거 (함수만 대체)
replace_line 'LoadLastMetaIndexParser(TransactionManager, FinalRelease, FinalInRelease);' '/* skipped LoadLastMetaIndexParser */'

echo "🎉 Patch complete via override+safe-comment method"
