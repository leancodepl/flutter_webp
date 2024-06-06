# webp

Asset transformer for converting images into WebP files.

## Install cwebp
### Option 1: Download precompiled binaries from Google

Follow the instructions at [https://developers.google.com/speed/webp/docs/precompiled](https://developers.google.com/speed/webp/docs/precompiled) to download and install the precompiled binaries for cwebp.

### Option 2: Install using Homebrew (macOS)

If you are using macOS and have Homebrew installed, you can install cwebp using the following command: `brew install webp`

## Package usage

Add to your pubspec.yaml

#### Default usage

If run without additional arguments, the default value of the quality parameter = 75 will be used.

```yaml
flutter:
  assets:
    - path: assets/logo.jpg
      transformers:
        - package: webp
```

#### Usage with params

```yaml
flutter:
  assets:
    - path: assets/logo.jpg
      transformers:
        - package: webp
          args: ['--quality=65', '--hint=graph', '--af']
```

## cwebp parameters

Here are some commonly used parameters for cwebp:

- `-q`, `--quality`: Set the quality factor for the output image. The value should be between 0 and 100, with 100 being the highest quality. For example, `--quality=80`.
- `loseless`: Encode the image without any loss. For images with fully transparent area, the invisible pixel values (R/G/B or Y/U/V) will be preserved only if the `--exact` option is used..
- `-m`, `--method`: Set the compression method. The value can be `0` (fastest), `1` (default), `2` (slowest), or `3` (best quality). For example, `--method=2`.
- `-f`, `--filter`: Set the filter strength. The value can be between 0 and 100, with 0 being no filtering and 100 being maximum filtering. For example, `--filter=50`.
- `-s`, `--size`: Set the target size for the output image. The value should be in bytes. For example, `--size=500000`.

For a complete list of parameters and their descriptions, please refer to the [cwebp documentation](https://developers.google.com/speed/webp/docs/cwebp).