# Open Look Away

A free, open-source Mac menu-bar break reminder. Calm by default. Beast Mode is optional honor-system push-ups.

```sh
curl -fsSL https://raw.githubusercontent.com/yoelgal/open-look-away/main/install.sh | bash
```

That downloads the latest release, checks it against its published checksum, installs the app, and opens it. Re-run it any time to update.

It needs macOS 13 or later on Apple Silicon. The app is not notarized. `curl` does not quarantine the download, so Gatekeeper does not block it.

To pin a release:

```sh
curl -fsSL https://raw.githubusercontent.com/yoelgal/open-look-away/main/install.sh | OLA_VERSION=v1.0.0 bash
```

To build from source:

```sh
git clone https://github.com/yoelgal/open-look-away.git && cd open-look-away && ./install.sh --from-source
```

```sh
./scripts/build-app.sh
./scripts/package-release.sh
```

MIT. See [LICENSE](LICENSE).
