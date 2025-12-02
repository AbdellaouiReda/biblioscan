import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/bibliotheque.dart';

void main() {
  group('Bibliotheque Model Tests', () {
    // Test 1 : Créer une bibliothèque complète
    test('Création d\'une bibliothèque complète', () {
      // On crée une bibliothèque avec toutes les infos
      final biblio = Bibliotheque(
        biblioId: 1,
        userId: 10,
        nom: 'Ma Bibliothèque Principale',
        nbLignes: 5,
        nbColonnes: 8,
        token: 'biblio_token_xyz',
      );

      // Vérification de toutes les propriétés
      expect(biblio.biblioId, 1);
      expect(biblio.userId, 10);
      expect(biblio.nom, 'Ma Bibliothèque Principale');
      expect(biblio.nbLignes, 5);
      expect(biblio.nbColonnes, 8);
      expect(biblio.token, 'biblio_token_xyz');
    });

    // Test 2 : Créer une nouvelle bibliothèque (sans ID)
    test('Création d\'une nouvelle bibliothèque (sans ID)', () {
      // Quand on crée une nouvelle bibliothèque, elle n'a pas encore d'ID
      final biblio = Bibliotheque(
        userId: 25,
        nom: 'Bibliothèque du Salon',
        nbLignes: 3,
        nbColonnes: 4,
      );

      expect(biblio.nom, 'Bibliothèque du Salon');
      expect(biblio.userId, 25);
      expect(biblio.nbLignes, 3);
      expect(biblio.nbColonnes, 4);
      expect(biblio.biblioId, isNull); // Pas encore d'ID serveur
      expect(biblio.token, isNull); // Pas encore de token
    });

    // Test 3 : Conversion vers JSON (toJson)
    test('Conversion Bibliotheque vers JSON (toJson)', () {
      final biblio = Bibliotheque(
        biblioId: 7,
        userId: 50,
        nom: 'Bibliothèque de Bureau',
        nbLignes: 4,
        nbColonnes: 6,
        token: 'bureau_token',
      );

      // Conversion en JSON
      final json = biblio.toJson();

      // Vérifications du JSON
      expect(json['biblio_id'], 7);
      expect(json['user_id'], 50);
      expect(json['nom'], 'Bibliothèque de Bureau');
      expect(json['nb_lignes'], 4);
      expect(json['nb_colonnes'], 6);
      expect(json['token'], 'bureau_token');
    });

    // Test 4 : Création depuis JSON (fromJson)
    test('Création d\'une bibliothèque depuis JSON (fromJson)', () {
      // Simulation d'une réponse API
      final json = {
        'biblio_id': 15,
        'user_id': 100,
        'nom': 'Bibliothèque Chambre',
        'nb_lignes': 2,
        'nb_colonnes': 3,
        'token': 'chambre_token_abc',
      };

      // Création depuis JSON
      final biblio = Bibliotheque.fromJson(json);

      // Vérifications
      expect(biblio.biblioId, 15);
      expect(biblio.userId, 100);
      expect(biblio.nom, 'Bibliothèque Chambre');
      expect(biblio.nbLignes, 2);
      expect(biblio.nbColonnes, 3);
      expect(biblio.token, 'chambre_token_abc');
    });

    // Test 5 : Tester les dimensions de la bibliothèque
    test('Dimensions de la bibliothèque valides', () {
      // Une petite bibliothèque
      final petiteBiblio = Bibliotheque(
        userId: 1,
        nom: 'Petite Étagère',
        nbLignes: 1,
        nbColonnes: 3,
      );

      // Une grande bibliothèque
      final grandeBiblio = Bibliotheque(
        userId: 1,
        nom: 'Grande Bibliothèque',
        nbLignes: 10,
        nbColonnes: 15,
      );

      expect(petiteBiblio.nbLignes, 1);
      expect(petiteBiblio.nbColonnes, 3);
      expect(grandeBiblio.nbLignes, 10);
      expect(grandeBiblio.nbColonnes, 15);
    });

    // Test 6 : fromJson avec valeurs manquantes
    test('fromJson avec biblioId et token null', () {
      final json = {
        'user_id': 77,
        'nom': 'Nouvelle Biblio',
        'nb_lignes': 3,
        'nb_colonnes': 5,
      };

      final biblio = Bibliotheque.fromJson(json);

      expect(biblio.nom, 'Nouvelle Biblio');
      expect(biblio.userId, 77);
      expect(biblio.biblioId, isNull);
      expect(biblio.token, isNull);
    });

    // Test 7 : Aller-retour JSON complet
    test('Aller-retour JSON : toJson puis fromJson', () {
      // Bibliothèque originale
      final biblioOriginale = Bibliotheque(
        biblioId: 99,
        userId: 200,
        nom: 'Test Biblio',
        nbLignes: 6,
        nbColonnes: 7,
        token: 'test_token',
      );

      // Conversion JSON puis reconstruction
      final json = biblioOriginale.toJson();
      final biblioRecree = Bibliotheque.fromJson(json);

      // Vérification que les deux sont identiques
      expect(biblioRecree.biblioId, biblioOriginale.biblioId);
      expect(biblioRecree.userId, biblioOriginale.userId);
      expect(biblioRecree.nom, biblioOriginale.nom);
      expect(biblioRecree.nbLignes, biblioOriginale.nbLignes);
      expect(biblioRecree.nbColonnes, biblioOriginale.nbColonnes);
      expect(biblioRecree.token, biblioOriginale.token);
    });

    // Test 8 : Calcul du nombre total d'emplacements (test logique métier)
    test('Calcul du nombre total d\'emplacements de livres', () {
      final biblio = Bibliotheque(
        userId: 1,
        nom: 'Ma Biblio',
        nbLignes: 4,
        nbColonnes: 5,
      );

      // Le nombre total d'emplacements = lignes × colonnes
      final totalEmplacements = biblio.nbLignes * biblio.nbColonnes;

      expect(totalEmplacements, 20); // 4 × 5 = 20 emplacements
    });
  });
}
