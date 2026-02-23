import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'package:flutter/material.dart';

final taskCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return 0;
  final res = await http.get(
    Uri.parse("https://kanban.jokeped.xyz/tasks/assignee/${user.id}"),
  );
  if (res.statusCode != 200) return 0;

  final data = jsonDecode(res.body);
  return data.length;
});

final reminderCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return 0;

  final res = await http.get(
    Uri.parse("https://kanban.jokeped.xyz/reminders/user/${user.id}"),
  );

  if (res.statusCode != 200) return 0;

  final data = jsonDecode(res.body);
  return data.length;
});