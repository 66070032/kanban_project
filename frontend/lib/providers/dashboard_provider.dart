import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'auth_provider.dart';

final taskCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return 0;
  final res = await http.get(
    Uri.parse("${AppConfig.baseUrl}/tasks/assignee/${user.id}"),
  );
  if (res.statusCode != 200) return 0;

  final data = jsonDecode(res.body);
  return data.length;
});

final reminderCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return 0;

  final res = await http.get(
    Uri.parse("${AppConfig.baseUrl}/reminders/user/${user.id}"),
  );

  if (res.statusCode != 200) return 0;

  final data = jsonDecode(res.body);
  return data.length;
});
