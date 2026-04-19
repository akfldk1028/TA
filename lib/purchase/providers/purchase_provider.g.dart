// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$offeringsHash() => r'9bca4c7db491fc6858125180228f5dcc6d2654f5';

/// See also [offerings].
@ProviderFor(offerings)
final offeringsProvider = AutoDisposeFutureProvider<Offerings?>.internal(
  offerings,
  name: r'offeringsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$offeringsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OfferingsRef = AutoDisposeFutureProviderRef<Offerings?>;
String _$purchaseNotifierHash() => r'b227a0ca116e71a8731e04d1a3dad259ff0adee9';

/// See also [PurchaseNotifier].
@ProviderFor(PurchaseNotifier)
final purchaseNotifierProvider =
    AsyncNotifierProvider<PurchaseNotifier, CustomerInfo>.internal(
      PurchaseNotifier.new,
      name: r'purchaseNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchaseNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PurchaseNotifier = AsyncNotifier<CustomerInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
