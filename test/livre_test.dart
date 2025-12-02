import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/livre.dart';

void main() {
  // On regroupe les tests par fonctionnalité avec "group"
  group('Livre Model Tests', () {
    // Test 1 : Créer un livre avec toutes les propriétés
    test('Création d\'un livre complet', () {
      // Arrange (Préparer) : on crée un livre avec toutes les infos
      final livre = Livre(
        livreId: 1,
        biblioId: 10,
        titre: 'Le Petit Prince',
        auteur: 'Antoine de Saint-Exupéry',
        datePub: '1943',
        positionLigne: 2,
        positionColonne: 3,
        couvertureUrl: 'https://example.com/cover.jpg',
        token: 'abc123',
      );

      // Assert (Vérifier) : on vérifie que toutes les propriétés sont correctes
      expect(livre.livreId, 1);
      expect(livre.biblioId, 10);
      expect(livre.titre, 'Le Petit Prince');
      expect(livre.auteur, 'Antoine de Saint-Exupéry');
      expect(livre.datePub, '1943');
      expect(livre.positionLigne, 2);
      expect(livre.positionColonne, 3);
      expect(livre.couvertureUrl, 'https://example.com/cover.jpg');
      expect(livre.token, 'abc123');
    });

    // Test 2 : Créer un livre avec seulement le titre (propriétés minimales)
    test('Création d\'un livre avec seulement le titre', () {
      // Seul le titre est obligatoire
      final livre = Livre(titre: 'Livre Sans Info');

      // On vérifie que le titre existe et que les autres champs sont null
      expect(livre.titre, 'Livre Sans Info');
      expect(livre.livreId, isNull);
      expect(livre.biblioId, isNull);
      expect(livre.auteur, isNull);
      expect(livre.positionLigne, isNull);
    });

    // Test 3 : Convertir un objet Livre en JSON
    test('Conversion Livre vers JSON (toJson)', () {
      // On crée un livre
      final livre = Livre(
        livreId: 5,
        biblioId: 20,
        titre: '1984',
        auteur: 'George Orwell',
        datePub: '1949',
      );

      // On le convertit en JSON
      final json = livre.toJson();

      // On vérifie que le JSON contient les bonnes valeurs
      expect(json['livre_id'], 5);
      expect(json['biblio_id'], 20);
      expect(json['titre'], '1984');
      expect(json['auteur'], 'George Orwell');
      expect(json['date_pub'], '1949');
    });

    // Test 4 : Créer un Livre depuis du JSON (comme quand on reçoit des données d'une API)
    test('Création d\'un livre depuis JSON (fromJson)', () {
      // On simule un JSON reçu d'une API
      final json = {
        'livre_id': 7,
        'biblio_id': 15,
        'titre': 'Harry Potter',
        'auteur': 'J.K. Rowling',
        'date_pub': '1997',
        'position_ligne': 1,
        'position_colonne': 5,
        'couverture_url': 'https://example.com/hp.jpg',
        'token': 'xyz789',
      };

      // On crée un livre à partir de ce JSON
      final livre = Livre.fromJson(json);

      // On vérifie que toutes les propriétés ont été correctement extraites
      expect(livre.livreId, 7);
      expect(livre.biblioId, 15);
      expect(livre.titre, 'Harry Potter');
      expect(livre.auteur, 'J.K. Rowling');
      expect(livre.datePub, '1997');
      expect(livre.positionLigne, 1);
      expect(livre.positionColonne, 5);
    });

    // Test 5 : Gérer un JSON incomplet (sans titre)
    test('fromJson avec titre manquant utilise "Sans titre" par défaut', () {
      // JSON sans titre
      final json = {
        'livre_id': 8,
        'auteur': 'Auteur Inconnu',
      };

      final livre = Livre.fromJson(json);

      // Le titre doit être "Sans titre" (valeur par défaut)
      expect(livre.titre, 'Sans titre');
      expect(livre.auteur, 'Auteur Inconnu');
    });

    // Test 6 : Aller-retour JSON (toJson puis fromJson)
    test('Aller-retour JSON : toJson puis fromJson', () {
      // On crée un livre original
      final livreOriginal = Livre(
        livreId: 99,
        titre: 'Test Book',
        auteur: 'Test Author',
        biblioId: 50,
      );

      // On le convertit en JSON puis on recrée un livre depuis ce JSON
      final json = livreOriginal.toJson();
      final livreRecree = Livre.fromJson(json);

      // Les deux livres doivent avoir les mêmes valeurs
      expect(livreRecree.livreId, livreOriginal.livreId);
      expect(livreRecree.titre, livreOriginal.titre);
      expect(livreRecree.auteur, livreOriginal.auteur);
      expect(livreRecree.biblioId, livreOriginal.biblioId);
    });
  });
}
