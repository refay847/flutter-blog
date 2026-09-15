// lib/core/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final topInset = MediaQuery.of(context).padding.top;

    // Collapsed height is 0 either way; expanded height includes the
    // status bar's own height so the text never sits under the clock.
    final expandedHeight = topInset + 44;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isOnline ? 0 : expandedHeight,
      width: double.infinity,
      color: Colors.redAccent,
      child: isOnline
          ? null
          : Padding(
              padding: EdgeInsets.only(top: topInset),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "You're offline — showing saved stories",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}