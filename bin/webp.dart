import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:args/args.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// All cwebp options are listed: https://developers.google.com/speed/webp/docs/cwebp

const _version = '1.0.0';

const _architectures = {
  Abi.windowsX64: 'windows-x64',
  Abi.macosX64: 'mac-x86-64',
  Abi.macosArm64: 'mac-arm64',
  Abi.linuxX64: 'linux-x86-64',
  Abi.linuxArm64: 'linux-aarch64',
};

ArgParser _buildParser() {
  return ArgParser()

    /// Basic Options
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'log this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'log the tool version.',
    )
    ..addOption(
      'input',
      mandatory: true,
      abbr: 'i',
      help: 'Input image file.',
    )
    ..addOption(
      'output',
      mandatory: true,
      abbr: 'o',
      help: 'Output WebP file.',
    )
    ..addFlag(
      'architectures',
      negatable: false,
      help: 'List supported architectures',
    )
    ..addFlag(
      'from_path',
      negatable: false,
      help: r'Use a cwebp converter from the $PATH.',
    )
    ..addFlag(
      'lossless',
      help:
          'Encode the image without any loss. For images with fully transparent area, the invisible pixel values (R/G/B or Y/U/V) will be preserved only if the -exact option is used.',
    )
    ..addOption(
      'near_lossless',
      help:
          'Specify the level of near-lossless image preprocessing. This option adjusts pixel values to help compressibility, but has minimal impact on the visual quality. It triggers lossless compression mode automatically. The range is 0 (maximum preprocessing) to 100 (no preprocessing, the default). The typical value is around 60. Note that lossy with -q 100 can at times yield better results.',
    )
    ..addOption(
      'quality',
      abbr: 'q',
      help:
          'Specify the compression factor for RGB channels between 0 and 100. The default is 75.'
          'In case of lossy compression (default), a small factor produces a smaller file with lower quality. Best quality is achieved by using a value of 100.'
          'In case of lossless compression (specified by the -lossless option), a small factor enables faster compression speed, but produces a larger file. Maximum compression is achieved by using a value of 100.',
    )
    ..addOption(
      'lossless_compression',
      abbr: 'z',
      help:
          'Switch on lossless compression mode with the specified level between 0 and 9.',
    )
    ..addOption(
      'alpha_q',
      help:
          'Specify the compression factor for alpha compression between 0 and 100. Lossless compression of alpha is achieved using a value of 100, while the lower values result in a lossy compression. The default is 100.',
    )
    ..addOption(
      'preset',
      abbr: 'p',
      help:
          'Specify a set of pre-defined parameters to suit a particular type of source material. Possible values are: default, photo, picture, drawing, icon, text.',
    )
    ..addOption(
      'm',
      abbr: 'm',
      help:
          'Specify the compression method to use. This parameter controls the trade off between encoding speed and the compressed file size and quality. Possible values range from 0 to 6. Default value is 4. When higher values are used, the encoder will spend more time inspecting additional encoding possibilities and decide on the quality gain. Lower value can result in faster processing time at the expense of larger file size and lower compression quality.',
    )
    ..addOption(
      'crop',
      abbr: 'c',
      help:
          'Crop the source to a rectangle with top-left corner at coordinates (x_position, y_position) and size width x height. This cropping area must be fully contained within the source rectangle. Note: the cropping is applied before any scaling.',
    )
    ..addOption(
      'resize',
      abbr: 'r',
      help:
          'Resize the source to a rectangle with size width x height. If either (but not both) of the width or height parameters is 0, the value will be calculated preserving the aspect-ratio. Note: scaling is applied after cropping.',
    )
    ..addFlag(
      'mt',
      help: 'Use multi-threading for encoding, if possible.',
    )
    ..addFlag(
      'low_memory',
      help:
          'Reduce memory usage of lossy encoding by saving four times the compressed size (typically). This will make the encoding slower and the output slightly different in size and distortion. This flag is only effective for methods 3 and up, and is off by default. Note that leaving this flag off will have some side effects on the bitstream: it forces certain bitstream features like number of partitions (forced to 1). Note that a more detailed report of bitstream size is loged by cwebp when using this option.',
    )

    /// Lossy Options
    /// These options are only effective when doing lossy encoding (the default, with or without alpha).
    ..addOption(
      'size',
      help:
          'Specify a target size (in bytes) to try and reach for the compressed output. The compressor will make several passes of partial encoding in order to get as close as possible to this target. If both -size and -psnr are used, -size value will prevail.',
    )
    ..addOption(
      'psnr',
      help:
          'Specify a target PSNR (in dB) to try and reach for the compressed output. The compressor will make several passes of partial encoding in order to get as close as possible to this target. If both -size and -psnr are used, -size value will prevail.',
    )
    ..addOption(
      'pass',
      help:
          "Set a maximum number of passes to use during the dichotomy used by options -size or -psnr. Maximum value is 10, default is 1. If options -size or -psnr were used, but -pass wasn't specified, a default value of '6' passes will be used. If -pass is specified, but neither -size nor -psnr are, a target PSNR of 40dB will be used.",
    )
    ..addFlag(
      'af',
      help:
          'Turns auto-filter on. This algorithm will spend additional time optimizing the filtering strength to reach a well-balanced quality.',
    )
    ..addFlag(
      'jpeg_like',
      help:
          'Change the internal parameter mapping to better match the expected size of JPEG compression. This flag will generally produce an output file of similar size to its JPEG equivalent (for the same -q setting), but with less visual distortion.',
    )

    /// Lossy advanced options
    ..addOption(
      'f',
      abbr: 'f',
      help:
          'Specify the strength of the deblocking filter, between 0 (no filtering) and 100 (maximum filtering). A value of 0 will turn off any filtering. Higher value will increase the strength of the filtering process applied after decoding the picture. The higher the value the smoother the picture will appear. Typical values are usually in the range of 20 to 50.',
    )
    ..addOption(
      'sharpness',
      help:
          'Specify the sharpness of the filtering (if used). Range is 0 (sharpest) to 7 (least sharp). Default is 0.',
    )
    ..addFlag(
      'strong',
      help:
          'Use strong filtering (if filtering is being used thanks to the -f option). Strong filtering is on by default.',
    )
    ..addFlag(
      'nostrong',
      help:
          'Disable strong filtering (if filtering is being used thanks to the -f option) and use simple filtering instead.',
    )
    ..addFlag(
      'sharp_yuv',
      help:
          "Use more accurate and sharper RGB->YUV conversion if needed. Note that this process is slower than the default 'fast' RGB->YUV conversion.",
    )
    ..addOption(
      'sns',
      help:
          'Specify the amplitude of the spatial noise shaping. Spatial noise shaping (or sns for short) refers to a general collection of built-in algorithms used to decide which area of the picture should use relatively less bits, and where else to better transfer these bits. The possible range goes from 0 (algorithm is off) to 100 (the maximal effect). The default value is 50.',
    )
    ..addOption(
      'segments',
      help:
          'Change the number of partitions to use during the segmentation of the sns algorithm. Segments should be in range 1 to 4. Default value is 4. This option has no effect for methods 3 and up, unless -low_memory is used.',
    )
    ..addOption(
      'partition_limit',
      help:
          "Degrade quality by limiting the number of bits used by some macroblocks. Range is 0 (no degradation, the default) to 100 (full degradation). Useful values are usually around 30-70 for moderately large images. In the VP8 format, the so-called control partition has a limit of 512k and is used to store the following information: whether the macroblock is skipped, which segment it belongs to, whether it is coded as intra 4x4 or intra 16x16 mode, and finally the prediction modes to use for each of the sub-blocks. For a very large image, 512k only leaves room for a few bits per 16x16 macroblock. The absolute minimum is 4 bits per macroblock. Skip, segment, and mode information can use up almost all these 4 bits (although the case is unlikely), which is problematic for very large images. The partition_limit factor controls how frequently the most bit-costly mode (intra 4x4) will be used. This is useful in case the 512k limit is reached and the following message is displayed: Error code: 6 (PARTITION0_OVERFLOW: Partition #0 is too big to fit 512k). If using -partition_limit is not enough to meet the 512k constraint, one should use less segments in order to save more header bits per macroblock. See the -segments option. Note the -m and -q options also influence the encoder's decisions and ability to hit this limit.",
    )

    /// Additional Options
    ..addOption(
      's',
      abbr: 's',
      help:
          "Specify that the input file actually consists of raw Y'CbCr samples following the ITU-R BT.601 recommendation, in 4:2:0 linear format. The luma plane has size width x height.",
    )
    ..addOption(
      'pre',
      help:
          'Specify some pre-processing steps. Using a value of 2 will trigger quality-dependent pseudo-random dithering during RGBA->YUVA conversion (lossy compression only).',
    )
    ..addOption(
      'alpha_filter',
      help:
          'Specify the predictive filtering method for the alpha plane. One of none, fast or best, in increasing complexity and slowness order. Default is fast. Internally, alpha filtering is performed using four possible predictions (none, horizontal, vertical, gradient). The best mode will try each mode in turn and pick the one which gives the smaller size. The fast mode will just try to form an a priori guess without testing all modes.',
    )
    ..addOption(
      'alpha_method',
      help:
          'Specify the algorithm used for alpha compression: 0 or 1. Algorithm 0 denotes no compression, 1 uses WebP lossless format for compression. The default is 1.',
    )
    ..addFlag(
      'exact',
      help:
          'Preserve RGB values in transparent area. The default is off, to help compressibility.',
    )
    ..addOption(
      'blend_alpha',
      help:
          'This option blends the alpha channel (if present) with the source using the background color specified in hexadecimal as 0xrrggbb. The alpha channel is afterward reset to the opaque value 255.',
    )
    ..addFlag(
      'noalpha',
      help: 'Using this option will discard the alpha channel.',
    )
    ..addOption(
      'hint',
      help:
          'Specify the hint about input image type. Possible values are: photo, picture or graph.',
    )
    ..addOption(
      'metadata',
      help:
          'A comma separated list of metadata to copy from the input to the output if present. Valid values: all, none, exif, icc, xmp. The default is none.',
    )
    ..addFlag(
      'noasm',
      help: 'Disable all assembly optimizations.',
    );
}

void _logUsage(ArgParser argParser) {
  log(
    'Usage: dart webp.dart <flags> [arguments]',
  );
  log(argParser.usage);
}

Future<String> _getPackageCwebpPath() async {
  if (!_architectures.keys.contains(Abi.current())) {
    stderr.write(
      'Architecture ${Abi.current()} not supported. Supported architectures are: ${_architectures.keys}.',
    );
    exit(1);
  }

  final config = await findPackageConfig(Directory.current);

  if (config == null) {
    stderr.write('Failed to locate or read package config.');
    exit(1);
  }

  final package = config.packages.where((e) => e.name == 'webp').firstOrNull;

  if (package == null) {
    stderr.write('Failed to find webp in package config.');
    exit(1);
  }

  return p.join(p.fromUri(package.root), _architectures[Abi.current()]);
}

Future<void> _convertToWebP(
  String input,
  String output,
  List<String> options, {
  required bool fromPath,
}) async {
  String? path;

  if (fromPath) {
    path = 'cwebp';
  } else {
    path = p.join(await _getPackageCwebpPath(), 'cwebp');
  }

  try {
    final result = await Process.run(path, [...options, input, '-o', output]);
    log(result.stdout.toString());
  } catch (e) {
    if (fromPath) {
      stderr.write(r'cwebp not found in $PATH.');
    } else {
      stderr.write('cwebp not found in $path.');
    }
    exit(1);
  }
}

Future<void> main(List<String> arguments) async {
  final argParser = _buildParser();
  final options = <String>[];
  try {
    final results = argParser.parse(arguments);
    var verbose = false;
    var fromPath = false;

    // Process the parsed arguments.
    // Basic Options
    if (results.wasParsed('help')) {
      _logUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      log('webp version: $_version');
      return;
    }
    if (results.wasParsed('architectures')) {
      log('Supported architectures: ${_architectures.keys}');
      return;
    }
    if (results.wasParsed('verbose')) {
      verbose = true;
    }
    if (results.wasParsed('from_path')) {
      fromPath = true;
    }
    if (results.wasParsed('lossless')) {
      options.add('-lossless');
    }
    if (results.wasParsed('near_lossless')) {
      options
        ..add('-near_lossless')
        ..add(results['near_lossless'] as String);
    }
    if (results.wasParsed('quality')) {
      options
        ..add('-q')
        ..add(results['quality'] as String);
    }
    if (results.wasParsed('lossless_compression')) {
      options
        ..add('-z')
        ..add(results['lossless_compression'] as String);
    }
    if (results.wasParsed('alpha_q')) {
      options
        ..add('-alpha_q')
        ..add(results['alpha_q'] as String);
    }
    if (results.wasParsed('preset')) {
      options
        ..add('-preset')
        ..add(results['preset'] as String);
    }
    if (results.wasParsed('m')) {
      options
        ..add('-m')
        ..add(results['m'] as String);
    }
    if (results.wasParsed('crop')) {
      options
        ..add('-crop')
        ..add(results['crop'] as String);
    }
    if (results.wasParsed('resize')) {
      options
        ..add('-resize')
        ..add(results['resize'] as String);
    }
    if (results.wasParsed('mt')) {
      options.add('-mt');
    }
    if (results.wasParsed('low_memory')) {
      options.add('-low_memory');
    }
    // Lossy Options
    if (results.wasParsed('size')) {
      options
        ..add('-size')
        ..add(results['size'] as String);
    }
    if (results.wasParsed('psnr')) {
      options
        ..add('-psnr')
        ..add(results['psnr'] as String);
    }
    if (results.wasParsed('pass')) {
      options
        ..add('-pass')
        ..add(results['pass'] as String);
    }
    if (results.wasParsed('af')) {
      options.add('-af');
    }
    if (results.wasParsed('jpeg_like')) {
      options.add('-jpeg_like');
    }
    // Lossy advanced options
    if (results.wasParsed('f')) {
      options
        ..add('-f')
        ..add(results['f'] as String);
    }
    if (results.wasParsed('sharpness')) {
      options
        ..add('-sharpness')
        ..add(results['sharpness'] as String);
    }
    if (results.wasParsed('strong')) {
      options.add('-strong');
    }
    if (results.wasParsed('nostrong')) {
      options.add('-nostrong');
    }
    if (results.wasParsed('sharp_yuv')) {
      options.add('-sharp_yuv');
    }
    if (results.wasParsed('sns')) {
      options
        ..add('-sns')
        ..add(results['sns'] as String);
    }
    if (results.wasParsed('segments')) {
      options
        ..add('-segments')
        ..add(results['segments'] as String);
    }
    if (results.wasParsed('partition_limit')) {
      options
        ..add('-partition_limit')
        ..add(results['partition_limit'] as String);
    }
    // Additional Options
    if (results.wasParsed('s')) {
      options
        ..add('-s')
        ..add(results['s'] as String);
    }
    if (results.wasParsed('pre')) {
      options
        ..add('-pre')
        ..add(results['pre'] as String);
    }
    if (results.wasParsed('alpha_filter')) {
      options
        ..add('-alpha_filter')
        ..add(results['alpha_filter'] as String);
    }
    if (results.wasParsed('alpha_method')) {
      options
        ..add('-alpha_method')
        ..add(results['alpha_method'] as String);
    }
    if (results.wasParsed('exact')) {
      options.add('-exact');
    }
    if (results.wasParsed('blend_alpha')) {
      options
        ..add('-blend_alpha')
        ..add(results['blend_alpha'] as String);
    }
    if (results.wasParsed('noalpha')) {
      options.add('-noalpha');
    }
    if (results.wasParsed('hint')) {
      options
        ..add('-hint')
        ..add(results['hint'] as String);
    }
    if (results.wasParsed('metadata')) {
      options
        ..add('-metadata')
        ..add(results['metadata'] as String);
    }
    if (results.wasParsed('noasm')) {
      options.add('-noasm');
    }

    if (verbose) {
      log('[VERBOSE] All arguments: ${results.arguments}');
    } else {
      log('Positional arguments: ${results.rest}');
    }

    // Process the parsed arguments.
    if (results.wasParsed('input') && results.wasParsed('output')) {
      await _convertToWebP(
        results['input'] as String,
        results['output'] as String,
        options,
        fromPath: fromPath,
      );
    } else {
      log('wrong input');
    }
  } on FormatException catch (e) {
    // log usage information if an invalid argument was provided.
    log(e.message);
    log('');
    _logUsage(argParser);
  }
}
