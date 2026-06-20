import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Firestore の `Timestamp` ⇔ Dart の `DateTime` を相互変換する JsonConverter。
///
/// Firestore から読むと `Timestamp` 型で、JSON文字列(ISO8601)で来る場合もあるため
/// 両対応にしている。書き込み時は `Timestamp` に戻す。
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    throw ArgumentError('Unsupported timestamp value: $json');
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}
