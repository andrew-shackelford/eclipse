import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableLink extends StatelessWidget {
  final String text;
  final String url;
  final TextStyle? style;

  const ClickableLink({
    Key? key,
    required this.text,
    required this.url,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launch(url),
      child: Text(
        text,
        style: style ??
            const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
