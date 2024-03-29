
# This stage is responsible for holding onto
# your config without copying it directly into
# the final image
FROM scratch as stage-config
COPY ./config /config

# Copy modules
# The default modules are inside blue-build/modules
# Custom modules overwrite defaults
FROM scratch as stage-modules
COPY --from=ghcr.io/blue-build/modules:latest /modules /modules
COPY ./modules /modules
FROM scratch as stage-akmods-asus
COPY --from=ghcr.io/ublue-os/akmods:asus-39 /rpms /rpms

# This stage is responsible for holding onto
# exports like the exports.sh
FROM docker.io/alpine as stage-exports
RUN printf "#!/usr/bin/env bash\n\nget_yaml_array() { \n  readarray -t \"\$1\" < <(echo \"\$3\" | yq -I=0 \"\$2\")\n} \n\nexport -f get_yaml_array\nexport OS_VERSION=\$(grep -Po '(?<=VERSION_ID=)\d+' /usr/lib/os-release)" >> /exports.sh && chmod +x /exports.sh

FROM ghcr.io/ublue-os/bluefin-dx-asus:latest

LABEL org.blue-build.build-id="5b9add58-004c-415c-ba28-06cb09a1ad88"
LABEL org.opencontainers.image.title="orora"
LABEL org.opencontainers.image.description="This is my personal OS image."
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG RECIPE=./config/recipe.yml
ARG IMAGE_REGISTRY=localhost
COPY cosign.pub /usr/share/ublue-os/cosign.pub

ARG CONFIG_DIRECTORY="/tmp/config"
ARG IMAGE_NAME="orora"
ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx-asus"

COPY --from=gcr.io/projectsigstore/cosign /ko-app/cosign /usr/bin/cosign
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/blue-build/cli:latest-installer /out/bluebuild /usr/bin/bluebuild

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY ./system_files /
# Copy Bluefin CLI packages
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/delta /usr/bin/delta
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/eza /usr/bin/eza
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/fd /usr/bin/fd
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/fzf /usr/bin/fzf
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/rg /usr/bin/rg
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/zoxide /usr/bin/zoxide
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/share/bash-prexec /usr/share/bash-prexec

RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh && /tmp/modules/script/script.sh '{"type":"script","scripts":["base/generate-image-info.sh"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-akmods-asus,src=/rpms,dst=/tmp/rpms,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/akmods/akmods.sh \
  && source /tmp/exports.sh && /tmp/modules/akmods/akmods.sh '{"type":"akmods","base":"asus","install":["ryzen-smu","zenergy"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","repos":["https://copr.fedorainfracloud.org/coprs/varlad/helix/repo/fedora-%OS_VERSION%/varlad-helix-fedora-%OS_VERSION%.repo","https://copr.fedorainfracloud.org/coprs/agriffis/neovim-nightly/repo/fedora-%OS_VERSION%/agriffis-neovim-nightly-fedora-%OS_VERSION%.repo"],"install":["cargo","helix","neovim","rust","rofi-wayland","xorg-x11-server-Xwayland","polkit","lxpolkit","xdg-user-dirs","dbus-tools","dbus-daemon","wl-clipboard","gnome-keyring","pavucontrol","playerctl","qt5-qtwayland","qt6-qtwayland","vulkan-validation-layers","vulkan-tools","google-noto-emoji-fonts","gnome-disk-utility","wireplumber","pipewire","pamixer","network-manager-applet","NetworkManager-openvpn","NetworkManager-openconnect","bluez","bluez-tools","blueman","thunar","thunar-archive-plugin","thunar-volman","xarchiver","imv","p7zip","unrar-free","slurp","grim","wlr-randr","wlsunset","grimshot","brightnessctl","swaylock","swayidle","kanshi","foot","dunst","mpv","adwaita-qt5","fontawesome-fonts-all","gnome-themes-extra","gnome-icon-theme","paper-icon-theme","breeze-icon-theme","papirus-icon-theme"],"remove":null}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/bling/bling.sh \
  && source /tmp/exports.sh && /tmp/modules/bling/bling.sh '{"type":"bling","install":["1password","flatpaksync"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","install":["sddm","sddm-themes"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","install":["hyprland","waybar","xdg-desktop-portal-hyprland","brightnessctl"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh && /tmp/modules/script/script.sh '{"type":"script","scripts":["base/software.sh","base/just.sh","sddm/settheming.sh","sddm/setsddmtheming.sh"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh && /tmp/modules/script/script.sh '{"type":"script","scripts":["hyprland/removeunprofessionalwallpapers.sh"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/signing/signing.sh \
  && source /tmp/exports.sh && /tmp/modules/signing/signing.sh '{"type":"signing"}' \
  && ostree container commit



# Added in case a user adds something else using the
# 'containerfile' module
RUN rm -fr /tmp/* /var/* && ostree container commit