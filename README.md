# Ōrora (オーロラ)

<div align="center" width="50%">
  <img alt="orora" src="assets/4-design/variant5.png">

[Ōrora (オーロラ)](https://www.nihongomaster.com/japanese/dictionary/word/3106/o%E3%83%BCrora-%E3%82%AA%E3%83%BC%E3%83%AD%E3%83%A9) is an opinionated custom-built operating system developed on the solid foundation of Universal Blue (Ublue). Embark on a Cosmic Computing Odyssey with Ōrora: Your Imagination in the Universe of Operating Systems

</div>

<div align="center">

[![Deploy Ōrora](https://github.com/bayou-brogrammer/orora/actions/workflows/deploy.yml/badge.svg)](https://github.com/bayou-brogrammer/orora/actions/workflows/deploy.yml)
[![Ōrora Iso Release](https://github.com/bayou-brogrammer/orora/actions/workflows/build_iso.yml/badge.svg?branch=live)](https://github.com/bayou-brogrammer/orora/actions/workflows/build_iso.yml)

</div>

## Installation

Images that can be rebased:

- [Silverblue](https://fedoraproject.org/silverblue/)
- [Kinoite](https://fedoraproject.org/kinoite/)
- [Sericea](https://fedoraproject.org/sericea/)
- [Onyx](https://fedoraproject.org/onyx/)
- [Any UBlue OS Image](https://universal-blue.org/images/)
- [Any rpm-ostree Based Image](https://coreos.github.io/rpm-ostree/)

---

> [!CAUTION]
> It is recommended to pin your current deployment before rebasing onto another.
> sudo ostree admin pin 0

- First rebase to the unsigned image, to get the proper signing keys and policies installed:

  ```sh
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/bayou-brogrammer/orora-asus:latest --reboot
  ```

- Then rebase to the signed image, like so:

  ```sh
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bayou-brogrammer/orora-asus:latest --reboot
  ```

- This repository builds date tags as well, so if you want to rebase to a particular day's build:

  ```sh
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bayou-brogrammer/orora-asus:20230403
  ```

## Signing

This repository by default also supports signing.
The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version
specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## Collaborators

<!-- readme: collaborators -start -->
<!-- readme: collaborators -end -->

## Contributors

<!-- readme: contributors -start -->
<!-- readme: contributors -end -->