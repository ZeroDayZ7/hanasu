abstract final class WebRtcConfig {
  static const Map<String, dynamic> rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelay',
        'credential': 'openrelay',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelay',
        'credential': 'openrelay',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all',
  };

  static const Map<String, dynamic> audioConstraints = {
    'audio': {
      'mandatory': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'optional': [],
    },
    'video': false,
  };
}
