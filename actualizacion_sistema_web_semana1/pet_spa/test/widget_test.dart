// Test básico de PetSpa — verifica que la app arranca correctamente.
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_spa/main.dart';

void main() {
  testWidgets('PetSpa app smoke test', (WidgetTester tester) async {
    // La clase principal de la app es PetSpaApp (no MyApp).
    // Este test solo verifica que la aplicación arranca sin errores.
    await tester.pumpWidget(const PetSpaApp());
    // Esperar a que se complete el primer frame
    await tester.pump();
    // Si llegamos aquí, la app inició correctamente
    expect(find.byType(PetSpaApp), findsOneWidget);
  });
}
