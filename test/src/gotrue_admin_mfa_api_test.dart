import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart' show env, load;
import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  load(); // Load env variables from .env file

  final gotrueUrl = env['GOTRUE_URL'] ?? 'http://localhost:9998';
  final serviceRoleToken = JWT(
    {'role': 'service_role'},
  ).sign(
    SecretKey(
        env['GOTRUE_JWT_SECRET'] ?? '37c304f8-51aa-419a-a1af-06154e63707a'),
  );

  /// User ID of the user with verified factor
  const userId2 = "28bc7a4e-c095-4573-93dc-e0be29bada97";
  /// Factor ID of `userId2`
  const factorId2 = "2d3aa138-da96-4aea-8217-af07daa6b82d";

  late GoTrueClient client;

  setUp(() async {
    final res = await http.post(
        Uri.parse("http://localhost:3000/rpc/reset_and_init_auth_data"),
        headers: {'x-forwarded-for': '127.0.0.1'});
    if (res.body.isNotEmpty) throw res.body;

    client = GoTrueClient(
      url: gotrueUrl,
      headers: {
        'Authorization': 'Bearer $serviceRoleToken',
        'apikey': serviceRoleToken,
        'x-forwarded-for': '127.0.0.1'
      },
    );
  });

  test("list factors", () async {
    final res = await client.admin.mfa.listFactors(userId2);
    expect(res.factors.length, 1);
    final factor = res.factors.first;
    expect(factor.createdAt.difference(DateTime.now()) < Duration(seconds: 2),
        true);
    expect(factor.updatedAt.difference(DateTime.now()) < Duration(seconds: 2),
        true);
    expect(factor.id, factorId2);
  });

  test("delete factor", () async {
    final res = await client.admin.mfa.deleteFactor(userId2, factorId2);
    expect(res.id, factorId2);
  });
}
