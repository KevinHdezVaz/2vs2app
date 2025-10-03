import 'package:Frutia/providers/ShoppingProvider.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final ShoppingItem item;
  const ProductDetailScreen({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrutiaColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: FrutiaColors.accent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(item.name,
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              background: Image.asset(
                item.image,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Descripción ---
                  Text('Acerca del Producto',
                      style: GoogleFonts.lato(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(item.description,
                      style: GoogleFonts.lato(
                          fontSize: 16,
                          color: FrutiaColors.secondaryText,
                          height: 1.5)),

                  const Divider(height: 40),

                  // --- Info Nutricional ---
                  Text('Información Nutricional (por 100g)',
                      style: GoogleFonts.lato(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildNutritionalInfo(item.nutritionalInfo),

                  const Divider(height: 40),

                  // --- Comparativa de Precios ---
                  Text('Precios Aproximados',
                      style: GoogleFonts.lato(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (item.prices.isEmpty)
                    const Text('No hay precios disponibles para este producto.')
                  else
                    ...item.prices
                        .map((price) => _buildPriceRow(price))
                        .toList(),
                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<ShoppingProvider>().addItemToUserList(item);
          Navigator.pop(context); // Opcional: regresa a la pantalla anterior
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} añadido a tu lista')));
        },
        label: const Text('Añadir a mi lista'),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: FrutiaColors.accent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNutritionalInfo(Map<String, String> info) {
    if (info.isEmpty)
      return const Text('No hay información nutricional disponible.');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: info.entries
          .map((entry) =>
              _NutrientInfoTile(nutrient: entry.key, value: entry.value))
          .toList(),
    );
  }

  Widget _buildPriceRow(StorePrice priceInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.storefront, color: FrutiaColors.accent),
        title: Text(priceInfo.storeName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(priceInfo.price,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: priceInfo.note != null ? Text(priceInfo.note!) : null,
      ),
    );
  }
}

class _NutrientInfoTile extends StatelessWidget {
  final String nutrient;
  final String value;
  const _NutrientInfoTile({required this.nutrient, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: FrutiaColors.accent),
          const SizedBox(width: 8),
          Text('$nutrient: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
