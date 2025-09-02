import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'cart_page.dart';

class CartIconWithBadge extends StatelessWidget {
  const CartIconWithBadge({
    super.key,
    this.iconSize = 24,
    this.showBadge = true,
  });

  final double iconSize;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, size: iconSize),
              onPressed: () {
                Navigator.pushNamed(context, CartPage.routeName);
              },
            ),
            if (showBadge && cartProvider.totalItems > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartProvider.totalItems > 99 ? '99+' : '${cartProvider.totalItems}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
