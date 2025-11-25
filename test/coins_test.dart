import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/user_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Coins Functionality Tests', () {
    late UserData userData;

    setUp(() {
      // Create minimal test user data without loading from Firestore or schema
      // This bypasses asset loading issues in test environment
      final testData = {
        'sproutProgress': {
          'coins': 0,
          'inventory': {},
        },
      };
      
      userData = UserData(
        uid: 'test_user_123',
        data: testData,
      );
    });

    // Helper to read quantity from inventory supporting both legacy int
    // entries and structured { 'quantity': int, 'isLocked': bool } entries.
    int qty(Map inventory, String itemId) {
      final v = inventory[itemId];
      if (v is int) return v;
      if (v is Map) return v['quantity'] as int? ?? 0;
      return 0;
    }

    group('Basic Coins Operations', () {
      test('getCoins should return 0 by default', () {
        expect(userData.getCoins(), equals(0));
      });

      test('getCoins should return correct amount after manual set', () {
        userData.set('sproutProgress.coins', 100);
        expect(userData.getCoins(), equals(100));
      });

      test('getCoins should handle missing coins field gracefully', () {
        // Create userData without coins field
        final testData = {
          'sproutProgress': {},
        };
        final testUserData = UserData(uid: 'test_user', data: testData);
        expect(testUserData.getCoins(), equals(0));
      });

      test('getCoins should handle non-integer values', () {
        userData.set('sproutProgress.coins', 'invalid');
        expect(userData.getCoins(), equals(0));
      });
    });

    group('Add Coins Tests', () {
      test('addCoins should increase coins amount', () async {
        await userData.addCoins(50);
        expect(userData.getCoins(), equals(50));
      });

      test('addCoins should accumulate correctly', () async {
        await userData.addCoins(25);
        await userData.addCoins(75);
        expect(userData.getCoins(), equals(100));
      });

      test('addCoins should handle large amounts', () async {
        await userData.addCoins(1000000);
        expect(userData.getCoins(), equals(1000000));
      });

      test('addCoins should throw error for negative amount', () async {
        expect(
          () async => await userData.addCoins(-10),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('addCoins should allow zero amount as no-op', () async {
        userData.set('sproutProgress.coins', 50);
        await userData.addCoins(0);
        expect(userData.getCoins(), equals(50)); // Unchanged
      });
    });

    group('Subtract Coins Tests', () {
      test('subtractCoins should decrease coins amount', () async {
        userData.set('sproutProgress.coins', 100);
        final result = await userData.subtractCoins(30);
        
        expect(result, isTrue);
        expect(userData.getCoins(), equals(70));
      });

      test('subtractCoins should return false for insufficient coins', () async {
        userData.set('sproutProgress.coins', 50);
        final result = await userData.subtractCoins(100);
        
        expect(result, isFalse);
        expect(userData.getCoins(), equals(50)); // Unchanged
      });

      test('subtractCoins should allow exact balance subtraction', () async {
        userData.set('sproutProgress.coins', 100);
        final result = await userData.subtractCoins(100);
        
        expect(result, isTrue);
        expect(userData.getCoins(), equals(0));
      });

      test('subtractCoins should prevent negative balance', () async {
        userData.set('sproutProgress.coins', 10);
        final result = await userData.subtractCoins(20);
        
        expect(result, isFalse);
        expect(userData.getCoins(), equals(10));
      });

      test('subtractCoins should throw error for negative amount', () async {
        userData.set('sproutProgress.coins', 100);
        expect(
          () async => await userData.subtractCoins(-10),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('subtractCoins should allow zero amount as no-op', () async {
        userData.set('sproutProgress.coins', 100);
        final result = await userData.subtractCoins(0);
        
        expect(result, isTrue);
        expect(userData.getCoins(), equals(100)); // Unchanged
      });
    });

    group('Can Afford Tests', () {
      test('canAfford should return true when user has exact amount', () {
        userData.set('sproutProgress.coins', 100);
        expect(userData.canAfford(100), isTrue);
      });

      test('canAfford should return true when user has more than needed', () {
        userData.set('sproutProgress.coins', 150);
        expect(userData.canAfford(100), isTrue);
      });

      test('canAfford should return false when user has less than needed', () {
        userData.set('sproutProgress.coins', 50);
        expect(userData.canAfford(100), isFalse);
      });

      test('canAfford should return true for zero cost', () {
        userData.set('sproutProgress.coins', 0);
        expect(userData.canAfford(0), isTrue);
      });

      test('canAfford should throw error for negative cost', () {
        expect(
          () => userData.canAfford(-10),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Purchase With Coins Tests', () {
      test('purchaseWithCoins should deduct coins and add items', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 10,
        });

        final result = await userData.purchaseWithCoins(
          cost: 50,
          items: {'wheat_seeds': 20},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(30));
      });

      test('purchaseWithCoins should handle multiple items', () async {
        userData.set('sproutProgress.coins', 200);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 5,
          'carrot_seeds': 10,
        });

        final result = await userData.purchaseWithCoins(
          cost: 100,
          items: {
            'wheat_seeds': 15,
            'carrot_seeds': 25,
          },
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(100));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(20));
        expect(qty(inventory, 'carrot_seeds'), equals(35));
      });

      test('purchaseWithCoins should fail for insufficient coins', () async {
        userData.set('sproutProgress.coins', 30);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 10,
        });

        final result = await userData.purchaseWithCoins(
          cost: 50,
          items: {'wheat_seeds': 20},
        );

        expect(result, isFalse);
        expect(userData.getCoins(), equals(30)); // Unchanged
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(10)); // Unchanged
      });

      test('purchaseWithCoins should handle new items in inventory', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 5,
        });

        final result = await userData.purchaseWithCoins(
          cost: 50,
          items: {'potato_seeds': 10},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'potato_seeds'), equals(10));
      });

      test('purchaseWithCoins should throw error for negative cost', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {});

        expect(
          () async => await userData.purchaseWithCoins(
            cost: -10,
            items: {'wheat_seeds': 5},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('purchaseWithCoins should handle zero cost purchases', () async {
        userData.set('sproutProgress.coins', 50);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 10,
        });

        final result = await userData.purchaseWithCoins(
          cost: 0,
          items: {'wheat_seeds': 5},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50)); // Unchanged
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(15));
      });
    });

    group('Edge Cases and Integration Tests', () {
      test('should handle rapid consecutive purchases', () async {
        userData.set('sproutProgress.coins', 1000);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 0,
        });

        for (int i = 0; i < 10; i++) {
          final result = await userData.purchaseWithCoins(
            cost: 50,
            items: {'wheat_seeds': 10},
          );
          expect(result, isTrue);
        }

        expect(userData.getCoins(), equals(500));
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(100));
      });

      test('should handle mixed operations (add, subtract, purchase)', () async {
        userData.set('sproutProgress.coins', 0);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        await userData.addCoins(100);
        expect(userData.getCoins(), equals(100));

        final subtractResult = await userData.subtractCoins(30);
        expect(subtractResult, isTrue);
        expect(userData.getCoins(), equals(70));

        final purchaseResult = await userData.purchaseWithCoins(
          cost: 50,
          items: {'wheat_seeds': 20},
        );
        expect(purchaseResult, isTrue);
        expect(userData.getCoins(), equals(20));

        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(20));
      });

      test('should handle purchase with exact balance', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        final result = await userData.purchaseWithCoins(
          cost: 100,
          items: {'wheat_seeds': 50},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(0));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(50));
      });

      test('should maintain integer-only values', () async {
        userData.set('sproutProgress.coins', 100);
        
        await userData.addCoins(50);
        expect(userData.getCoins(), isA<int>());
        
        await userData.subtractCoins(25);
        expect(userData.getCoins(), isA<int>());
        expect(userData.getCoins(), equals(125));
      });

      test('should handle large purchase quantities', () async {
        userData.set('sproutProgress.coins', 10000);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 0,
        });

        final result = await userData.purchaseWithCoins(
          cost: 5000,
          items: {'wheat_seeds': 1000},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(5000));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(1000));
      });
    });

    group('Purchase Multiplier Scenarios', () {
      test('should handle 1x multiplier purchase', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        final result = await userData.purchaseWithCoins(
          cost: 5 * 1, // 5 coins per purchase, 1x multiplier
          items: {'wheat_seeds': 1},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(95));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(1));
      });

      test('should handle 10x multiplier purchase', () async {
        userData.set('sproutProgress.coins', 100);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        final result = await userData.purchaseWithCoins(
          cost: 5 * 10, // 5 coins per purchase, 10x multiplier
          items: {'wheat_seeds': 10},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(10));
      });

      test('should handle 100x multiplier purchase', () async {
        userData.set('sproutProgress.coins', 1000);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        final result = await userData.purchaseWithCoins(
          cost: 5 * 100, // 5 coins per purchase, 100x multiplier
          items: {'wheat_seeds': 100},
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(500));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(100));
      });

      test('should fail 100x purchase with insufficient coins', () async {
        userData.set('sproutProgress.coins', 300);
        userData.set('sproutProgress.inventory', {'wheat_seeds': 0});

        final result = await userData.purchaseWithCoins(
          cost: 5 * 100,
          items: {'wheat_seeds': 100},
        );

        expect(result, isFalse);
        expect(userData.getCoins(), equals(300)); // Unchanged
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(0)); // Unchanged
      });
    });

    group('Inventory Integration Tests', () {
      test('should correctly update existing inventory items', () async {
        userData.set('sproutProgress.coins', 200);
        userData.set('sproutProgress.inventory', {
          'wheat_seeds': 50,
          'carrot_seeds': 30,
          'potato_seeds': 20,
        });

        final result = await userData.purchaseWithCoins(
          cost: 100,
          items: {
            'wheat_seeds': 25,
            'carrot_seeds': 15,
          },
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(100));
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(75));
        expect(qty(inventory, 'carrot_seeds'), equals(45));
        expect(qty(inventory, 'potato_seeds'), equals(20)); // Unchanged
      });

      test('should handle missing inventory gracefully', () async {
        // Create userData without inventory field
        final testData = {
          'sproutProgress': {
            'coins': 100,
          },
        };
        final testUserData = UserData(uid: 'test_user', data: testData);

        final result = await testUserData.purchaseWithCoins(
          cost: 50,
          items: {'wheat_seeds': 10},
        );

        // Should succeed and initialize inventory
        expect(result, isTrue);
        expect(testUserData.getCoins(), equals(50));
        
        final inventory = testUserData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat_seeds'), equals(10));
      });
    });

    group('Selling Items Tests', () {
      test('sellItem should add coins and remove item from inventory', () async {
        // Set up inventory with items
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 0);

        final result = await userData.sellItem(
          itemId: 'wheat',
          quantity: 5,
          sellAmountPerItem: 5,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(25)); // 5 * 5 = 25
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat'), equals(5)); // 10 - 5 = 5
      });

      test('sellItem should work with 1x multiplier', () async {
        userData.set('sproutProgress.inventory', {
          'carrot': {'quantity': 20, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 10);

        final result = await userData.sellItem(
          itemId: 'carrot',
          quantity: 1,
          sellAmountPerItem: 8,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(18)); // 10 + (1 * 8)
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'carrot'), equals(19));
      });

      test('sellItem should work with 10x multiplier', () async {
        userData.set('sproutProgress.inventory', {
          'potato': {'quantity': 50, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 20);

        final result = await userData.sellItem(
          itemId: 'potato',
          quantity: 10,
          sellAmountPerItem: 12,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(140)); // 20 + (10 * 12)
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'potato'), equals(40));
      });

      test('sellItem should work with 100x multiplier', () async {
        userData.set('sproutProgress.inventory', {
          'beetroot': {'quantity': 200, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 0);

        final result = await userData.sellItem(
          itemId: 'beetroot',
          quantity: 100,
          sellAmountPerItem: 15,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(1500)); // 100 * 15
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'beetroot'), equals(100));
      });

      test('sellItem should work with sell all', () async {
        userData.set('sproutProgress.inventory', {
          'radish': {'quantity': 37, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 50);

        final result = await userData.sellItem(
          itemId: 'radish',
          quantity: 37, // Sell all
          sellAmountPerItem: 20,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(790)); // 50 + (37 * 20)
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'radish'), equals(0));
      });

      test('sellItem should return false for insufficient quantity', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 5, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 100);

        final result = await userData.sellItem(
          itemId: 'wheat',
          quantity: 10, // More than available
          sellAmountPerItem: 5,
        );

        expect(result, isFalse);
        expect(userData.getCoins(), equals(100)); // Unchanged
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat'), equals(5)); // Unchanged
      });

      test('sellItem should return false for non-existent item', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 50);

        final result = await userData.sellItem(
          itemId: 'nonexistent_item',
          quantity: 1,
          sellAmountPerItem: 10,
        );

        expect(result, isFalse);
        expect(userData.getCoins(), equals(50)); // Unchanged
      });

      test('sellItem should return false when inventory is null', () async {
        userData.set('sproutProgress.coins', 100);
        // No inventory set

        final result = await userData.sellItem(
          itemId: 'wheat',
          quantity: 1,
          sellAmountPerItem: 5,
        );

        expect(result, isFalse);
        expect(userData.getCoins(), equals(100)); // Unchanged
      });

      test('sellItem should throw error for negative quantity', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });

        expect(
          () async => await userData.sellItem(
            itemId: 'wheat',
            quantity: -5,
            sellAmountPerItem: 5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sellItem should throw error for zero quantity', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });

        expect(
          () async => await userData.sellItem(
            itemId: 'wheat',
            quantity: 0,
            sellAmountPerItem: 5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sellItem should throw error for negative sell amount', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });

        expect(
          () async => await userData.sellItem(
            itemId: 'wheat',
            quantity: 5,
            sellAmountPerItem: -5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('sellItem should allow zero sell amount', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 10, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 50);

        final result = await userData.sellItem(
          itemId: 'wheat',
          quantity: 5,
          sellAmountPerItem: 0, // Free item
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50)); // No coins added
        
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat'), equals(5)); // Items removed
      });

      test('sellItem should work with legacy int inventory format', () async {
        // Set up inventory with legacy int format
        userData.set('sproutProgress.inventory', {
          'wheat': 20, // Legacy format
        });
        userData.set('sproutProgress.coins', 0);

        final result = await userData.sellItem(
          itemId: 'wheat',
          quantity: 10,
          sellAmountPerItem: 5,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(50));
        
        // Should convert to structured format
        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat'), equals(10));
        
        // Verify it's in structured format now
        final wheatData = inventory['wheat'];
        expect(wheatData, isA<Map>());
        expect((wheatData as Map)['quantity'], equals(10));
        expect(wheatData['isLocked'], equals(false));
      });

      test('sellItem should handle multiple sells in sequence', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 100, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 0);

        // Sell 1x
        await userData.sellItem(
          itemId: 'wheat',
          quantity: 1,
          sellAmountPerItem: 5,
        );
        expect(userData.getCoins(), equals(5));
        expect(qty(userData.get('sproutProgress.inventory') as Map, 'wheat'), equals(99));

        // Sell 10x
        await userData.sellItem(
          itemId: 'wheat',
          quantity: 10,
          sellAmountPerItem: 5,
        );
        expect(userData.getCoins(), equals(55));
        expect(qty(userData.get('sproutProgress.inventory') as Map, 'wheat'), equals(89));

        // Sell 50x
        await userData.sellItem(
          itemId: 'wheat',
          quantity: 50,
          sellAmountPerItem: 5,
        );
        expect(userData.getCoins(), equals(305));
        expect(qty(userData.get('sproutProgress.inventory') as Map, 'wheat'), equals(39));

        // Sell all remaining
        await userData.sellItem(
          itemId: 'wheat',
          quantity: 39,
          sellAmountPerItem: 5,
        );
        expect(userData.getCoins(), equals(500));
        expect(qty(userData.get('sproutProgress.inventory') as Map, 'wheat'), equals(0));
      });

      test('sellItem should handle selling different item types', () async {
        userData.set('sproutProgress.inventory', {
          'wheat': {'quantity': 20, 'isLocked': false},
          'carrot': {'quantity': 15, 'isLocked': false},
          'potato': {'quantity': 10, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 0);

        // Sell wheat
        await userData.sellItem(
          itemId: 'wheat',
          quantity: 10,
          sellAmountPerItem: 5,
        );
        expect(userData.getCoins(), equals(50));

        // Sell carrot
        await userData.sellItem(
          itemId: 'carrot',
          quantity: 5,
          sellAmountPerItem: 8,
        );
        expect(userData.getCoins(), equals(90));

        // Sell potato
        await userData.sellItem(
          itemId: 'potato',
          quantity: 10,
          sellAmountPerItem: 12,
        );
        expect(userData.getCoins(), equals(210));

        final inventory = userData.get('sproutProgress.inventory') as Map;
        expect(qty(inventory, 'wheat'), equals(10));
        expect(qty(inventory, 'carrot'), equals(10));
        expect(qty(inventory, 'potato'), equals(0));
      });

      test('sellItem should handle large coin amounts', () async {
        userData.set('sproutProgress.inventory', {
          'radish': {'quantity': 10000, 'isLocked': false},
        });
        userData.set('sproutProgress.coins', 500);

        final result = await userData.sellItem(
          itemId: 'radish',
          quantity: 10000,
          sellAmountPerItem: 20,
        );

        expect(result, isTrue);
        expect(userData.getCoins(), equals(200500)); // 500 + (10000 * 20)
      });
    });
  });
}
