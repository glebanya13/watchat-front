import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:watchat/common/widgets/loader.dart';

import 'package:watchat/models/status_model.dart';

class StatusScreen extends StatefulWidget {
  static const String routeName = '/status-screen';
  final Status status;
  const StatusScreen({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  
  

  @override
  void initState() {
    super.initState();
    
  }

  
  
  
  
  
  
  
  

  @override
  Widget build(BuildContext context) {
    
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Статус'),
        ),
        body: widget.status.photoUrl.isEmpty
            ? const SizedBox.shrink()
            : PageView.builder(
                itemCount: widget.status.photoUrl.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          widget.status.photoUrl[index],
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 64);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Статус ${index + 1} из ${widget.status.photoUrl.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    }

    
    return Scaffold(
      body: const Center(
        child: Text('Статусы временно недоступны'),
      ),
    );
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  }
}
