import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/buyer_login_screen.dart';
import 'package:myapp/screens/buyer_signup_screen.dart';
import 'package:myapp/screens/cart_screen.dart';
import 'package:myapp/screens/farmer_profile_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/product_detail_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/edit_product_screen.dart';
import 'package:myapp/screens/manage_products_screen.dart';
import 'package:myapp/screens/seller_signup_screen.dart';
import 'package:myapp/screens/splash_screen.dart';
import 'package:myapp/screens/shop_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const BuyerLoginScreen();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const BuyerSignupScreen();
      },
    ),
    GoRoute(
      path: '/product',
      builder: (BuildContext context, GoRouterState state) {
        return const ProductDetailScreen();
      },
    ),
    GoRoute(
      path: '/farmer-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const FarmerProfileScreen();
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (BuildContext context, GoRouterState state) {
        return const CartScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
    GoRoute(
      path: '/shop',
      builder: (BuildContext context, GoRouterState state) {
        return const ShopScreen();
      },
    ),
    GoRoute(
      path: '/seller-signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SellerSignupScreen();
      },
    ),
    GoRoute(
      path: '/manage-products',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageProductsScreen();
      },
    ),
    GoRoute(
      path: '/edit-product',
      builder: (BuildContext context, GoRouterState state) {
        // Ambil productId dari extra. Jika tidak ada, berarti mode 'tambah'.
        final productId = state.extra as int?;
        return EditProductScreen(productId: productId);
      },
    ),
  ],
);
