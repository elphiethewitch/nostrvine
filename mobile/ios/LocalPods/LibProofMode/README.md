# LibProofMode

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

The library has a minimum system requirement of iOS 15.

## Installation

LibProofMode is available through [CocoaPods](https://cocoapods.org). To install
it, add the following to your Podfile:

```ruby
target 'YourApp' do
    pod 'LibProofMode'
end

target 'YourShareExtension' do
    pod 'LibProofMode'
end
```

## Usage

The proof generation code works with the `MediaItem` class, which can be constructed using a `PHAsset`, a `URL` or a `Data` blob. Once constructed, you
feed this item to `Proof.shared.process` to generate all the proof files for it. In this call, you also send a `ProofGenerationOptions` parameter that
controls what data (in addition to all default values) to include in the proof, i.e. device ID, location data and network information.

When proof is generated, default keys (stored in users document directory) are used. You can override this by providing your own set of keys
by calling `Proof.shared.initializeWithKeys()` before any calls to `Proof.shared.process`.

Proof will by default be generated in the users documents directory, under a subfolder named by the hash of the media. If you want to save
proof to another location, you can provide the URL of an (existing!) folder in `MediaItem.proofFolder`.

If you want to leave out device identifier support (via the AdSupport.getDeviceIdentifier() api, you can consume the pod via subspec "NoAdSupport", so in your Podfile:

```ruby
target 'YourApp' do
    pod 'LibProofMode/NoAdSupport'
end
```

## Notarization providers

In the `ProofGenerationOptions` struct you can optionally provide an array of `NotarizationProviders` (that you implement). They take the media data and apply
your custom logic to that, returning an arbitrary string when done.

## Environment

You may create an issue in our bugtracker, or better send a pull request at https://gitlab.com/guardianproject/proofmode/libproofmode-ios.

Here is a (maybe outdated, non-complete) list of things you inherit, should you decide to depend on LibProofMode:

- CocoaPods from LibProofMode
  - ObjectivePGP
  - DeviceKit

## Author

Guardian Project

## License

LibProofMode is available under the Apache License, Version 2.0. See the LICENSE file for more info.
