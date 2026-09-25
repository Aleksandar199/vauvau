import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:vauvau/features/admin/presentation/admin_strings.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/map/domain/models/poi_model.dart';
import 'package:vauvau/features/map/presentation/user_poi_controller.dart';
import 'package:vauvau/features/moderation/domain/content_report.dart';
import 'package:vauvau/features/moderation/presentation/report_controller.dart';
import 'package:vauvau/features/profile/presentation/profile_screen.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';

final _pendingPoi = PoiModel(
  id: 'pending-cafe',
  name: 'Kafić na čekanju',
  category: PoiCategory.cafe,
  address: 'Bulevar 1',
  latitude: 45.25,
  longitude: 19.84,
  lastVerified: DateTime.utc(2026, 1, 1),
  source: 'VauVau Zajednica',
  verificationStatus: PoiVerificationStatus.pending,
);

final _report = ContentReport(
  id: 'r1',
  reportedByUserId: 'u1',
  contentType: ReportContentType.dog,
  targetId: 'dog-1',
  reason: 'Neprikladan sadržaj',
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('hides Admin Panel for regular users', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pump();
    expect(find.text(ProfileStrings.adminPanel), findsNothing);
  });

  testWidgets('denies dashboard without admin role', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();
    expect(find.text(AdminStrings.denied), findsOneWidget);
  });

  testWidgets('admin can review pending POIs and reports', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWith((ref) => true),
          pendingPoisProvider.overrideWith((ref) => [_pendingPoi]),
          activeReportsProvider.overrideWith((ref) => [_report]),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(
                uid: 'admin',
                email: 'admin@vauvau.local',
                role: UserRole.admin,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();
    expect(find.text(AdminStrings.pendingTab), findsOneWidget);
    expect(find.text('Kafić na čekanju'), findsOneWidget);
    expect(find.text(AdminStrings.approve), findsOneWidget);

    await tester.tap(find.text(AdminStrings.reportsTab));
    await tester.pumpAndSettle();
    expect(find.text('Neprikladan sadržaj'), findsOneWidget);
    expect(find.text(AdminStrings.block), findsOneWidget);
  });
}
