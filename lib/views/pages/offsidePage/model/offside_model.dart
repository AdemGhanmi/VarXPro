// File: lib/views/pages/offsidePage/models/offside_model.dart
// Updated with dummy position generation for players/gks/ball/line if missing

// ------------------------------------------------------------
// 1) PingResponse (unchanged)
// ------------------------------------------------------------
class PingResponse {
  final bool ok;
  final String model;
  final String opencv;

  PingResponse({
    required this.ok,
    required this.model,
    required this.opencv,
  });

  factory PingResponse.fromJson(Map<String, dynamic> json) {
    final bool statusOk =
        (json['ok'] == true) || (json['status']?.toString().toLowerCase() == 'ok');
    final String opencvVal =
        (json['opencv'] as String?) ?? (json['opengl'] as String?) ?? '';
    return PingResponse(
      ok: statusOk,
      model: (json['model'] as String?) ?? '',
      opencv: opencvVal,
    );
  }
}

// ------------------------------------------------------------
// 2) Helpers de normalisation (lineup → players) + Dummy Generation
// ------------------------------------------------------------
List<Map<String, dynamic>> _normalize2DPlayers(dynamic raw) {
  final out = <Map<String, dynamic>>[];
  if (raw is List) {
    for (final p in raw) {
      if (p is Map) {
        final x = (p['x'] as num?)?.toDouble();
        final y = (p['y'] as num?)?.toDouble();
        if (x != null && y != null) {
          out.add({
            'x': x,
            'y': y,
            'team': p['team'],
            'is_gk': p['is_gk'] ?? false,
          });
        }
      } else if (p is List) {
        if (p.length >= 2 && p[0] is num && p[1] is num) {
          out.add({
            'x': (p[0] as num).toDouble(),
            'y': (p[1] as num).toDouble(),
            'team': p.length >= 3 ? p[2] : null,
            'is_gk': p.length >= 4 ? p[3] : false,
          });
        }
      }
    }
  }
  return out;
}

List<Map<String, dynamic>> _normalize3DPlayers(dynamic raw) {
  final out = <Map<String, dynamic>>[];
  if (raw is List) {
    for (final p in raw) {
      if (p is Map) {
        final x = (p['x'] as num?)?.toDouble();
        final y = (p['y'] as num?)?.toDouble();
        final z = (p['z'] as num?)?.toDouble() ?? 0.0;
        if (x != null && y != null) {
          out.add({
            'x': x,
            'y': y,
            'z': z,
            'team': p['team'],
            'is_gk': p['is_gk'] ?? false,
          });
        }
      } else if (p is List) {
        if (p.length >= 2 && p[0] is num && p[1] is num) {
          out.add({
            'x': (p[0] as num).toDouble(),
            'y': (p[1] as num).toDouble(),
            'z': (p.length >= 3 && p[2] is num) ? (p[2] as num).toDouble() : 0.0,
            'team': p.length >= 4 ? p[3] : null,
            'is_gk': p.length >= 5 ? p[4] : false,
          });
        }
      }
    }
  }
  return out;
}

List<Map<String, dynamic>> _extractPlayers2DFromAny(Map<String, dynamic> meta) {
  final candidates = [
    'players_xy',
    'players_list',
    'players2d',
    'players_2d',
    'lineup_xy',
    'lineup2d',
    'lineup_2d',
    'xy',
    'positions_2d',
    'positions',
    'lineup',
    'detections',
    'objects',
  ];
  List<Map<String, dynamic>> got = [];
  for (final k in candidates) {
    if (meta[k] != null) {
      got = _normalize2DPlayers(meta[k]);
      if (got.isNotEmpty) return got;
    }
  }

  final numPlayers = (meta['meta']?['num_players'] as num?)?.toInt() ?? 0;
  if (numPlayers > 0 && got.isEmpty) {
    print('⚠️ No real 2D positions found—generating $numPlayers dummy players/gks');
    final frameW = (meta['meta']?['frame_size']?['w'] as num?)?.toDouble() ?? 900.0;
    final frameH = (meta['meta']?['frame_size']?['h'] as num?)?.toDouble() ?? 600.0;
    final numGks = 2;
    final numFieldPlayers = numPlayers - numGks;
    for (int i = 0; i < numFieldPlayers; i++) {
      got.add({
        'x': 100.0 + (i % 5 * 150),
        'y': 50.0 + (i ~/ 5 * 120),
        'team': i % 2 == 0 ? 'team1' : 'team2',
        'is_gk': false,
      });
    }
    got.add({'x': 50.0, 'y': frameH / 2, 'team': 'team1', 'is_gk': true});
    got.add({'x': frameW - 50.0, 'y': frameH / 2, 'team': 'team2', 'is_gk': true});
  }
  return got;
}

List<Map<String, dynamic>> _extractPlayers3DFromAny(Map<String, dynamic> meta) {
  final candidates = [
    'players_xyz',
    'players3d',
    'players_3d',
    'lineup_xyz',
    'lineup3d',
    'lineup_3d',
    'xyz',
    'positions_3d',
    'detections_3d',
  ];
  List<Map<String, dynamic>> got = [];
  for (final k in candidates) {
    if (meta[k] != null) {
      got = _normalize3DPlayers(meta[k]);
      if (got.isNotEmpty) return got;
    }
  }

  final numPlayers = (meta['meta']?['num_players'] as num?)?.toInt() ?? 0;
  if (numPlayers > 0 && got.isEmpty) {
    print('⚠️ No real 3D positions found—generating $numPlayers dummy players/gks (z=0)');
    final fieldLength = (meta['meta']?['field_size_m']?['length'] as num?)?.toDouble() ?? 105.0;
    final fieldWidth = (meta['meta']?['field_size_m']?['width'] as num?)?.toDouble() ?? 68.0;
    final numGks = 2;
    final numFieldPlayers = numPlayers - numGks;
    for (int i = 0; i < numFieldPlayers; i++) {
      got.add({
        'x': 10.0 + (i % 5 * 20.0),
        'y': 5.0 + (i ~/ 5 * 13.6),
        'z': 0.0,
        'team': i % 2 == 0 ? 'team1' : 'team2',
        'is_gk': false,
      });
    }
    got.add({'x': 0.0, 'y': fieldWidth / 2, 'z': 0.0, 'team': 'team1', 'is_gk': true});
    got.add({'x': fieldLength, 'y': fieldWidth / 2, 'z': 0.0, 'team': 'team2', 'is_gk': true});
  }
  return got;
}

Map<String, double>? _generateDummyBall(Map<String, dynamic> meta) {
  final numBalls = (meta['meta']?['num_balls'] as num?)?.toInt() ?? 0;
  if (numBalls > 0) return null;
  print('⚠️ No ball found—generating dummy ball');
  final frameW = (meta['meta']?['frame_size']?['w'] as num?)?.toDouble() ?? 900.0;
  final frameH = (meta['meta']?['frame_size']?['h'] as num?)?.toDouble() ?? 600.0;
  return {'x': frameW / 2, 'y': frameH / 2};
}

List<List<double>>? _generateDummyOffsideLine(Map<String, dynamic> meta) {
  if (meta['offside_line'] != null) return null;
  print('⚠️ No offside line—generating dummy line');
  final frameW = (meta['meta']?['frame_size']?['w'] as num?)?.toDouble() ?? 900.0;
  final frameH = (meta['meta']?['frame_size']?['h'] as num?)?.toDouble() ?? 600.0;
  return [
    [frameW / 3, frameH / 2 - 50],
    [frameW / 3, frameH / 2 + 50],
  ];
}

Map<String, List<double>>? _generateDummyOffsideLine3D(Map<String, dynamic> meta) {
  if (meta['offside_line'] != null) return null;
  print('⚠️ No 3D offside line—generating dummy');
  final fieldLength = (meta['meta']?['field_size_m']?['length'] as num?)?.toDouble() ?? 105.0;
  final fieldWidth = (meta['meta']?['field_size_m']?['width'] as num?)?.toDouble() ?? 68.0;
  return {
    'p1': [fieldLength / 3, fieldWidth / 2 - 5, 0.0],
    'p2': [fieldLength / 3, fieldWidth / 2 + 5, 0.0],
  };
}

// ------------------------------------------------------------
// 3) Models 2D / 3D (Updated with dummies)
// ------------------------------------------------------------
class Field2DModel {
  final Map<String, int> frameSize;
  final List<Map<String, dynamic>> players;
  final Map<String, double>? ball;
  final List<List<double>>? offsideLine;
  final List<List<double>>? pitch;

  Field2DModel({
    required this.frameSize,
    required this.players,
    required this.ball,
    required this.offsideLine,
    required this.pitch,
  });

  factory Field2DModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? meta}) {
    final fs = (json['frame_size'] as Map<String, dynamic>?);
    final w = (fs?['w'] as num?)?.toInt() ?? 0;
    final h = (fs?['h'] as num?)?.toInt() ?? 0;

    List<Map<String, dynamic>> playersList = _normalize2DPlayers(json['players']);
    if (playersList.isEmpty) {
      playersList = _normalize2DPlayers(json['players_xy'] ?? json['players_list']);
    }
    final metaPlayers = _extractPlayers2DFromAny(meta ?? {});
    if (playersList.isEmpty && metaPlayers.isNotEmpty) {
      playersList = metaPlayers;
    }

    Map<String, double>? ball;
    if (json['ball'] is Map) {
      final b = json['ball'] as Map<String, dynamic>;
      final bx = (b['x'] as num?)?.toDouble();
      final by = (b['y'] as num?)?.toDouble();
      if (bx != null && by != null) {
        ball = {'x': bx, 'y': by};
      }
    } else {
      ball = _generateDummyBall(meta ?? {});
    }

    List<List<double>>? offsideLine;
    if (json['offside_line'] is List) {
      offsideLine = (json['offside_line'] as List)
          .whereType<List>()
          .map((pt) => [
                (pt[0] as num).toDouble(),
                (pt[1] as num).toDouble(),
              ])
          .toList();
    } else {
      offsideLine = _generateDummyOffsideLine(meta ?? {});
    }

    List<List<double>>? pitch;
    final pitchObj = json['pitch'];
    if (pitchObj is Map && pitchObj['corners'] is List) {
      pitch = (pitchObj['corners'] as List)
          .whereType<List>()
          .map((pt) => pt.take(2).map((e) => (e as num).toDouble()).toList())
          .toList()
          .cast<List<double>>();
    }

    return Field2DModel(
      frameSize: {'w': w, 'h': h},
      players: playersList,
      ball: ball,
      offsideLine: offsideLine,
      pitch: pitch,
    );
  }
}

class Field3DModel {
  final Map<String, double> fieldSizeM;
  final List<Map<String, dynamic>> players;
  final Map<String, double>? ball;
  final Map<String, List<double>>? offsideLine;
  final List<List<double>>? pitch;
  final bool homographyAvailable;

  Field3DModel({
    required this.fieldSizeM,
    required this.players,
    required this.ball,
    required this.offsideLine,
    required this.pitch,
    required this.homographyAvailable,
  });

  factory Field3DModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? meta}) {
    final fsz = (json['field_size_m'] as Map<String, dynamic>?);
    final length = (fsz?['length'] as num?)?.toDouble() ?? 105.0;
    final width  = (fsz?['width']  as num?)?.toDouble() ?? 68.0;

    List<Map<String, dynamic>> playersList = _normalize3DPlayers(json['players']);
    if (playersList.isEmpty) {
      playersList = _normalize3DPlayers(json['players_xyz'] ?? json['players_list']);
    }
    final metaPlayers = _extractPlayers3DFromAny(meta ?? {});
    if (playersList.isEmpty && metaPlayers.isNotEmpty) {
      playersList = metaPlayers;
    }

    Map<String, double>? ball;
    if (json['ball'] is Map) {
      final b = json['ball'] as Map<String, dynamic>;
      final bx = (b['x'] as num?)?.toDouble();
      final by = (b['y'] as num?)?.toDouble();
      final bz = (b['z'] as num?)?.toDouble() ?? 0.0;
      if (bx != null && by != null) {
        ball = {'x': bx, 'y': by, 'z': bz};
      }
    } else {
      final dummy2d = _generateDummyBall(meta ?? {});
      if (dummy2d != null) {
        ball = {...dummy2d, 'z': 0.0};
      }
    }

    Map<String, List<double>>? offsideLine;
    if (json['offside_line'] is Map) {
      final l = json['offside_line'] as Map<String, dynamic>;
      final p1 = (l['p1'] as List?)?.map((e) => (e as num).toDouble()).toList();
      final p2 = (l['p2'] as List?)?.map((e) => (e as num).toDouble()).toList();
      if (p1 != null && p2 != null && p1.length >= 2 && p2.length >= 2) {
        offsideLine = {'p1': p1, 'p2': p2};
      }
    } else {
      offsideLine = _generateDummyOffsideLine3D(meta ?? {});
    }

    List<List<double>>? pitch;
    final pitchObj = json['pitch'];
    if (pitchObj is Map && pitchObj['corners'] is List) {
      pitch = (pitchObj['corners'] as List)
          .whereType<List>()
          .map((pt) => pt.map((e) => (e as num).toDouble()).toList())
          .toList()
          .cast<List<double>>();
    }

    final hom = json['homography_available'] as bool? ?? false;

    return Field3DModel(
      fieldSizeM: {'length': length, 'width': width},
      players: playersList,
      ball: ball,
      offsideLine: offsideLine,
      pitch: pitch,
      homographyAvailable: hom,
    );
  }
}

// ------------------------------------------------------------
// 4) OffsideFrameResponse / OffsideVideoResponse (Updated to pass meta to models)
// ------------------------------------------------------------
class OffsideFrameResponse {
  final bool ok;
  final bool? offside;
  final int? offsidesCount;
  final String? fileUrl;
  final String? image2DUrl;
  final String? image3DUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? attackingTeam;
  final double? secondLastDefenderProjection;
  final List<dynamic>? players;
  final String? reason;
  final String? error;
  final String? top;
  final String? verdict;

  final Field2DModel? field2D;
  final Field3DModel? field3D;
  final Map<String, dynamic>? meta;

  OffsideFrameResponse({
    required this.ok,
    required this.offside,
    required this.offsidesCount,
    this.fileUrl,
    this.image2DUrl,
    this.image3DUrl,
    this.linePoints,
    this.attackDirection,
    this.attackingTeam,
    this.secondLastDefenderProjection,
    this.players,
    this.reason,
    this.error,
    this.top,
    this.verdict,
    this.field2D,
    this.field3D,
    this.meta,
  });

  bool get offsideResolved {
    if (offside != null) return offside!;
    final s = (top ?? verdict)?.toLowerCase();
    if (s == 'offside') return true;
    if (s == 'onside') return false;
    if (offsidesCount != null) return (offsidesCount! > 0);
    return false;
  }

  dynamic get offsideLine => field2D?.offsideLine ?? field3D?.offsideLine;

  factory OffsideFrameResponse.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? models,
    String? fileUrl,
    String? image2DUrl,
    String? image3DUrl,
  }) {
    Map<String, List<int>>? linePointsMap;
    final offsideObj = json['offside'];
    if (offsideObj is Map && offsideObj['line'] is Map) {
      final l = offsideObj['line'] as Map<String, dynamic>;
      final p1 = (l['p1'] as List?)?.map((e) => (e as num).toInt()).toList();
      final p2 = (l['p2'] as List?)?.map((e) => (e as num).toInt()).toList();
      if (p1 != null && p2 != null) {
        linePointsMap = {'start': p1, 'end': p2};
      }
    } else if (json['line_points'] is Map) {
      final lp = json['line_points'] as Map<String, dynamic>;
      linePointsMap = {
        'start': (lp['start'] as List?)?.map((e) => (e as num).toInt()).toList() ?? <int>[],
        'end': (lp['end'] as List?)?.map((e) => (e as num).toInt()).toList() ?? <int>[],
      };
    }

    bool? offBool;
    final offRaw = json['offside'];
    if (offRaw is bool) offBool = offRaw;
    if (offRaw is String) {
      final v = offRaw.toLowerCase();
      if (v == 'true' || v == 'offside') offBool = true;
      if (v == 'false' || v == 'onside') offBool = false;
    }

    final Map<String, dynamic> m = {};
    if (models != null) {
      models.forEach((k, v) {
        if (v is Map) {
          m[k] = Map<String, dynamic>.from(v);
        } else {
          m[k] = v;
        }
      });
    }

    final f2dMap = (m['field_2d'] is Map) ? Map<String, dynamic>.from(m['field_2d']) : <String, dynamic>{};
    final f3dMap = (m['field_3d'] is Map) ? Map<String, dynamic>.from(m['field_3d']) : <String, dynamic>{};

    Field2DModel? f2d = Field2DModel.fromJson(f2dMap, meta: json);
    Field3DModel? f3d = Field3DModel.fromJson(f3dMap, meta: json);

    return OffsideFrameResponse(
      ok: true,
      offside: offBool,
      offsidesCount: (json['offsides_count'] as num?)?.toInt(),
      fileUrl: fileUrl,
      image2DUrl: image2DUrl,
      image3DUrl: image3DUrl,
      linePoints: linePointsMap,
      attackDirection: json['attack_direction'] as String?,
      attackingTeam: json['attacking_team'] as String?,
      secondLastDefenderProjection: (json['second_last_defender_projection'] as num?)?.toDouble(),
      players: json['players'] as List<dynamic>?,
      reason: json['reason'] as String?,
      error: json['error'] as String?,
      top: json['top'] as String?,
      verdict: json['verdict'] as String?,
      field2D: f2d,
      field3D: f3d,
      meta: json,
    );
  }
}

class OffsideVideoResponse {
  final bool ok;
  final bool? offside;
  final int? offsidesCount;
  final String? fileUrl;
  final String? image2DUrl;
  final String? image3DUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? attackingTeam;
  final double? secondLastDefenderProjection;
  final List<dynamic>? players;
  final String? reason;
  final String? error;
  final String? top;
  final String? verdict;

  final Field2DModel? field2D;
  final Field3DModel? field3D;
  final Map<String, dynamic>? meta;

  OffsideVideoResponse({
    required this.ok,
    required this.offside,
    required this.offsidesCount,
    this.fileUrl,
    this.image2DUrl,
    this.image3DUrl,
    this.linePoints,
    this.attackDirection,
    this.attackingTeam,
    this.secondLastDefenderProjection,
    this.players,
    this.reason,
    this.error,
    this.top,
    this.verdict,
    this.field2D,
    this.field3D,
    this.meta,
  });

  bool get offsideResolved {
    if (offside != null) return offside!;
    final s = (top ?? verdict)?.toLowerCase();
    if (s == 'offside') return true;
    if (s == 'onside') return false;
    if (offsidesCount != null) return (offsidesCount! > 0);
    return false;
  }

  dynamic get offsideLine => field2D?.offsideLine ?? field3D?.offsideLine;

  factory OffsideVideoResponse.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? models,
    String? fileUrl,
    String? image2DUrl,
    String? image3DUrl,
  }) {
    Map<String, List<int>>? linePointsMap;
    final offsideObj = json['offside'];
    if (offsideObj is Map && offsideObj['line'] is Map) {
      final l = offsideObj['line'] as Map<String, dynamic>;
      final p1 = (l['p1'] as List?)?.map((e) => (e as num).toInt()).toList();
      final p2 = (l['p2'] as List?)?.map((e) => (e as num).toInt()).toList();
      if (p1 != null && p2 != null) {
        linePointsMap = {'start': p1, 'end': p2};
      }
    } else if (json['line_points'] is Map) {
      final lp = json['line_points'] as Map<String, dynamic>;
      linePointsMap = {
        'start': (lp['start'] as List?)?.map((e) => (e as num).toInt()).toList() ?? <int>[],
        'end': (lp['end'] as List?)?.map((e) => (e as num).toInt()).toList() ?? <int>[],
      };
    }

    final Map<String, dynamic> m = {};
    if (models != null) {
      models.forEach((k, v) {
        if (v is Map) {
          m[k] = Map<String, dynamic>.from(v);
        } else {
          m[k] = v;
        }
      });
    }

    final f2dMap = (m['field_2d'] is Map) ? Map<String, dynamic>.from(m['field_2d']) : <String, dynamic>{};
    final f3dMap = (m['field_3d'] is Map) ? Map<String, dynamic>.from(m['field_3d']) : <String, dynamic>{};

    Field2DModel? f2d = Field2DModel.fromJson(f2dMap, meta: json);
    Field3DModel? f3d = Field3DModel.fromJson(f3dMap, meta: json);

    bool? offBool;
    final offRaw = json['offside'];
    if (offRaw is bool) offBool = offRaw;
    if (offRaw is String) {
      final v = offRaw.toLowerCase();
      if (v == 'true' || v == 'offside') offBool = true;
      if (v == 'false' || v == 'onside') offBool = false;
    }

    return OffsideVideoResponse(
      ok: true,
      offside: offBool,
      offsidesCount: (json['offsides_count'] as num?)?.toInt(),
      fileUrl: fileUrl,
      image2DUrl: image2DUrl,
      image3DUrl: image3DUrl,
      linePoints: linePointsMap,
      attackDirection: json['attack_direction'] as String?,
      attackingTeam: json['attacking_team'] as String?,
      secondLastDefenderProjection: (json['second_last_defender_projection'] as num?)?.toDouble(),
      players: json['players'] as List<dynamic>?,
      reason: json['reason'] as String?,
      error: json['error'] as String?,
      top: json['top'] as String?,
      verdict: json['verdict'] as String?,
      field2D: f2d,
      field3D: f3d,
      meta: json,
    );
  }
}