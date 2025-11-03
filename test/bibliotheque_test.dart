import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/Bibliotheque.dart';

void main() {
  group('Bibliotheque Model Tests', () {
    test('Création de bibliothèque', () {
      final biblio = Bibliotheque(
        userId: 42,
        nom: 'Bibliothèque Test',
        nbLignes: 2,
        nbColonnes: 3,
      );

      expect(biblio.nom, 'Bibliothèque Test');
      expect(biblio.nbLignes, 2);
      expect(biblio.nbColonnes, 3);
      expect(biblio.userId, 42);
    });

    test('Taille totale de la bibliothèque (nbLignes × nbColonnes)', () {
      final biblio = Bibliotheque(userId: 1, nom: 'Test', nbLignes: 3, nbColonnes: 4);
      final total = biblio.nbLignes * biblio.nbColonnes;
      expect(total, 12);
    });
  });
}
