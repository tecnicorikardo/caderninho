import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales')
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.metadata.hasPendingWrites);

    return StreamBuilder<bool>(
      stream: stream,
      initialData: false,
      builder: (context, snapshot) {
        final pending = snapshot.data ?? false;
        return Chip(
          avatar: Icon(
            pending ? Icons.sync : Icons.cloud_done,
            size: 16,
            color: pending ? Colors.orange : Colors.green,
          ),
          label: Text(pending ? 'Sincronizando' : 'Sincronizado'),
        );
      },
    );
  }
}
