#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
source_app="${project_dir}/build/Shadow Sepulcher.app"
install_root="${HCG_INSTALL_ROOT:-${HOME}/Applications}"
installed_app="${install_root}/Shadow Sepulcher.app"

"${script_dir}/build-app.sh" release
codesign --verify --deep --strict "${source_app}"

mkdir -p "${install_root}"
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/hermes-guardian-install.XXXXXX")
trap 'rm -rf -- "${stage_dir}"' EXIT
staged_app="${stage_dir}/Shadow Sepulcher.app"
/usr/bin/ditto "${source_app}" "${staged_app}"
codesign --verify --deep --strict "${staged_app}"

if [[ -e "${installed_app}" ]]; then
    previous_app="${install_root}/Shadow Sepulcher.previous.app"
    if [[ -e "${previous_app}" ]]; then
        rm -rf -- "${previous_app}"
    fi
    mv "${installed_app}" "${previous_app}"
fi

# Builds before the rename installed as "Agent Guardian.app" with the same bundle
# identifier. Move it aside so only one copy registers for launch at login.
legacy_app="${install_root}/Agent Guardian.app"
if [[ -e "${legacy_app}" ]]; then
    legacy_backup="${install_root}/Agent Guardian.previous.app"
    if [[ -e "${legacy_backup}" ]]; then
        rm -rf -- "${legacy_backup}"
    fi
    mv "${legacy_app}" "${legacy_backup}"
fi

mv "${staged_app}" "${installed_app}"
codesign --verify --deep --strict "${installed_app}"

echo "Installed ${installed_app}"
echo "Enable Launch at login from More > App Behavior in Shadow Sepulcher."
