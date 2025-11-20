
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildCategoryChips(),
                  _buildSectionTitle('Rempah Yang Sedang Trend'),
                  _buildTrendingCard(context),
                  _buildFavoritesSection(context),
                  _buildSectionTitle('Top Petani'),
                  _buildTopFarmers(context),
                  _buildRecommendedSection(context),
                  const SizedBox(height: 100), // Padding for floating nav bar
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavBar(currentRoute: '/'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi! Sepia',
                    style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),),
                Text('kamu Sedang Mencari Rempah Apa?',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 30, color: Color(0xFF4D5D42)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 30, color: Color(0xFF4D5D42)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['Aromatik', 'Rimpang', 'Daun', 'Biji & Buah', 'B'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = index == 0;
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == categories.length - 1 ? 16.0 : 0),
            child: Chip(
              label: Text(categories[index]),
              backgroundColor: isSelected ? const Color(0xFF4D5D42) : const Color(0xFFFBF9F4),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFF4D5D42) : Colors.grey.shade300)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
    );
  }

  Widget _buildTrendingCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.network(
                'https://picsum.photos/600/250?random=1',
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bunga Lawang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                          Text('Dengan kualitas yang tinggi dan harga yang bersaing', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Rp 25.000/kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF4D5D42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Rempah Favorit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 16),
                _buildFavoriteItem(context, 'https://picsum.photos/160/220?random=2', 'Cabe Kering', 'Rp 15.000'),
                const SizedBox(width: 16),
                _buildFavoriteItem(context, 'https://picsum.photos/160/220?random=3', 'Kayu Manis', 'Rp 45.000/kg'),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, String imageUrl, String name, String price) {
    return GestureDetector(
      onTap: () => context.push('/product'),
      child: SizedBox(
        width: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover, height: 220, width: 160),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15)
                ),
                margin: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                    Text(price, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFarmers(BuildContext context) {
    final farmers = {
      'Karti': '4',
      'Eko': '5',
      'Bambang': '6',
      'Slamet': '7',
    };
    return SizedBox(
      height: 120,
      child: ListView.builder(
         scrollDirection: Axis.horizontal,
         itemCount: farmers.length,
        itemBuilder: (context, index) {
          final name = farmers.keys.elementAt(index);
          final imageId = farmers.values.elementAt(index);
          return GestureDetector(
            onTap: () => context.push('/farmer-profile'),
            child: Container(
               width: 100,
               margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == farmers.length - 1 ? 16.0 : 0),
               color: Colors.transparent,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network('https://picsum.photos/80/80?random=$imageId', width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(color: Color(0xFF4A4A4A))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Produk Rekomendasi'),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 16),
              _buildRecommendedItem(context, 'https://picsum.photos/150/150?random=8', 'Jahe Merah', 'Rp 30.000/kg'),
              const SizedBox(width: 16),
              _buildRecommendedItem(context, 'https://picsum.photos/150/150?random=9', 'Kunyit Bubuk', 'Rp 20.000/pack'),
              const SizedBox(width: 16),
              _buildRecommendedItem(context, 'https://picsum.photos/150/150?random=10', 'Lada Putih', 'Rp 50.000/kg'),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedItem(BuildContext context, String imageUrl, String name, String price) {
    return GestureDetector(
      onTap: () => context.push('/product'),
      child: SizedBox(
        width: 150,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover, height: 150, width: 150),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
      ),
    );
  }
}
