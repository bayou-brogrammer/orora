#!/bin/bash

install_packages() {
  PACKAGE_LIST=$1

  # build list of all packages requested for inclusion
  mapfile -t INCLUDED_PACKAGES < <(yq -r "[(.all.include | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[]), \
  (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[])] \
  | sort | unique[]" /tmp/packages.yml)

  # build list of all packages requested for exclusion
  mapfile -t EXCLUDED_PACKAGES < <(yq -r ".all.exclude | sort | unique[]" /tmp/packages.yml)

  # ensure exclusion list only contains packages already present on image
  if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    mapfile -t EXCLUDED_PACKAGES < <(rpm -qa --queryformat='%{NAME} ' "${EXCLUDED_PACKAGES[@]}")
  fi

  # simple case to install where no packages need excluding
  if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
    rpm-ostree install \
      "${INCLUDED_PACKAGES[@]}"

  # install/excluded packages both at same time
  elif [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
      "${EXCLUDED_PACKAGES[@]}" \
      "$(printf -- "--install=%s " "${INCLUDED_PACKAGES[@]}")"

  else
    echo "No packages to install."

  fi

  # check if any excluded packages are still present
  # (this can happen if an included package pulls in a dependency)
  mapfile -t EXCLUDED_PACKAGES < <(jq -r ".all.exclude | sort | unique[]" /tmp/packages.yml)

  if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    mapfile -t EXCLUDED_PACKAGES < <(rpm -qa --queryformat='%{NAME} ' "${EXCLUDED_PACKAGES[@]}")
  fi

  # remove any exluded packages which are still present on image
  if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
      "${EXCLUDED_PACKAGES[@]}"
  fi
}

PACKAGE_LISTS=(
  "orora"
  "orora-dx"
)

for PACKAGE_LIST in "${PACKAGE_LISTS[@]}"; do
  install_packages "$PACKAGE_LIST"
done
