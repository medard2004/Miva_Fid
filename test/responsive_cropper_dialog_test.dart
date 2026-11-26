import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/services/image_upload_service.dart';

void main() {
  testWidgets(
      'ResponsiveWebCropperDialog s adapte sans debordement sur mobile (360x640)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var initialized = false;
    String? poppedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                poppedResult = await showDialog<String?>(
                  context: context,
                  builder: (_) => ResponsiveWebCropperDialog(
                    cropper: const Placeholder(),
                    initCropper: () => initialized = true,
                    crop: () async => 'blob:cropped-logo',
                    rotate: (_) {},
                    scale: (_) {},
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(initialized, isTrue);
    expect(find.text("Recadrer l'image"), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(poppedResult, 'blob:cropped-logo');
  });

  testWidgets(
      'ResponsiveWebCropperDialog s adapte sans debordement sur desktop (1280x800)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveWebCropperDialog(
            cropper: const Placeholder(),
            initCropper: () {},
            crop: () async => null,
            rotate: (_) {},
            scale: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Recadrer l'image"), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
  });
}
