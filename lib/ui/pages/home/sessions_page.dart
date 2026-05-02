import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/style/app_style.dart';
import '../../../domain/models/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/widgets/glass_aware_app_bar.dart';
import '../../core/widgets/glass_aware_scaffold.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isGlass = ref.watch(styleModeProvider) == AppStyleMode.liquidGlass;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLight ? Colors.black87 : Colors.white;
    final glassSettings = LiquidGlassSettings(
      blur: isLight ? 12 : 8,
      thickness: 25,
      glassColor: isLight ? const Color(0x18000000) : const Color(0x30FFFFFF),
    );

    return GlassAwareScaffold(
      appBar: GlassAwareAppBar(
        title: Text(l10n.sessionsTitle),
        centerTitle: true,
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return _EmptyState(
              onNew: () async {
                await context.push('/sessions/new');
                ref.invalidate(sessionsProvider);
              },
              onJoin: () async {
                await context.push('/sessions/join');
                ref.invalidate(sessionsProvider);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: sessions.length,
            itemBuilder: (context, index) => _SessionCard(
              session: sessions[index],
              onTap: () => context.push('/sessions/${sessions[index].id}'),
              onLongPress: () => _showSessionActions(context, ref, sessions[index], l10n),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(l10n.errorMessage(e.toString())),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(sessionsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isGlass
            ? [
                GlassButton(
                  icon: Icon(Icons.qr_code_scanner, color: iconColor),
                  onTap: () async {
                    await context.push('/sessions/join');
                    ref.invalidate(sessionsProvider);
                  },
                  useOwnLayer: true,
                  settings: glassSettings,
                ),
                const SizedBox(width: 12),
                GlassButton.custom(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.sessionsNewTable,
                        style: TextStyle(
                            color: iconColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push('/sessions/new');
                    ref.invalidate(sessionsProvider);
                  },
                  width: 180,
                  height: 56,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                  useOwnLayer: true,
                  settings: glassSettings,
                ),
              ]
            : [
                FloatingActionButton(
                  heroTag: 'join',
                  onPressed: () async {
                    await context.push('/sessions/join');
                    ref.invalidate(sessionsProvider);
                  },
                  tooltip: l10n.sessionsJoinTooltip,
                  child: const Icon(Icons.qr_code_scanner),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'new',
                  onPressed: () async {
                    await context.push('/sessions/new');
                    ref.invalidate(sessionsProvider);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.sessionsNewTable),
                ),
              ],
      ),
    );
  }

  void _showSessionActions(
      BuildContext context, WidgetRef ref, Session session, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    session.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (session.status != SessionStatus.closed)
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: Text(l10n.sessionActionsLeaveTable),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.sessionLeaveTitle),
                        content: Text(l10n.sessionLeaveMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.leave),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(sessionsProvider.notifier).closeSession(session.id);
                    }
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.sessionDeleteTitle),
                      content: Text(l10n.sessionDeleteMessage(session.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(sessionsProvider.notifier).deleteSession(session.id);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SessionCard({required this.session, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final userAsync = ref.watch(profileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final restaurantName = restaurantsAsync.maybeWhen(
      data: (list) =>
          list.where((r) => r.id == session.restaurantId).firstOrNull?.name ??
          l10n.sessionCardUnknownRestaurant,
      orElse: () => '…',
    );

    final isHost = userAsync.value?.id == session.hostUserId;

    final (statusColor, statusLabel) = switch (session.status) {
      SessionStatus.open => (scheme.primary, l10n.sessionStatusOpen),
      SessionStatus.sent => (scheme.tertiary, l10n.sessionStatusSent),
      SessionStatus.closed => (scheme.outline, l10n.sessionStatusClosed),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.restaurant, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    restaurantName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outline, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${session.participantIds.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (isHost) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.sessionCardHost,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(l10n, session.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(AppLocalizations l10n, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.sessionTimeJustNow;
    if (diff.inMinutes < 60) return l10n.sessionTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.sessionTimeHoursAgo(diff.inHours);
    return l10n.sessionTimeDaysAgo(diff.inDays);
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onNew;
  final Future<void> Function() onJoin;

  const _EmptyState({required this.onNew, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: scheme.outline),
            const SizedBox(height: 16),
            Text(l10n.sessionsEmpty, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.sessionsEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: Text(l10n.sessionsNewTable),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.sessionsJoinTable),
            ),
          ],
        ),
      ),
    );
  }
}
