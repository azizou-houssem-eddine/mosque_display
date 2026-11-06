import 'package:flutter/material.dart';

enum TvAspectRatio { ar16_9, ar16_10, ar4_3 }

class TvResolution {
  final String id;
  final String name;
  final double width;
  final double height;
  final TvAspectRatio aspectRatio;
  final double devicePixelRatio;

  const TvResolution({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.aspectRatio,
    this.devicePixelRatio = 1.0,
  });

  Size get physicalSize => Size(width, height);
  Size get logicalSize =>
      Size(width / devicePixelRatio, height / devicePixelRatio);
  String get ratioLabel {
    switch (aspectRatio) {
      case TvAspectRatio.ar16_9:
        return '16:9';
      case TvAspectRatio.ar16_10:
        return '16:10';
      case TvAspectRatio.ar4_3:
        return '4:3';
    }
  }

  @override
  String toString() =>
      '$name [${width.toInt()}x${height.toInt()} ($ratioLabel) @${devicePixelRatio}x]';
}

/// 9 Core Resolution Matrix (3 Tiers x 3 Aspect Ratios)
const List<TvResolution> coreTvResolutions = [
  // 720p
  TvResolution(
      id: '720p_16_9',
      name: '720p HD Ready',
      width: 1280,
      height: 720,
      aspectRatio: TvAspectRatio.ar16_9),
  TvResolution(
      id: '720p_16_10',
      name: '720p Wide',
      width: 1152,
      height: 720,
      aspectRatio: TvAspectRatio.ar16_10),
  TvResolution(
      id: '720p_4_3',
      name: '720p Narrow',
      width: 960,
      height: 720,
      aspectRatio: TvAspectRatio.ar4_3),
  // 1080p
  TvResolution(
      id: '1080p_16_9',
      name: '1080p Full HD',
      width: 1920,
      height: 1080,
      aspectRatio: TvAspectRatio.ar16_9),
  TvResolution(
      id: '1080p_16_10',
      name: '1080p WUXGA',
      width: 1920,
      height: 1200,
      aspectRatio: TvAspectRatio.ar16_10),
  TvResolution(
      id: '1080p_4_3',
      name: '1080p Narrow',
      width: 1440,
      height: 1080,
      aspectRatio: TvAspectRatio.ar4_3),
  // 4K
  TvResolution(
      id: '4k_16_9',
      name: '4K Ultra HD',
      width: 3840,
      height: 2160,
      aspectRatio: TvAspectRatio.ar16_9),
  TvResolution(
      id: '4k_16_10',
      name: '4K Wide',
      width: 3840,
      height: 2400,
      aspectRatio: TvAspectRatio.ar16_10),
  TvResolution(
      id: '4k_4_3',
      name: '4K Narrow',
      width: 2880,
      height: 2160,
      aspectRatio: TvAspectRatio.ar4_3),
];

/// Pixel Density Variations (Android TV UI scaling modes)
const List<TvResolution> tvDensityResolutions = [
  TvResolution(
      id: '4k_dpr_2_0',
      name: '4K (DPR 2.0x Android TV UI)',
      width: 3840,
      height: 2160,
      aspectRatio: TvAspectRatio.ar16_9,
      devicePixelRatio: 2.0),
  TvResolution(
      id: '1080p_dpr_1_5',
      name: '1080p (DPR 1.5x HDPI Stick)',
      width: 1920,
      height: 1080,
      aspectRatio: TvAspectRatio.ar16_9,
      devicePixelRatio: 1.5),
  TvResolution(
      id: '4k_dpr_3_0',
      name: '4K (DPR 3.0x XXHDPI Panel)',
      width: 3840,
      height: 2160,
      aspectRatio: TvAspectRatio.ar16_9,
      devicePixelRatio: 3.0),
];
