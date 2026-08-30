/// Status of a one-shot mutation against the `/rider/me/*` API.
///
/// Deliberately separate from each feature's list/load status so an
/// in-flight write doesn't hide already-loaded data behind a spinner.
///
/// Shared by the profile, orders and wallet providers — defining it per
/// feature would make any file importing two of them ambiguous.
enum RiderMeActionStatus { idle, inProgress, success, error }
