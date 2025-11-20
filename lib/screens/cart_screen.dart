
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/bottom_nav_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Data dummy untuk keranjang
  final List<Map<String, dynamic>> cartData = [
    {
      "sellerName": "@Bambang256",
      "isSelected": false,
      "items": [
        {
          "image": "https://picsum.photos/100/100?random=18",
          "name": "Lada Hitam",
          "type": "Premium",
          "price": "Rp 85.000",
          "quantity": 2,
          "totalPrice": "Rp 170.000",
        },
        {
          "image": "https://picsum.photos/100/100?random=19",
          "name": "Jahe Merah",
          "type": "Organik",
          "price": "Rp 75.000",
          "quantity": 1,
          "totalPrice": "Rp 75.000",
        },
        {
          "image": "https://picsum.photos/100/100?random=20",
          "name": "Cabai Kering",
          "type": "Pedas",
          "price": "Rp 90.000",
          "quantity": 2,
          "totalPrice": "Rp 180.000",
        },
      ]
    },
    {
      "sellerName": "@Karti26",
      "isSelected": true,
      "items": [
        {
          "image": "https://picsum.photos/100/100?random=21",
          "name": "Kayu Manis",
          "type": "Batang",
          "price": "Rp 90.000",
          "quantity": 2,
          "totalPrice": "Rp 180.000",
        },
        {
          "image": "https://picsum.photos/100/100?random=22",
          "name": "Serai Wangi",
          "type": "Bali",
          "price": "Rp 75.000",
          "quantity": 2,
          "totalPrice": "Rp 150.000",
        },
        {
          "image": "https://picsum.photos/100/100?random=23",
          "name": "Bunga Lawang",
          "type": "wangi",
          "price": "Rp 90.000",
          "quantity": 2,
          "totalPrice": "Rp 180.000",
        },
      ]
    },
     {
      "sellerName": "@Eko_sus",
      "isSelected": false,
      "items": []
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 200), // Padding for checkout and nav bar
            itemCount: cartData.length,
            itemBuilder: (context, index) {
              final sellerData = cartData[index];
              return _buildSellerSection(
                context,
                sellerName: sellerData['sellerName'],
                isSelected: sellerData['isSelected'],
                items: (sellerData['items'] as List).map((item) {
                  return _buildCartItem(
                    image: item['image'],
                    name: item['name'],
                    type: item['type'],
                    price: item['price'],
                    quantity: item['quantity'],
                    totalPrice: item['totalPrice'],
                  );
                }).toList(),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCheckoutBar(),
                const BottomNavBar(currentRoute: '/cart'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFBF9F4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
        onPressed: () => context.go('/'), // FIX: Kembali ke home
      ),
      title: const Text(
        'Keranjang',
        style: TextStyle(
          color: Color(0xFF4A4A4A),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF4D5D42), size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF4D5D42), size: 28),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSellerSection(BuildContext context, {required String sellerName, bool isSelected = false, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A4A4A))),
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                // TODO: Implement toggle select all logic
              },
              activeColor: const Color(0xFF4D5D42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items,
        const SizedBox(height: 16), // Spacing between sellers
      ],
    );
  }

  Widget _buildCartItem({required String image, required String name, required String type, required String price, required int quantity, required String totalPrice}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(image, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A4A4A))),
                Text(type, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(price, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          _buildQuantityControl(quantity),
          const SizedBox(width: 16),
          SizedBox(
            width: 80, // Memberi lebar tetap untuk total harga
            child: Text(totalPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A4A4A)), textAlign: TextAlign.end,)
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4D5D42),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 16), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(quantity.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 16), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        )
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total :', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text('Rp 510.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF4A4A4A)), overflow: TextOverflow.ellipsis,),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D5D42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              child: const Text('Check Out'),
            ),
          ],
        ),
      ),
    );
  }
}
