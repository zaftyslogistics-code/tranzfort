import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader._({
    super.key,
    required this.child,
  });

  final Widget child;

  factory SkeletonLoader.card({
    Key? key,
    double? height,
    EdgeInsetsGeometry? margin,
  }) = _SkeletonCardLoader;

  factory SkeletonLoader.list({
    Key? key,
    int count,
    double itemHeight,
    EdgeInsetsGeometry? padding,
  }) = _SkeletonListLoader;

  factory SkeletonLoader.text({
    Key? key,
    int lines,
    double lineHeight,
    double gap,
    EdgeInsetsGeometry? padding,
  }) = _SkeletonTextLoader;

  factory SkeletonLoader.circle({
    Key? key,
    double radius,
  }) = _SkeletonCircleLoader;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.scaffoldBg,
      highlightColor: Colors.white,
      child: child,
    );
  }
}

class _SkeletonCardLoader extends SkeletonLoader {
  _SkeletonCardLoader({
    super.key,
    double? height,
    EdgeInsetsGeometry? margin,
  }) : super._(
         child: Container(
           height: height ?? 112,
           margin:
               margin ??
               const EdgeInsets.symmetric(vertical: AppSpacing.xs),
           decoration: BoxDecoration(
             color: AppColors.neutralLight,
             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
           ),
         ),
       );
}

class _SkeletonListLoader extends SkeletonLoader {
  _SkeletonListLoader({
    super.key,
    int count = 3,
    double itemHeight = 112,
    EdgeInsetsGeometry? padding,
  }) : super._(
         child: ListView.separated(
           shrinkWrap: true,
           physics: const NeverScrollableScrollPhysics(),
           padding: padding ??
               const EdgeInsets.symmetric(
                 horizontal: AppSpacing.screenPaddingH,
                 vertical: AppSpacing.screenPaddingV,
               ),
           itemCount: count,
           separatorBuilder: (context, index) =>
               const SizedBox(height: AppSpacing.sm),
           itemBuilder: (context, index) => Container(
             height: itemHeight,
             decoration: BoxDecoration(
               color: AppColors.neutralLight,
               borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
             ),
           ),
         ),
       );
}

class _SkeletonTextLoader extends SkeletonLoader {
  _SkeletonTextLoader({
    super.key,
    int lines = 3,
    double lineHeight = 12,
    double gap = AppSpacing.xs,
    EdgeInsetsGeometry? padding,
  }) : super._(
         child: Padding(
           padding: padding ?? EdgeInsets.zero,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: List.generate(lines, (index) {
               final widthFactor = index == lines - 1 ? 0.7 : 1.0;
               return Padding(
                 padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : gap),
                 child: FractionallySizedBox(
                   widthFactor: widthFactor,
                   child: Container(
                     height: lineHeight,
                     decoration: BoxDecoration(
                       color: AppColors.neutralLight,
                       borderRadius: BorderRadius.circular(AppSpacing.xs),
                     ),
                   ),
                 ),
               );
             }),
           ),
         ),
       );
}

class _SkeletonCircleLoader extends SkeletonLoader {
  _SkeletonCircleLoader({
    super.key,
    double radius = 20,
  }) : super._(
         child: Container(
           width: radius * 2,
           height: radius * 2,
           decoration: const BoxDecoration(
             color: AppColors.neutralLight,
             shape: BoxShape.circle,
           ),
         ),
       );
}
