final class SdpValidator {
  const SdpValidator._();

  /// Waliduje formalną i merytoryczną poprawność ciągu SDP.
  static bool isValidSdp(String? sdp, {required String expectedType}) {
    if (sdp == null || sdp.trim().isEmpty) {
      return false;
    }

    final trimmed = sdp.trim();

    // 1. Podstawowe nagłówki SDP (RFC 4566 / RFC 8866)
    if (!trimmed.startsWith('v=0')) {
      return false;
    }

    if (!trimmed.contains('o=') || !trimmed.contains('s=')) {
      return false;
    }

    // 2. Weryfikacja typu sesji
    if (expectedType == 'offer') {
      if (!trimmed.contains('a=setup:actpass') &&
          !trimmed.contains('a=setup:active')) {
        // Oferta musi zdefiniować rolę DTLS (zazwyczaj actpass)
        return false;
      }
    } else if (expectedType == 'answer') {
      if (!trimmed.contains('a=setup:active') &&
          !trimmed.contains('a=setup:passive')) {
        // Answer musi precyzyjnie wybrać rolę DTLS
        return false;
      }
    }

    // 3. Weryfikacja sekcji mediów (m=audio lub m=video)
    if (!trimmed.contains('m=audio') && !trimmed.contains('m=video')) {
      return false;
    }

    // 4. Weryfikacja atrybutów transportu/bezpieczeństwa (ICE i DTLS fingerprint)
    if (!trimmed.contains('a=ice-ufrag:') || !trimmed.contains('a=ice-pwd:')) {
      return false;
    }

    if (!trimmed.contains('a=fingerprint:')) {
      return false;
    }

    return true;
  }
}
