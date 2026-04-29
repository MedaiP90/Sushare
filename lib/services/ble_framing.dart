import 'dart:typed_data';

// BLE packets have limited payload size. Messages are split into chunks with a
// 4-byte header so the receiver can reassemble them in order.
//
// Header layout per packet: [totalChunks:2][chunkIndex:2][payload bytes...]

/// Default payload size in bytes per chunk (fits the lowest common denominator
/// of iOS default ATT MTU 185 − 3 ATT overhead − 4 framing header = 178).
const int defaultChunkPayloadSize = 178;

/// Splits [bytes] into BLE-safe chunks, each prefixed with a 4-byte header.
/// [payloadSize] is the maximum payload bytes per chunk (excluding the 4-byte
/// header). Pass a value derived from [CentralManager.getMaximumWriteLength]
/// or [PeripheralManager.getMaximumNotifyLength] minus 4.
List<Uint8List> chunkBytes(Uint8List bytes,
    {int payloadSize = defaultChunkPayloadSize}) {
  final total = (bytes.length / payloadSize).ceil().clamp(1, 65535);
  return List.generate(total, (i) {
    final start = i * payloadSize;
    final end = (start + payloadSize).clamp(0, bytes.length);
    final payload = bytes.sublist(start, end);
    final packet = Uint8List(4 + payload.length);
    packet[0] = (total >> 8) & 0xFF;
    packet[1] = total & 0xFF;
    packet[2] = (i >> 8) & 0xFF;
    packet[3] = i & 0xFF;
    packet.setRange(4, packet.length, payload);
    return packet;
  });
}

/// Accumulates BLE chunks until a complete message is reassembled.
/// A new sequence (chunk index 0) resets any in-progress assembly.
class ChunkAssembler {
  int? _totalChunks;
  final _chunks = <int, Uint8List>{};

  /// Returns the full message bytes when all chunks have arrived, else null.
  Uint8List? feed(Uint8List packet) {
    if (packet.length < 4) return null;
    final total = (packet[0] << 8) | packet[1];
    final idx = (packet[2] << 8) | packet[3];
    if (idx == 0) {
      _totalChunks = total;
      _chunks.clear();
    }
    if (_totalChunks == null || total != _totalChunks) return null;
    _chunks[idx] = packet.sublist(4);
    if (_chunks.length == _totalChunks) {
      final builder = BytesBuilder();
      for (var i = 0; i < _totalChunks!; i++) {
        builder.add(_chunks[i]!);
      }
      _chunks.clear();
      _totalChunks = null;
      return builder.toBytes();
    }
    return null;
  }
}
