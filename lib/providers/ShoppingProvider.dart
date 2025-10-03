import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Importa este paquete. Añádelo a pubspec.yaml si no lo tienes.

// --- MODELOS DE DATOS ---
class StorePrice {
  final String storeName;
  final String price;
  final String? note;
  StorePrice({required this.storeName, required this.price, this.note});
}

class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final String image;
  final String description;
  final Map<String, String> nutritionalInfo;
  final List<StorePrice> prices;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    this.description = 'Descripción detallada del producto no disponible.',
    this.nutritionalInfo = const {},
    this.prices = const [],
  });
}

class UserShoppingListItem {
  final ShoppingItem item;
  int quantity;
  bool isChecked;

  UserShoppingListItem({
    required this.item,
    this.quantity = 1,
    this.isChecked = false,
  });
}

// --- PROVIDER PARA MANEJAR EL ESTADO ---
class ShoppingProvider extends ChangeNotifier {
  // Lista maestra de todos los productos disponibles en la app
  final List<ShoppingItem> _masterProductList = [
    ShoppingItem(
      id: 'p001',
      name: 'Pechuga de Pollo',
      category: 'Carnes y Aves',
      image: 'assets/images/chicken_breast.png',
      description:
          'Pechuga de pollo fresca, ideal para una dieta alta en proteínas. Perfecta para la plancha, al horno o desmenuzada.',
      nutritionalInfo: {
        'Calorías': '165 kcal',
        'Proteínas': '31 g',
        'Grasas': '3.6 g',
        'Carbs': '0 g'
      },
      prices: [
        StorePrice(storeName: 'Wong', price: 'S/ 17.50 x kg'),
        StorePrice(storeName: 'Tottus', price: 'S/ 17.50 x kg'),
        StorePrice(storeName: 'Plaza Vea', price: 'S/ 16.50 x kg'),
      ],
    ),
    ShoppingItem(
      id: 'p002',
      name: 'Bistec de Res',
      category: 'Carnes y Aves',
      image: 'assets/images/beef_steak.png',
      nutritionalInfo: {
        'Calorías': '250 kcal',
        'Proteínas': '26 g',
        'Grasas': '15 g',
        'Carbs': '0 g'
      },
      prices: [
        StorePrice(storeName: 'Wong', price: 'S/ 40.90 x kg'),
        StorePrice(storeName: 'Tottus', price: 'S/ 39.90 x kg'),
      ],
    ),
    ShoppingItem(
      id: 'p003',
      name: 'Lata de Atún',
      category: 'Despensa',
      image: 'assets/images/tuna_can.png',
      nutritionalInfo: {
        'Calorías': '184 kcal',
        'Proteínas': '40 g',
        'Grasas': '1 g',
        'Carbs': '0 g'
      },
      prices: [
        StorePrice(storeName: 'Wong', price: 'S/ 4.99'),
        StorePrice(storeName: 'Plaza Vea', price: 'S/ 4.99'),
      ],
    ),
    ShoppingItem(
      id: 'p004',
      name: 'Huevos de Corral',
      category: 'Lácteos y Huevos',
      image: 'assets/images/eggs.png',
      nutritionalInfo: {
        'Calorías': '155 kcal',
        'Proteínas': '13 g',
        'Grasas': '11 g',
        'Carbs': '1.1 g'
      },
    ),
  ];

  // Lista de compras personal del usuario
  final List<UserShoppingListItem> _userShoppingList = [];

  // Getters para acceder a las listas desde la UI
  List<ShoppingItem> get masterProductList => _masterProductList;
  List<UserShoppingListItem> get userShoppingList => _userShoppingList;

  // --- MÉTODOS PARA MANIPULAR LA LISTA ---

  void addItemToUserList(ShoppingItem item) {
    // Evitar duplicados
    if (_userShoppingList.any((element) => element.item.id == item.id)) {
      incrementQuantity(item.id);
      return;
    }
    _userShoppingList.add(UserShoppingListItem(item: item));
    notifyListeners();
  }

  void removeItemFromUserList(String itemId) {
    _userShoppingList.removeWhere((element) => element.item.id == itemId);
    notifyListeners();
  }

  void incrementQuantity(String itemId) {
    final item = _userShoppingList
        .firstWhereOrNull((element) => element.item.id == itemId);
    if (item != null) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String itemId) {
    final item = _userShoppingList
        .firstWhereOrNull((element) => element.item.id == itemId);
    if (item != null && item.quantity > 1) {
      item.quantity--;
      notifyListeners();
    } else if (item != null && item.quantity == 1) {
      removeItemFromUserList(itemId);
    }
  }

  void toggleCheck(String itemId) {
    final item = _userShoppingList
        .firstWhereOrNull((element) => element.item.id == itemId);
    if (item != null) {
      item.isChecked = !item.isChecked;
      notifyListeners();
    }
  }
}
