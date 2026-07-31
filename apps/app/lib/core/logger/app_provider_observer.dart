import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppProviderObserver extends ProviderObserver {
  final AppLogger _logger;

  AppProviderObserver(this._logger);

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    _logger.t(
      'Initialized: ${context.provider.name ?? context.provider.runtimeType}',
      module: 'Riverpod',
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    _logger.d(
      'Updated: ${context.provider.name ?? context.provider.runtimeType}',
      module: 'Riverpod',
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.e(
      'Provider failure: ${context.provider.name ?? context.provider.runtimeType}',
      module: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
