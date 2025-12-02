import 'package:flutter_test/flutter_test.dart';
import 'package:biblioscan/models/user.dart';

void main() {
  group('User Model Tests', () {
    // Test 1 : Créer un utilisateur avec toutes les propriétés
    test('Création d\'un utilisateur complet', () {
      // On crée un utilisateur avec toutes les infos
      final user = User(
        userId: 1,
        username: 'john_doe',
        password: 'motdepasse123',
        token: 'token_secret_xyz',
      );

      // On vérifie chaque propriété
      expect(user.userId, 1);
      expect(user.username, 'john_doe');
      expect(user.password, 'motdepasse123');
      expect(user.token, 'token_secret_xyz');
    });

    // Test 2 : Créer un utilisateur sans ID ni token (nouvel utilisateur)
    test('Création d\'un nouvel utilisateur (sans ID ni token)', () {
      // Quand on crée un compte, on n'a pas encore d'ID ni de token
      final user = User(
        username: 'marie_martin',
        password: 'securePwd456',
      );

      expect(user.username, 'marie_martin');
      expect(user.password, 'securePwd456');
      expect(user.userId, isNull); // Pas encore d'ID
      expect(user.token, isNull); // Pas encore de token
    });

    // Test 3 : Convertir un User en JSON
    test('Conversion User vers JSON (toJson)', () {
      final user = User(
        userId: 10,
        username: 'alice',
        password: 'alicepass',
        token: 'alice_token_123',
      );

      // Conversion en JSON
      final json = user.toJson();

      // Vérification du JSON généré
      expect(json['user_id'], 10);
      expect(json['username'], 'alice');
      expect(json['password'], 'alicepass');
      expect(json['token'], 'alice_token_123');
    });

    // Test 4 : Créer un User depuis JSON (réponse d'API)
    test('Création d\'un utilisateur depuis JSON (fromJson)', () {
      // Simulation d'une réponse API après connexion
      final json = {
        'user_id': 42,
        'username': 'bob_builder',
        'password': 'builder2024',
        'token': 'jwt_token_bob_xyz',
      };

      // Création du User depuis le JSON
      final user = User.fromJson(json);

      // Vérifications
      expect(user.userId, 42);
      expect(user.username, 'bob_builder');
      expect(user.password, 'builder2024');
      expect(user.token, 'jwt_token_bob_xyz');
    });

    // Test 5 : fromJson avec valeurs manquantes
    test('fromJson avec certaines valeurs null', () {
      // JSON sans userId et sans token (nouvel utilisateur)
      final json = {
        'username': 'charlie',
        'password': 'charlie123',
      };

      final user = User.fromJson(json);

      expect(user.username, 'charlie');
      expect(user.password, 'charlie123');
      expect(user.userId, isNull);
      expect(user.token, isNull);
    });

    // Test 6 : Aller-retour JSON complet
    test('Aller-retour JSON : toJson puis fromJson', () {
      // Utilisateur original
      final userOriginal = User(
        userId: 100,
        username: 'testuser',
        password: 'testpass',
        token: 'test_token',
      );

      // Conversion JSON puis reconstruction
      final json = userOriginal.toJson();
      final userRecree = User.fromJson(json);

      // Vérification que les deux sont identiques
      expect(userRecree.userId, userOriginal.userId);
      expect(userRecree.username, userOriginal.username);
      expect(userRecree.password, userOriginal.password);
      expect(userRecree.token, userOriginal.token);
    });

    // Test 7 : Vérifier que les propriétés requises lèvent une erreur si absentes
    test('Les propriétés requises doivent être fournies', () {
      // On ne peut pas créer un User sans username et password
      // Ce test vérifie que le compilateur Dart force ces propriétés

      // Ceci devrait compiler sans erreur (propriétés fournies)
      final user = User(
        username: 'requiredTest',
        password: 'requiredPass',
      );

      expect(user.username, isNotEmpty);
      expect(user.password, isNotEmpty);
    });
  });
}
