import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/Livre.dart';

void main() {
  group('Livre Model Tests', () {
    test('Création de Livre avec valeurs par défaut', () {
      final livre = Livre(
        biblioId: 1,
        titre: 'Test',
        positionLigne: 0,
        positionColonne: 1,
      );

      expect(livre.titre, 'Test');
      expect(livre.auteur, isNull);
      expect(livre.positionLigne, 0);
      expect(livre.positionColonne, 1);
    });

    test('Vérifie que deux livres différents ne sont pas égaux', () {
      final livre1 = Livre(biblioId: 1, titre: 'A', positionLigne: 0, positionColonne: 0);
      final livre2 = Livre(biblioId: 1, titre: 'B', positionLigne: 1, positionColonne: 0);

      expect(livre1 == livre2, isFalse);
    });
  });
}
