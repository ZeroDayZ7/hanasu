// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

@JsonKey(defaultValue: '') String get id;@JsonKey(name: 'room_id', defaultValue: '') String get roomId;@JsonKey(name: 'author_id', defaultValue: '') String get authorId;@JsonKey(name: 'author_nick', defaultValue: '') String get authorNick; String get text; TranslationMessage? get translation; MessageType get type; MessageStatus get status; DateTime get timestamp;@JsonKey(includeFromJson: false, includeToJson: false) MessageSource get source;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorNick, authorNick) || other.authorNick == authorNick)&&(identical(other.text, text) || other.text == text)&&(identical(other.translation, translation) || other.translation == translation)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,authorId,authorNick,text,translation,type,status,timestamp,source);

@override
String toString() {
  return 'ChatMessage(id: $id, roomId: $roomId, authorId: $authorId, authorNick: $authorNick, text: $text, translation: $translation, type: $type, status: $status, timestamp: $timestamp, source: $source)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(name: 'room_id', defaultValue: '') String roomId,@JsonKey(name: 'author_id', defaultValue: '') String authorId,@JsonKey(name: 'author_nick', defaultValue: '') String authorNick, String text, TranslationMessage? translation, MessageType type, MessageStatus status, DateTime timestamp,@JsonKey(includeFromJson: false, includeToJson: false) MessageSource source
});


$TranslationMessageCopyWith<$Res>? get translation;

}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? authorId = null,Object? authorNick = null,Object? text = null,Object? translation = freezed,Object? type = null,Object? status = null,Object? timestamp = null,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorNick: null == authorNick ? _self.authorNick : authorNick // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,translation: freezed == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as TranslationMessage?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as MessageSource,
  ));
}
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TranslationMessageCopyWith<$Res>? get translation {
    if (_self.translation == null) {
    return null;
  }

  return $TranslationMessageCopyWith<$Res>(_self.translation!, (value) {
    return _then(_self.copyWith(translation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(name: 'room_id', defaultValue: '')  String roomId, @JsonKey(name: 'author_id', defaultValue: '')  String authorId, @JsonKey(name: 'author_nick', defaultValue: '')  String authorNick,  String text,  TranslationMessage? translation,  MessageType type,  MessageStatus status,  DateTime timestamp, @JsonKey(includeFromJson: false, includeToJson: false)  MessageSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.roomId,_that.authorId,_that.authorNick,_that.text,_that.translation,_that.type,_that.status,_that.timestamp,_that.source);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(name: 'room_id', defaultValue: '')  String roomId, @JsonKey(name: 'author_id', defaultValue: '')  String authorId, @JsonKey(name: 'author_nick', defaultValue: '')  String authorNick,  String text,  TranslationMessage? translation,  MessageType type,  MessageStatus status,  DateTime timestamp, @JsonKey(includeFromJson: false, includeToJson: false)  MessageSource source)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.roomId,_that.authorId,_that.authorNick,_that.text,_that.translation,_that.type,_that.status,_that.timestamp,_that.source);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(name: 'room_id', defaultValue: '')  String roomId, @JsonKey(name: 'author_id', defaultValue: '')  String authorId, @JsonKey(name: 'author_nick', defaultValue: '')  String authorNick,  String text,  TranslationMessage? translation,  MessageType type,  MessageStatus status,  DateTime timestamp, @JsonKey(includeFromJson: false, includeToJson: false)  MessageSource source)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.roomId,_that.authorId,_that.authorNick,_that.text,_that.translation,_that.type,_that.status,_that.timestamp,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage extends ChatMessage {
  const _ChatMessage({@JsonKey(defaultValue: '') required this.id, @JsonKey(name: 'room_id', defaultValue: '') this.roomId = '', @JsonKey(name: 'author_id', defaultValue: '') this.authorId = '', @JsonKey(name: 'author_nick', defaultValue: '') this.authorNick = '', required this.text, this.translation, this.type = MessageType.text, this.status = MessageStatus.sent, required this.timestamp, @JsonKey(includeFromJson: false, includeToJson: false) this.source = MessageSource.other}): super._();
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(name: 'room_id', defaultValue: '') final  String roomId;
@override@JsonKey(name: 'author_id', defaultValue: '') final  String authorId;
@override@JsonKey(name: 'author_nick', defaultValue: '') final  String authorNick;
@override final  String text;
@override final  TranslationMessage? translation;
@override@JsonKey() final  MessageType type;
@override@JsonKey() final  MessageStatus status;
@override final  DateTime timestamp;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  MessageSource source;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorNick, authorNick) || other.authorNick == authorNick)&&(identical(other.text, text) || other.text == text)&&(identical(other.translation, translation) || other.translation == translation)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,authorId,authorNick,text,translation,type,status,timestamp,source);

@override
String toString() {
  return 'ChatMessage(id: $id, roomId: $roomId, authorId: $authorId, authorNick: $authorNick, text: $text, translation: $translation, type: $type, status: $status, timestamp: $timestamp, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(name: 'room_id', defaultValue: '') String roomId,@JsonKey(name: 'author_id', defaultValue: '') String authorId,@JsonKey(name: 'author_nick', defaultValue: '') String authorNick, String text, TranslationMessage? translation, MessageType type, MessageStatus status, DateTime timestamp,@JsonKey(includeFromJson: false, includeToJson: false) MessageSource source
});


@override $TranslationMessageCopyWith<$Res>? get translation;

}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? authorId = null,Object? authorNick = null,Object? text = null,Object? translation = freezed,Object? type = null,Object? status = null,Object? timestamp = null,Object? source = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorNick: null == authorNick ? _self.authorNick : authorNick // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,translation: freezed == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as TranslationMessage?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as MessageSource,
  ));
}

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TranslationMessageCopyWith<$Res>? get translation {
    if (_self.translation == null) {
    return null;
  }

  return $TranslationMessageCopyWith<$Res>(_self.translation!, (value) {
    return _then(_self.copyWith(translation: value));
  });
}
}

// dart format on
