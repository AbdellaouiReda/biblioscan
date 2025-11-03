import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/Livre.dart';
import 'package:biblioscan/models/Bibliotheque.dart';

void main() {
  group('Validation positions des livres', () {
    test('Position valide dans la taille de la bibliothèque', () {
      final biblio = Bibliotheque(userId: 1, nom: 'Test', nbLignes: 2, nbColonnes: 3);
      final livre = Livre(
        biblioId: biblio.biblioId ?? 1,
        titre: 'Livre Test',
        positionLigne: 1,
        positionColonne: 2,
      );

      expect(livre.positionLigne < biblio.nbLignes, true);
      expect(livre.positionColonne < biblio.nbColonnes, true);
    });

    test('Position invalide détectée', () {
      final biblio = Bibliotheque(userId: 1, nom: 'Test', nbLignes: 2, nbColonnes: 3);
      final livre = Livre(
        biblioId: biblio.biblioId ?? 1,
        titre: 'Livre Test',
        positionLigne: 5, // Trop grand
        positionColonne: 1,
      );

      expect(livre.positionLigne >= biblio.nbLignes, true);
    });

    test('Nombre maximum de livres dans la bibliothèque', () {
      final biblio = Bibliotheque(userId: 1, nom: 'Test', nbLignes: 2, nbColonnes: 3);
      final maxBooks = biblio.nbLignes * biblio.nbColonnes;
      expect(maxBooks, 6);
    });
  });
}
