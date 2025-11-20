
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Column(
            children: [
              _buildCategoryChips(),
              Expanded(
                child: _buildProductGrid(context),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavBar(currentRoute: '/shop'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFBF9F4),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Rekomendasi Produk',
        style: TextStyle(
          color: Color(0xFF4D5D42),
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
        onPressed: () => context.go('/'), // Kembali ke home
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF4D5D42), size: 28),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['Semua', 'Aromatik', 'Rimpang', 'Daun', 'Biji & Buah'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            bool isSelected = index == 0;
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == categories.length - 1 ? 16.0 : 0),
              child: ChoiceChip(
                label: Text(categories[index]),
                selected: isSelected,
                onSelected: (selected) {},
                backgroundColor: const Color(0xFFFBF9F4),
                selectedColor: const Color(0xFF4D5D42),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFF4D5D42) : Colors.grey.shade300)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final products = {
      'Jahe Merah': 'Rp 30.000/kg',
      'Kunyit Bubuk': 'Rp 20.000/pack',
      'Lada Putih': 'Rp 50.000/kg',
      'Cengkeh': 'Rp 40.000/kg',
      'Kapulaga': 'Rp 60.000/kg',
      'Pala Bubuk': 'Rp 35.000/pack',
      'Bunga Lawang': 'Rp 25.000/kg',
      'Kayu Manis': 'Rp 45.000/kg',
    };

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for nav bar
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Adjust this for desired card height
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final name = products.keys.elementAt(index);
        final price = products.values.elementAt(index);
        final imageId = index + 20; // To get different random images
        return _buildRecommendedItem(context, 'https://picsum.photos/150/200?random=$imageId', name, price);
      },
    );
  }

  Widget _buildRecommendedItem(BuildContext context, String imageUrl, String name, String price) {
    return GestureDetector(
      onTap: () => context.push('/product'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A4A4A))),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
