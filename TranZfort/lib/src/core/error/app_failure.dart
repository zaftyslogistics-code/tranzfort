import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppFailureType {
  network,
  auth,
  validation,
  conflict,
  notFound,
  forbidden,
  serverError,
  unknown,
}

AppFailureType classifyError(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return AppFailureType.network;
  }
  if (error is AuthException) {
    return AppFailureType.auth;
  }
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return AppFailureType.conflict; // UNIQUE violation
    }
    if (error.code == '42501') return AppFailureType.forbidden; // RLS denied
    if (error.code == 'PGRST116') return AppFailureType.notFound;
    return AppFailureType.serverError;
  }
  return AppFailureType.unknown;
}
