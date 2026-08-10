import 'package:edugain/core/ui/user_photo.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server stores avatars as a path, not a URL. Resolving it is the one
/// piece of logic between "the picture exists" and "the picture is on screen",
/// and getting it wrong is silent — an unreachable URL just draws initials, the
/// same as no picture at all, which is exactly how the previous avatar bug
/// stayed invisible for weeks.
void main() {
  test('nothing to show stays nothing', () {
    expect(UserPhoto.resolve(null), isNull);
    expect(UserPhoto.resolve(''), isNull);
    expect(UserPhoto.resolve('   '), isNull);
  });

  test('an absolute URL is left alone', () {
    // Google sign-in still stores a full URL, and so does any older account.
    expect(
      UserPhoto.resolve('https://example.com/a.jpg'),
      'https://example.com/a.jpg',
    );
  });

  test('a stored path is resolved against the API host', () {
    // Tests run on the VM, where the API base is a real absolute URL — the
    // Android case. The path the server stores has to end up pointing at the
    // API host and not at nothing.
    final resolved = UserPhoto.resolve('/api/v1/auth/avatar/777.jpg')!;
    final uri = Uri.parse(resolved);
    expect(uri.hasScheme, isTrue);
    expect(uri.host, isNotEmpty);
    expect(uri.path, '/api/v1/auth/avatar/777.jpg');
    // A query left over from the base would send the request somewhere odd.
    expect(uri.hasQuery, isFalse);
  });

  test('junk that is neither absolute nor rooted is refused', () {
    // Better to draw initials than to hand Image.network something it will
    // resolve against whatever origin happens to be current.
    expect(UserPhoto.resolve('avatar.jpg'), isNull);
    expect(UserPhoto.resolve('../secret'), isNull);
  });
}
