/// Whether this learner still has to join our Telegram channel.
///
/// `mustJoin` is the server's single verdict, and every "let them through"
/// case is already folded into it: the gate is switched off, the learner has
/// no Telegram account we could check, or Telegram would not answer. The
/// client deliberately does not re-derive any of that — it has less
/// information than the server and would only get it wrong differently.
class ChannelGate {
  const ChannelGate({
    required this.username,
    required this.url,
    required this.mustJoin,
    required this.subscribed,
  });

  final String username;
  final String url;
  final bool mustJoin;
  final bool subscribed;

  /// No gate. Used whenever we could not get an answer — see the controller.
  static const open = ChannelGate(
    username: '',
    url: '',
    mustJoin: false,
    subscribed: false,
  );

  factory ChannelGate.fromJson(Map<String, dynamic> json) => ChannelGate(
    username: json['username'] as String? ?? '',
    url: json['url'] as String? ?? '',
    // A response we cannot read opens the gate rather than shutting it: being
    // wrong the other way locks people out of the whole product.
    mustJoin: json['required'] as bool? ?? false,
    subscribed: json['subscribed'] as bool? ?? false,
  );
}
