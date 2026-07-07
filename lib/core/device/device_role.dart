import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/fcm_service.dart';

/// この端末の役割。
///
/// 家族は 1 つの Google アカウント（= 単一 uid）を共有し、端末ごとに
/// 「保護者用」か「お子さん用」かを選ぶ。役割はローカル（SharedPreferences）に
/// 保存し、FCM トークンにも書き込んで**通知の出し分け**に使う
/// （通知①=新着は child 端末へ、通知②=日次ダイジェストは parent 端末へ）。
enum DeviceRole {
  parent,
  child;

  /// 保存文字列（`name`）からの復元。未知/未設定は null。
  static DeviceRole? fromName(String? value) {
    for (final role in DeviceRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }

  /// この役割の起点ルート。
  String get homePath => this == DeviceRole.parent ? '/parent' : '/child';
}

/// `main.dart` が起動時に読み込んだ保存済み役割を注入するためのプロバイダ。
///
/// 既定は null（未設定＝オンボーディング未完了）。テスト環境では override
/// されないため常に null となり、認証・役割ゲートは無効のまま動く。
final bootstrapDeviceRoleProvider = Provider<DeviceRole?>((ref) => null);

/// この端末の役割を保持・更新するコントローラ。
///
/// 初期値は [bootstrapDeviceRoleProvider]（起動時に SharedPreferences から復元）。
/// [setRole] で変更すると永続化し、FCM トークンへ役割を再書き込みする。
class DeviceRoleController extends Notifier<DeviceRole?> {
  static const prefsKey = 'device_role';

  @override
  DeviceRole? build() => ref.read(bootstrapDeviceRoleProvider);

  /// 役割を設定して永続化する（オンボーディング確定・設定からの変更で呼ぶ）。
  Future<void> setRole(DeviceRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, role.name);
    state = role;
    // 既に保存済みのトークンへ新しい役割を反映する。
    ref.read(fcmServiceProvider).onRoleChanged();
  }
}

/// この端末の役割（null = 未設定）。
final deviceRoleProvider =
    NotifierProvider<DeviceRoleController, DeviceRole?>(DeviceRoleController.new);
