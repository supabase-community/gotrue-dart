import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart' show env, load;
import 'package:gotrue/gotrue.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:test/test.dart';

import 'custom_http_client.dart';

void main() {
  final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

  load(); // Load env variables from .env file

  final gotrueUrl = env['GOTRUE_URL'] ?? 'http://localhost:9998';
  final gotrueUrlWithAutoConfirmOff =
      env['GOTRUE_URL'] ?? 'http://localhost:9999';
  final anonToken = env['GOTRUE_TOKEN'] ?? 'anonKey';
  final email = env['GOTRUE_USER_EMAIL'] ?? 'fake$timestamp@email.com';
  final phone = env['GOTRUE_USER_PHONE'] ?? '166600000000';
  final password = env['GOTRUE_USER_PASS'] ?? 'secret';

  group('Client with default http client', () {
    late GoTrueClient client;
    late GoTrueClient clientWithAuthConfirmOff;

    int subscriptionCallbackCalledCount = 0;

    late StreamSubscription<AuthState> onAuthSubscription;

    setUpAll(() {
      client = GoTrueClient(
        url: gotrueUrl,
        headers: {
          'Authorization': 'Bearer $anonToken',
          'apikey': anonToken,
        },
      );
      clientWithAuthConfirmOff = GoTrueClient(
        url: gotrueUrlWithAutoConfirmOff,
        headers: {
          'Authorization': 'Bearer $anonToken',
          'apikey': anonToken,
        },
      );
      onAuthSubscription = client.onAuthStateChange.listen((_) {
        subscriptionCallbackCalledCount++;
      }, onError: (_) {});
    });

    test('basic json parsing', () async {
      const body =
          '{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjExODk1MzExLCJzdWIiOiI0Njg3YjkzNi02ZDE5LTRkNmUtOGIyYi1kYmU0N2I1ZjYzOWMiLCJlbWFpbCI6InRlc3Q5QGdtYWlsLmNvbSIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIn0sInVzZXJfbWV0YWRhdGEiOm51bGwsInJvbGUiOiJhdXRoZW50aWNhdGVkIn0.GyIokEvKGp0M8PYU8IiIpvzeTAXspoCtR5aj-jCnWys","token_type":"bearer","expires_in":3600,"refresh_token":"gnqAPZwZDj_XCYMF7U2Xtg","user":{"id":"4687b936-6d19-4d6e-8b2b-dbe47b5f639c","aud":"authenticated","role":"authenticated","email":"test9@gmail.com","confirmed_at":"2021-01-29T03:41:51.026791085Z","last_sign_in_at":"2021-01-29T03:41:51.032154484Z","app_metadata":{"provider":"email"},"user_metadata":null,"created_at":"2021-01-29T03:41:51.022787Z","updated_at":"2021-01-29T03:41:51.033826Z"}}';
      final bodyJson = json.decode(body);
      final session = Session.fromJson(bodyJson as Map<String, dynamic>);

      expect(session, isNotNull);
      expect(
        session!.accessToken,
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjExODk1MzExLCJzdWIiOiI0Njg3YjkzNi02ZDE5LTRkNmUtOGIyYi1kYmU0N2I1ZjYzOWMiLCJlbWFpbCI6InRlc3Q5QGdtYWlsLmNvbSIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIn0sInVzZXJfbWV0YWRhdGEiOm51bGwsInJvbGUiOiJhdXRoZW50aWNhdGVkIn0.GyIokEvKGp0M8PYU8IiIpvzeTAXspoCtR5aj-jCnWys',
      );
    });

    test('signUp() with email', () async {
      final response = await client.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://localhost:9998/welcome',
        data: {"Hello": "World"},
      );
      final data = response.session;
      expect(data?.accessToken, isA<String>());
      expect(data?.refreshToken, isA<String>());
      expect(data?.user.id, isA<String>());
      expect(data?.user.userMetadata, {"Hello": "World"});
    });

    test('Parsing invalid URL should emit Exception on onAuthStateChange',
        () async {
      expect(client.onAuthStateChange, emitsError(isA<AuthException>()));

      const expiresIn = 12345;
      const refreshToken = 'my_refresh_token';
      const tokenType = 'my_token_type';
      const providerToken = 'my_provider_token_with_fragment';

      final urlWithoutAccessToken = Uri.parse(
          'http://my-callback-url.com/welcome#expires_in=$expiresIn&refresh_token=$refreshToken&token_type=$tokenType&provider_token=$providerToken');
      try {
        await client.getSessionFromUrl(urlWithoutAccessToken);
        fail('getSessionFromUrl did not throw exception');
      } catch (_) {}
    });

    test('Subscribe a listener', () async {
      /// auth subsctiption callback has been called once with the signup above
      expect(subscriptionCallbackCalledCount, 1);

      /// unsubscribe to prevent further calling the callback
      onAuthSubscription.cancel();
    });

    test('signUp() with phone', () async {
      final response = await client.signUp(
        phone: phone,
        password: password,
        emailRedirectTo: 'https://localhost:9998/welcome',
        data: {"Hello": "World"},
      );
      final data = response.session;
      expect(data?.accessToken, isA<String>());
      expect(data?.refreshToken, isA<String>());
      expect(data?.user.id, isA<String>());
      expect(data?.user.userMetadata, {"Hello": "World"});
    });

    test('signUp() with autoConfirm off with email', () async {
      final response = await clientWithAuthConfirmOff.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://localhost:9999/welcome',
      );
      expect(response.user, isA<User>());
      expect(response.session, isNull);
    });

    test(
        'signUp() with autoConfirm off with phone should fail because Twilio is not setup',
        () async {
      try {
        await clientWithAuthConfirmOff.signUp(
          phone: phone,
          password: password,
        );
      } catch (error) {
        expect(error, isA<AuthException>());
      }
    });

    test('signUp() with email should throw error if used twice', () async {
      final localEmail = email;

      try {
        await client.signUp(email: localEmail, password: password);
      } catch (error) {
        expect(error, isA<AuthException>());
      }
    });

    test('signInWithOtp with email', () async {
      await client.signInWithOtp(email: email);
    });

    test('signInWithOtp with phone', () async {
      try {
        await client.signInWithOtp(phone: phone);
      } catch (error) {
        expect(error, isA<AuthException>());
      }
    });

    test('signInWithPassword() with email', () async {
      final response =
          await client.signInWithPassword(email: email, password: password);
      final data = response.session;

      expect(data?.accessToken, isA<String>());
      expect(data?.refreshToken, isA<String>());
      expect(data?.user.id, isA<String>());

      final payload = Jwt.parseJwt(data!.accessToken);
      final persistSession = json.decode(data.persistSessionString);
      expect(payload['exp'], persistSession['expiresAt']);
    });

    test('Get user', () async {
      final user = client.currentUser;
      expect(user, isNotNull);
      expect(user!.id, isA<String>());
      expect(user.appMetadata['provider'], 'email');
    });

    test('signInWithPassword() with phone', () async {
      final response =
          await client.signInWithPassword(phone: phone, password: password);
      final data = response.session;

      expect(data?.accessToken, isA<String>());
      expect(data?.refreshToken, isA<String>());
      expect(data?.user.id, isA<String>());

      final payload = Jwt.parseJwt(data!.accessToken);
      final persistSession = json.decode(data.persistSessionString);
      expect(payload['exp'], persistSession['expiresAt']);
    });

    test('Set session', () async {
      final refreshToken = client.currentSession?.refreshToken ?? '';
      expect(refreshToken, isNotEmpty);

      final newClient = GoTrueClient(
        url: gotrueUrl,
        headers: {
          'apikey': anonToken,
        },
      );

      expect(newClient.currentSession?.refreshToken ?? '', isEmpty);
      expect(newClient.currentSession?.accessToken ?? '', isEmpty);
      await newClient.setSession(refreshToken);
      expect(newClient.currentSession?.accessToken ?? '', isNotEmpty);
    });

    test('Update user', () async {
      final response = await client.updateUser(
        UserAttributes(data: {
          'hello': 'world',
          'japanese': '日本語',
          'korean': '한국어',
          'arabic': 'عربى',
        }),
      );
      final user = response.user;
      expect(user?.id, isA<String>());
      expect(user?.userMetadata?['hello'], 'world');
      expect(client.currentSession?.user.userMetadata?['hello'], 'world');
    });

    test('Get user after updating', () async {
      final user = client.currentUser;
      expect(user, isNotNull);
      expect(user?.id, isA<String>());
      expect(user?.userMetadata?['hello'], 'world');
      expect(user?.userMetadata?['japanese'], '日本語');
      expect(user?.userMetadata?['korean'], '한국어');
      expect(user?.userMetadata?['arabic'], 'عربى');
    });

    test('signOut', () async {
      await client.signOut();
    });

    test('Get user after logging out', () async {
      final user = client.currentUser;
      expect(user, isNull);
    });

    test('signIn() with the wrong password', () async {
      try {
        await client.signInWithPassword(
          email: email,
          password: 'wrong_$password',
        );
        fail('signInWithPassword did not throw');
      } on AuthException catch (error) {
        expect(error.message, isNotNull);
      }
    });

    test('Unsubscribe a listener works', () {
      /// Because we unsubscribed on subscription test, the callback should not longer be called.
      expect(subscriptionCallbackCalledCount, 1);
    });

    group('The auth client can signin with third-party oAuth providers', () {
      test('signIn() with Provider', () async {
        final res = await client.getOAuthSignInUrl(provider: Provider.google);
        expect(res.url, isA<String>());
        expect(res.provider, Provider.google);
      });

      test('signIn() with Provider with redirectTo', () async {
        final res = await client.getOAuthSignInUrl(
            provider: Provider.google, redirectTo: 'https://supabase.com');
        expect(res.url,
            '$gotrueUrl/authorize?provider=google&redirect_to=https%3A%2F%2Fsupabase.com');
        expect(res.provider, Provider.google);
      });

      test('signIn() with Provider can append a redirectUrl', () async {
        final res = await client.getOAuthSignInUrl(
            provider: Provider.google,
            redirectTo: 'https://localhost:9000/welcome');
        expect(res.url, isA<String>());
        expect(res.provider, Provider.google);
      });

      test('signIn() with Provider can append scopes', () async {
        final res = await client.getOAuthSignInUrl(
            provider: Provider.google, scopes: 'repo');
        expect(res.url, isA<String>());
        expect(res.provider, Provider.google);
      });

      test('signIn() with Provider can append options', () async {
        final res = await client.getOAuthSignInUrl(
            provider: Provider.google,
            redirectTo: 'https://localhost:9000/welcome',
            scopes: 'repo');
        expect(res.url, isA<String>());
        expect(res.provider, Provider.google);
      });
    });
  });

  group("Client with custom http client", () {
    late GoTrueClient client;

    setUpAll(() {
      client = GoTrueClient(
        url: gotrueUrl,
        httpClient: CustomHttpClient(),
      );
    });

    test('signIn()', () async {
      try {
        await client.signInWithPassword(email: email, password: password);
      } catch (error) {
        expect(error, isA<AuthException>());
        expect((error as AuthException).statusCode, '420');
      }
    });
  });
}
