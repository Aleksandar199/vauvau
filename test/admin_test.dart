import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/admin/data/local_admin_repository.dart';
import 'package:vauvau/features/admin/presentation/admin_controller.dart';
import 'package:vauvau/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:vauvau/features/admin/presentation/admin_strings.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/data/seed_moments.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';

void main() {
  Future<void> pumpDashboard(WidgetTester tester, {required bool isAdmin}) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final adminRepo = LocalAdminRepository();
    addTearDown(adminRepo.dispose);
    final momentsRepo = LocalMomentsRepository(currentUserId: 'local-user');
    addTearDown(momentsRepo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(isAdmin),
          adminRepositoryProvider.overrideWith((ref) => adminRepo),
          momentsRepositoryProvider.overrideWith((ref) => momentsRepo),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('blocks non-admin users', (tester) async {
    await pumpDashboard(tester, isAdmin: false);

    expect(find.text(AdminStrings.denied), findsOneWidget);
    expect(find.text(AdminStrings.statsTab), findsNothing);
  });

  testWidgets('resolves and deletes feedback', (tester) async {
    await pumpDashboard(tester, isAdmin: true);

    expect(find.text(AdminStrings.statsTab), findsOneWidget);
    expect(find.text('Mapa se sporo učitava'), findsOneWidget);
    expect(find.text(AdminStrings.isNew), findsOneWidget);

    await tester.tap(find.text(AdminStrings.resolve));
    await tester.pump();
    await tester.pump();
    expect(find.text(AdminStrings.resolve), findsNothing);
    expect(find.text(AdminStrings.resolved), findsNWidgets(2));

    await tester.tap(find.text(AdminStrings.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AdminStrings.confirm));
    await tester.pumpAndSettle();
    expect(find.text('Mapa se sporo učitava'), findsNothing);
  });

  testWidgets('deletes a moment and lists users', (tester) async {
    await pumpDashboard(tester, isAdmin: true);

    await tester.ensureVisible(find.text(AdminStrings.contentTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AdminStrings.contentTab));
    await tester.pumpAndSettle();
    final caption = SeedMoments.all.first.caption;
    expect(find.text(caption), findsOneWidget);

    await tester.tap(find.text(AdminStrings.deleteMoment).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AdminStrings.confirm));
    await tester.pumpAndSettle();
    expect(find.text(caption), findsNothing);

    await tester.ensureVisible(find.text(AdminStrings.usersTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AdminStrings.usersTab));
    await tester.pumpAndSettle();
    expect(find.text(AdminStrings.totalUsers(2)), findsOneWidget);
    expect(find.text('Milica'), findsOneWidget);
    expect(find.text(AdminStrings.adminBadge), findsOneWidget);
  });
}
