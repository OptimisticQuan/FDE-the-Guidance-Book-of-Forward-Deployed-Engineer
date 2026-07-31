#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if (($# > 0)); then
  output_path="$1"
else
  timestamp="$(date '+%Y%m%d%H%M')"
  output_path="${repo_root}/dist/FDE（前沿部署工程师）从零入门指南-范冰-${timestamp}.epub"
fi

for command_name in pandoc pdftoppm; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf '缺少构建依赖：%s\n' "${command_name}" >&2
    printf 'macOS 可运行：brew install pandoc poppler\n' >&2
    exit 127
  fi
done

shopt -s nullglob
chapters=("${repo_root}"/[0-9][0-9]-*.md)
shopt -u nullglob

if ((${#chapters[@]} == 0)); then
  printf '未找到章节文件：%s/[0-9][0-9]-*.md\n' "${repo_root}" >&2
  exit 1
fi

cover_source="${repo_root}/前线部署工程师.pdf"
if [[ ! -f "${cover_source}" ]]; then
  printf '未找到封面来源：%s\n' "${cover_source}" >&2
  exit 1
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fde-epub.XXXXXX")"
trap 'rm -rf -- "${temp_dir}"' EXIT

# PDF 首页是本书封面；构建时提取可避免维护另一份易过期的封面源文件。
pdftoppm \
  -f 1 \
  -singlefile \
  -png \
  -r 144 \
  "${cover_source}" \
  "${temp_dir}/cover" >/dev/null

mkdir -p -- "$(dirname -- "${output_path}")"

pandoc \
  --from=gfm \
  --to=epub3 \
  --output="${output_path}" \
  --data-dir="${repo_root}/epub" \
  --metadata-file="${repo_root}/epub/metadata.yaml" \
  --css="${repo_root}/epub/epub.css" \
  --epub-cover-image="${temp_dir}/cover.png" \
  --toc \
  --toc-depth=2 \
  "${chapters[@]}"

printf 'EPUB 已生成：%s\n' "${output_path}"
