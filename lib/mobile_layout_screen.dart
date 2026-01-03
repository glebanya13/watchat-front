import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/utils/colors.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/features/group/screens/create_group_screen.dart';
import 'package:watchat/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:watchat/features/chat/widgets/contacts_list.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileLayoutScreen> createState() => _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        centerTitle: false,
        title: const Text(
          'WatChat',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text(
                  'Создать группу',
                ),
                onTap: () => Future(
                  () => Navigator.pushNamed(
                      context, CreateGroupScreen.routeName),
                ),
              ),
              PopupMenuItem(
                child: const Text(
                  'Профиль',
                ),
                onTap: () => Future(
                  () => Navigator.pushNamed(
                      context, '/profile'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: const ContactsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, SelectContactsScreen.routeName);
        },
        backgroundColor: tabColor,
        child: const Icon(
          Icons.comment,
          color: Colors.white,
        ),
      ),
    );
  }
}
