#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$MACOS_KEYS" --output ./.github/secrets/6ed47842-6809-48e3-9d0a-dec963c510ef.MacTeamProvisioningProfiledurin.MediaUploader.provisionprofile ./.github/secrets/6ed47842-6809-48e3-9d0a-dec963c510ef.MacTeamProvisioningProfiledurin.MediaUploader.provisionprofile.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$MACOS_KEYS" --output ./.github/secrets/Certificates.p12 ./.github/secrets/Certificates.p12.gpg

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp ./.github/secrets/6ed47842-6809-48e3-9d0a-dec963c510ef.MacTeamProvisioningProfiledurin.MediaUploader.provisionprofile ~/Library/MobileDevice/Provisioning\ Profiles/6ed47842-6809-48e3-9d0a-dec963c510ef.MacTeamProvisioningProfiledurin.MediaUploader.provisionprofile


security create-keychain -p "" build.keychain
security import ./.github/secrets/Certificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain
