/// [value] when it is a string with visible content, otherwise null.
///
/// For optional API strings where `""` means "not set" as much as `null`
/// does — e.g. a photo URL, which must not be handed to an image loader
/// when blank.
String? nonEmptyString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
