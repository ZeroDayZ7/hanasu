import 'dart:async';

enum CircuitBreakerState { closed, open, halfOpen }

final class CircuitBreaker {
  final int maxFailures;
  final Duration resetTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  Timer? _resetTimer;

  CircuitBreaker({
    this.maxFailures = 5,
    this.resetTimeout = const Duration(minutes: 5),
  });

  CircuitBreakerState get state => _state;
  bool get isOpen => _state == CircuitBreakerState.open;
  bool get isClosed => _state == CircuitBreakerState.closed;
  bool get isHalfOpen => _state == CircuitBreakerState.halfOpen;

  /// Wywoływane przed każdą próbą połączenia.
  /// Rzuca wyjątek lub zwraca false, jeśli obwód jest otwarty.
  bool canExecute() {
    if (_state == CircuitBreakerState.open) {
      return false;
    }
    return true;
  }

  /// Rejestruje sukces – resetuje stan do Closed.
  void onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  /// Rejestruje porażkę – zwiększa licznik i ewentualnie otwiera obwód.
  void onFailure() {
    if (_state == CircuitBreakerState.halfOpen) {
      _openCircuit();
      return;
    }

    _failureCount++;
    if (_failureCount >= maxFailures) {
      _openCircuit();
    }
  }

  /// Ręczne wyjście z trybu Open (np. gdy system wykryje odzyskanie połączenia z internetem).
  void reset() {
    onSuccess();
  }

  void _openCircuit() {
    _state = CircuitBreakerState.open;
    _resetTimer?.cancel();
    _resetTimer = Timer(resetTimeout, () {
      _state = CircuitBreakerState.halfOpen;
    });
  }

  void dispose() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }
}
