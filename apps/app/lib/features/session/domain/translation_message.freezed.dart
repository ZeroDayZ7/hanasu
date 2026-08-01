// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranslationMessage {

 String get text;@JsonKey(name: 'source_language', defaultValue: '') String get sourceLanguage;@JsonKey(name: 'target_language', defaultValue: '') String get targetLanguage;@JsonKey(name: 'translated_at') DateTime get translatedAt;
/// Create a copy of TranslationMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationMessageCopyWith<TranslationMessage> get copyWith => _$TranslationMessageCopyWithImpl<TranslationMessage>(this as TranslationMessage, _$identity);

  /// Serializes this TranslationMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationMessage&&(identical(other.text, text) || other.text == text)&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&(identical(other.targetLanguage, targetLanguage) || other.targetLanguage == targetLanguage)&&(identical(other.translatedAt, translatedAt) || other.translatedAt == translatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,sourceLanguage,targetLanguage,translatedAt);

@override
String toString() {
  return 'TranslationMessage(text: $text, sourceLanguage: $sourceLanguage, targetLanguage: $targetLanguage, translatedAt: $translatedAt)';
}


}

/// @nodoc
abstract mixin class $TranslationMessageCopyWith<$Res>  {
  factory $TranslationMessageCopyWith(TranslationMessage value, $Res Function(TranslationMessage) _then) = _$TranslationMessageCopyWithImpl;
@useResult
$Res call({
 String text,@JsonKey(name: 'source_language', defaultValue: '') String sourceLanguage,@JsonKey(name: 'target_language', defaultValue: '') String targetLanguage,@JsonKey(name: 'translated_at') DateTime translatedAt
});




}
/// @nodoc
class _$TranslationMessageCopyWithImpl<$Res>
    implements $TranslationMessageCopyWith<$Res> {
  _$TranslationMessageCopyWithImpl(this._self, this._then);

  final TranslationMessage _self;
  final $Res Function(TranslationMessage) _then;

/// Create a copy of TranslationMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? sourceLanguage = null,Object? targetLanguage = null,Object? translatedAt = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sourceLanguage: null == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String,targetLanguage: null == targetLanguage ? _self.targetLanguage : targetLanguage // ignore: cast_nullable_to_non_nullable
as String,translatedAt: null == translatedAt ? _self.translatedAt : translatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationMessage].
extension TranslationMessagePatterns on TranslationMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationMessage value)  $default,){
final _that = this;
switch (_that) {
case _TranslationMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationMessage value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text, @JsonKey(name: 'source_language', defaultValue: '')  String sourceLanguage, @JsonKey(name: 'target_language', defaultValue: '')  String targetLanguage, @JsonKey(name: 'translated_at')  DateTime translatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationMessage() when $default != null:
return $default(_that.text,_that.sourceLanguage,_that.targetLanguage,_that.translatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text, @JsonKey(name: 'source_language', defaultValue: '')  String sourceLanguage, @JsonKey(name: 'target_language', defaultValue: '')  String targetLanguage, @JsonKey(name: 'translated_at')  DateTime translatedAt)  $default,) {final _that = this;
switch (_that) {
case _TranslationMessage():
return $default(_that.text,_that.sourceLanguage,_that.targetLanguage,_that.translatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text, @JsonKey(name: 'source_language', defaultValue: '')  String sourceLanguage, @JsonKey(name: 'target_language', defaultValue: '')  String targetLanguage, @JsonKey(name: 'translated_at')  DateTime translatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TranslationMessage() when $default != null:
return $default(_that.text,_that.sourceLanguage,_that.targetLanguage,_that.translatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationMessage implements TranslationMessage {
  const _TranslationMessage({required this.text, @JsonKey(name: 'source_language', defaultValue: '') required this.sourceLanguage, @JsonKey(name: 'target_language', defaultValue: '') required this.targetLanguage, @JsonKey(name: 'translated_at') required this.translatedAt});
  factory _TranslationMessage.fromJson(Map<String, dynamic> json) => _$TranslationMessageFromJson(json);

@override final  String text;
@override@JsonKey(name: 'source_language', defaultValue: '') final  String sourceLanguage;
@override@JsonKey(name: 'target_language', defaultValue: '') final  String targetLanguage;
@override@JsonKey(name: 'translated_at') final  DateTime translatedAt;

/// Create a copy of TranslationMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationMessageCopyWith<_TranslationMessage> get copyWith => __$TranslationMessageCopyWithImpl<_TranslationMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationMessage&&(identical(other.text, text) || other.text == text)&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&(identical(other.targetLanguage, targetLanguage) || other.targetLanguage == targetLanguage)&&(identical(other.translatedAt, translatedAt) || other.translatedAt == translatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,sourceLanguage,targetLanguage,translatedAt);

@override
String toString() {
  return 'TranslationMessage(text: $text, sourceLanguage: $sourceLanguage, targetLanguage: $targetLanguage, translatedAt: $translatedAt)';
}


}

/// @nodoc
abstract mixin class _$TranslationMessageCopyWith<$Res> implements $TranslationMessageCopyWith<$Res> {
  factory _$TranslationMessageCopyWith(_TranslationMessage value, $Res Function(_TranslationMessage) _then) = __$TranslationMessageCopyWithImpl;
@override @useResult
$Res call({
 String text,@JsonKey(name: 'source_language', defaultValue: '') String sourceLanguage,@JsonKey(name: 'target_language', defaultValue: '') String targetLanguage,@JsonKey(name: 'translated_at') DateTime translatedAt
});




}
/// @nodoc
class __$TranslationMessageCopyWithImpl<$Res>
    implements _$TranslationMessageCopyWith<$Res> {
  __$TranslationMessageCopyWithImpl(this._self, this._then);

  final _TranslationMessage _self;
  final $Res Function(_TranslationMessage) _then;

/// Create a copy of TranslationMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? sourceLanguage = null,Object? targetLanguage = null,Object? translatedAt = null,}) {
  return _then(_TranslationMessage(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sourceLanguage: null == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String,targetLanguage: null == targetLanguage ? _self.targetLanguage : targetLanguage // ignore: cast_nullable_to_non_nullable
as String,translatedAt: null == translatedAt ? _self.translatedAt : translatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
