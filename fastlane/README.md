fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios validate_metadata

```sh
[bundle exec] fastlane ios validate_metadata
```

Validate App Store metadata

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture store screenshots in every app language and frame them into fastlane/screenshots

Uses the iPhone 17 Pro Max and iPad Pro 13-inch (M5) Simulators, and Google Chrome for the captions

Options: locales:de-DE,th devices:iphone,ipad

### ios frame

```sh
[bundle exec] fastlane ios frame
```

Frame the raw captures in fastlane/framing and add their captions, into fastlane/screenshots

The captions and layout are framing/template.html, rendered by headless Chrome

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Upload metadata and screenshots to App Store Connect, without a build or review submission

Needs an App Store Connect API key in fastlane/app_store_connect_api_key.json

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
