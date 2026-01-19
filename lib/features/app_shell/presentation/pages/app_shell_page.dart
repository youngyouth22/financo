import 'package:flutter/material.dart';


class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

	@override
	createState() => _AppShellPage();
}
class _AppShellPage extends State<AppShellPage> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(),
		);
	}
}
