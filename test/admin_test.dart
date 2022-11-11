import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart' show env, load;
import 'package:gotrue/gotrue.dart';
import 'package:test/test.dart';

void main() {
  load(); // Load env variables from .env file

  final gotrueUrl = env['GOTRUE_URL'] ?? 'http://localhost:9998';
  final unregistredUserEmail = 'new${Random.secure().nextInt(4096)}@fake.org';
  final password = env['GOTRUE_USER_PASS'] ?? 'secret';

  final serviceRoleToken = JWT(
    {
      'role': 'service_role',
    },
  ).sign(
    SecretKey(
        env['GOTRUE_JWT_SECRET'] ?? '37c304f8-51aa-419a-a1af-06154e63707a'),
  );

  late GoTrueClient client;
  late String targetUserId;

  setUpAll(() {
    client = GoTrueClient(
      url: gotrueUrl,
      headers: {
        'Authorization': 'Bearer $serviceRoleToken',
        'apikey': serviceRoleToken,
      },
    );
  });

  group('User fetch', () {
    test(
        'getUserById() should return a registered user given its user identifier',
        () async {
      final sessionResponse =
          await client.signUp(email: unregistredUserEmail, password: password);
      final createdUser = sessionResponse.user;
      expect(createdUser, isNotNull);
      targetUserId = createdUser!.id;
      final foundUserResponse = await client.admin.getUserById(targetUserId);
      expect(foundUserResponse.user, isNotNull);
      expect(foundUserResponse.user?.email, unregistredUserEmail);
    });
  });

  group('User updates', () {
    test('modify email using updateUserById()', () async {
      final res = await client.admin.updateUserById(targetUserId,
          attributes: AdminUserAttributes(email: 'new@email.com'));
      expect(res.user!.email, 'new@email.com');
    });

    test('modify userMetadata using updateUserById()', () async {
      final res = await client.admin.updateUserById(targetUserId,
          attributes:
              AdminUserAttributes(userMetadata: {'username': 'newUserName'}));
      expect(res.user!.userMetadata!['username'], 'newUserName');
    });
  });

  group('User registration', () {
    test(
        'generateLink() supports signUp with generate confirmation signup link ',
        () async {
      const userMetadata = {'status': 'alpha'};

      final response = await client.admin.generateLink(
        type: GenerateLinkType.signup,
        email: unregistredUserEmail,
        password: password,
        data: userMetadata,
        redirectTo: 'http://localhost:9999/welcome',
      );

      expect(response.user, isNotNull);

      final actionLink = response.properties.actionLink;

      final actionUri = Uri.tryParse(actionLink);
      expect(actionUri, isNotNull);

      expect(actionUri!.queryParameters['token'], isNotEmpty);
      expect(actionUri.queryParameters['type'], isNotEmpty);
      expect(actionUri.queryParameters['redirect_to'],
          'http://localhost:9999/welcome');
    });

    test('inviteUserByEmail() creates a new user with an invited_at timestamp',
        () async {
      final newEmail = 'new${Random.secure().nextInt(4096)}@fake.org';
      final res = await client.admin.inviteUserByEmail(newEmail);
      expect(res.user, isNotNull);
      expect(res.user?.email, newEmail);
      expect(res.user?.invitedAt, isNotNull);
    });

    test('createUser() creates a new user', () async {
      final newEmail = 'new${Random.secure().nextInt(4096)}@fake.org';
      final userMetadata = {"name": "supabase"};
      final res = await client.admin.createUser(
          AdminUserAttributes(email: newEmail, userMetadata: userMetadata));
      expect(res.user, isNotNull);
      expect(res.user?.email, newEmail);
      expect(res.user?.userMetadata, userMetadata);
    });
  });

  group("User deletion", () {
    test("deleteUser() deletes an user", () async {
      final newUser = await client.admin.createUser(AdminUserAttributes(
        email: 'new${Random.secure().nextInt(4096)}@fake.org',
        password: password,
      ));
      final userLengthBefore = (await client.admin.listUsers()).length;
      await client.admin.deleteUser(newUser.user!.id);
      final userLengthAfter = (await client.admin.listUsers()).length;
      expect(userLengthBefore - 1, userLengthAfter);
    });
  });
}
