# webp

[![webp pub.dev badge][pub-badge]][pub-badge-link]
[![][build-badge]][build-badge-link]

Asset transformer for converting images into WebP files.

## Install package

```
flutter pub add webp
```

## Package usage

Add to your `pubspec.yaml`.

### Default usage

If run without additional arguments, the default value of the quality parameter = 75 with lossy compression will be used.

```yaml
flutter:
  assets:
    - path: assets/logo.jpg
      transformers:
        - package: webp
```

### Usage with params

```yaml
flutter:
  assets:
    - path: assets/logo.jpg
      transformers:
        - package: webp
          args: ['--quality=65', '--hint=graph', '--af']
```

By default, the package runs the embedded precompiled cwebp binary. You can use the one specified in your `$PATH` by adding the `--from_path` flag.

```yaml
flutter:
  assets:
    - path: assets/logo.jpg
      transformers:
        - package: webp
          args: ['--from_path']
```

## cwebp parameters

Here are some commonly used parameters for cwebp:

- `-q`, `--quality`: Set the quality factor for the output image. The value should be between 0 and 100, with 100 being the highest quality. For example, `--quality=80`.
- `--lossless`: Encode the image without any loss. For images with fully transparent area, the invisible pixel values (R/G/B or Y/U/V) will be preserved only if the `--exact` option is used..
- `-m`, `--method`: Set the compression method. The value can be `0` (fastest), `1` (default), `2` (slowest), or `3` (best quality). For example, `--method=2`.
- `-f`, `--filter`: Set the filter strength. The value can be between 0 and 100, with 0 being no filtering and 100 being maximum filtering. For example, `--filter=50`.
- `-s`, `--size`: Set the target size for the output image. The value should be in bytes. For example, `--size=500000`.

For a complete list of parameters and their descriptions, please refer to the [cwebp documentation](https://developers.google.com/speed/webp/docs/cwebp).

## Supported architectures

The package provides cwebp binaries for the following architectures:
- windows-x64,
- macos-x64,
- macos-arm64,
- linux-x64,
- linux-arm64.

Note: You can still use the package on other architectures with cwebp from your `$PATH`.

## Learn more
- [Asset transformers in Flutter](https://docs.flutter.dev/ui/assets/asset-transformation)

---

<p align="center">
   <a href="https://leancode.co/?utm_source=readme&utm_medium=bloc_lens_package">
      <img alt="LeanCode" src="https://leancodepublic.blob.core.windows.net/public/wide.png" width="300"/>
   </a>
   <p align="center">
   Built with ☕️ by <a href="https://leancode.co/?utm_source=readme&utm_medium=bloc_lens_package">LeanCode</a>
   </p>
</p>

[pub-badge]: https://img.shields.io/pub/v/webp
[pub-badge-link]: https://pub.dev/packages/webp
[build-badge]: https://img.shields.io/github/actions/workflow/status/leancodepl/flutter_webp/check.yml
[build-badge-link]: https://github.com/leancodepl/flutter_webp/actions/workflows/check.yml