import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/router/app_router.dart';
import 'package:miva_fid/core/router/client_router.dart';
import 'package:miva_fid/core/router/merchant_router.dart';
import 'package:miva_fid/core/utils/loading_overlay_service.dart';
import 'package:miva_fid/core/utils/toast_service.dart';

void main() {
  tearDown(() async {
    ToastService.hideCurrent();
    await LoadingOverlayService.hide();
    ToastService.navigatorKey = rootNavigatorKey;
    LoadingOverlayService.navigatorKey = rootNavigatorKey;
  });

  testWidgets(
      'ToastService et LoadingOverlayService affichent les erreurs sur Client PWA (clientNavigatorKey)',
      (tester) async {
    ToastService.navigatorKey = clientNavigatorKey;
    LoadingOverlayService.navigatorKey = clientNavigatorKey;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: clientNavigatorKey,
        scaffoldMessengerKey: ToastService.messengerKey,
        home: const Scaffold(body: Text('Client Home')),
      ),
    );

    ToastService.showError('Identifiants client incorrects.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Identifiants client incorrects.'), findsOneWidget);

    ToastService.hideCurrent();
    await tester.pump();

    LoadingOverlayService.show(message: 'Chargement client...');
    await tester.pump();
    expect(find.text('Chargement client...'), findsOneWidget);

    await LoadingOverlayService.hide();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'ToastService et LoadingOverlayService affichent les erreurs et toasts push sur Marchand PWA (merchantNavigatorKey)',
      (tester) async {
    ToastService.navigatorKey = merchantNavigatorKey;
    LoadingOverlayService.navigatorKey = merchantNavigatorKey;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: merchantNavigatorKey,
        scaffoldMessengerKey: ToastService.messengerKey,
        home: const Scaffold(body: Text('Merchant Home')),
      ),
    );

    ToastService.showError('Erreur serveur marchand.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Erreur serveur marchand.'), findsOneWidget);

    ToastService.hideCurrent();
    await tester.pump();

    ToastService.showCampaign(
      title: 'Offre spéciale',
      body: '-20% aujourd’hui',
      campaignId: '99',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Offre spéciale'), findsOneWidget);
    expect(find.text('-20% aujourd’hui'), findsOneWidget);

    ToastService.hideCurrent();
    await tester.pump();
  });

  testWidgets(
      'ToastService bascule sur SnackBar si aucun Overlay n est encore monté',
      (tester) async {
    final detachedKey = GlobalKey<NavigatorState>();
    ToastService.navigatorKey = detachedKey;

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: ToastService.messengerKey,
        home: const Scaffold(body: Text('Bootstrapping')),
      ),
    );

    ToastService.showError('Erreur au démarrage');
    await tester.pump();

    expect(find.text('Erreur au démarrage'), findsOneWidget);
  });
}
