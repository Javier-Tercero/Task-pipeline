/// What a guest's sign-up needs to remember across the app rebuild that
/// signing up and verifying cause (main.dart rebuilds the MaterialApp whenever
/// the session changes, which resets every screen).
///
/// Provided above the MaterialApp in main.dart, so it survives those rebuilds.
class GuestSignUpMemory {
  /// The project whose tasks the guest was looking at when they chose to sign
  /// up. Once their email is verified, the projects screen reopens it and then
  /// clears this, so later sign-ins start on the carousel as usual.
  String? returnToProjectId;

  /// The guest chose "Later" on the sign-up prompt, so it isn't shown again
  /// this session. The Sign up buttons stay available.
  bool promptDismissed = false;
}
