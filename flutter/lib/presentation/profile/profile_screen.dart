import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Пользователь', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LoggedOut());
              },
              child: const Text('Выйти из аккаунта'),
            ),
          ],
        ),
      ),
    );
  }
}