#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash curl jq

set -euo pipefail

# Fetch the latest version from GitHub releases
LATEST_VERSION=$(curl -s https://api.github.com/repos/instruqt/cli/releases/latest | jq -r .tag_name)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSIONS_FILE="${SCRIPT_DIR}/versions.nix"
SUPPORTED_COMBINATIONS=(
  "x86_64-linux"
  "x86_64-darwin"
  "aarch64-darwin"
)

main() {
  echo "{" > "$VERSIONS_FILE"
  echo "  version = \"${LATEST_VERSION}\";" >> "$VERSIONS_FILE"
  for combo in "${SUPPORTED_COMBINATIONS[@]}"; do
    IFS='-' read -r arch os <<< "$combo"
    download_url=$(constructDownloadURL "$arch" "$os" "$LATEST_VERSION")
    file_hash=$(fetchFileHash "$download_url")
    appendToVersionsFile "$VERSIONS_FILE" "$arch" "$os" "$download_url" "$file_hash"
  done
  echo "}" >> "$VERSIONS_FILE"
}

constructDownloadURL() {
  local architecture="$1"
  local os="$2"
  local version="$3"
  case "$os" in
    linux) echo "https://github.com/instruqt/cli/releases/download/${version}/instruqt-linux.zip" ;;
    darwin)
      case "$architecture" in
        x86_64) echo "https://github.com/instruqt/cli/releases/download/${version}/instruqt-darwin-amd64.zip" ;;
        aarch64) echo "https://github.com/instruqt/cli/releases/download/${version}/instruqt-darwin-arm64.zip" ;;
        *) echo "Unsupported architecture: $architecture" >&2; return 1 ;;
      esac
      ;;
    *) echo "Unsupported operating system: $os" >&2; return 1 ;;
  esac
}

fetchFileHash() {
  local url="$1"
  nix store prefetch-file --json "$url" | jq -r .hash
}

appendToVersionsFile() {
  local file="$1"
  local architecture="$2"
  local operating_system="$3"
  local url="$4"
  local hash="$5"
  cat >> "$file" << EOF

  ${architecture}-${operating_system} = {
    url = "$url";
    hash = "$hash";
  };
EOF
}

main
