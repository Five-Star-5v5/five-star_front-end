import 'dart:js' as js;

String? jsEnvLookup(String key) {
  final env = js.context.hasProperty('env') ? js.context['env'] : null;
  if (env != null && env.hasProperty(key) && env[key] != null) {
    final val = env[key] as String;
    return val.isNotEmpty ? val : null;
  }
  return null;
}
