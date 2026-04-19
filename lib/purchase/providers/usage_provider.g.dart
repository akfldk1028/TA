// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyUsageHash() => r'08a6cd6034c3684a8acc5046ece34acacb158651';

/// 오늘 남은 무료 리딩 횟수.
/// 프리미엄이면 null (무제한), 무료면 0~3.
///
/// Copied from [dailyUsage].
@ProviderFor(dailyUsage)
final dailyUsageProvider = AutoDisposeFutureProvider<int?>.internal(
  dailyUsage,
  name: r'dailyUsageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyUsageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DailyUsageRef = AutoDisposeFutureProviderRef<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
