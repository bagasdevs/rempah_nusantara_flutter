import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myapp/screens/address_screen.dart';
import 'package:myapp/screens/buyer_login_screen.dart';
import 'package:myapp/screens/buyer_signup_screen.dart';
import 'package:myapp/screens/cart_screen.dart';
import 'package:myapp/screens/categories_screen.dart';
import 'package:myapp/screens/checkout_screen.dart';
import 'package:myapp/screens/complete_profile_screen.dart';

import 'package:myapp/screens/edit_product_screen.dart';
import 'package:myapp/screens/edit_profile_screen.dart';
import 'package:myapp/screens/favorites_screen.dart';
import 'package:myapp/screens/help_center_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/language_screen.dart';
import 'package:myapp/screens/manage_products_screen.dart';
import 'package:myapp/screens/notification_screen.dart';
import 'package:myapp/screens/notification_settings_screen.dart';
import 'package:myapp/screens/onboarding_screen.dart';
import 'package:myapp/screens/order_success_screen.dart';
import 'package:myapp/screens/orders_screen.dart';
import 'package:myapp/screens/privacy_policy_screen.dart';
import 'package:myapp/screens/product_detail_screen.dart';
import 'package:myapp/screens/products_screen.dart';
import 'package:myapp/screens/profile_screen.dart';

import 'package:myapp/screens/search_screen.dart';
import 'package:myapp/screens/seller_profile_screen.dart';
import 'package:myapp/screens/seller_signup_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/splash_screen.dart';

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
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
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
      path: '/categories',
      builder: (BuildContext context, GoRouterState state) {
        return const CategoriesScreen();
      },
    ),
    GoRoute(
      path: '/products',
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = state.uri.queryParameters['category'];
        final categoryName = state.uri.queryParameters['name'];
        final searchQuery = state.uri.queryParameters['search'];
        return ProductsScreen(
          categoryId: categoryId != null ? int.tryParse(categoryId) : null,
          categoryName: categoryName,
          searchQuery: searchQuery,
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        final initialQuery = state.uri.queryParameters['q'];
        return SearchScreen(initialQuery: initialQuery);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationScreen();
      },
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const CompleteProfileScreen();
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (BuildContext context, GoRouterState state) {
        // Ekstrak 'id' dari path parameter dan ubah menjadi integer
        final productId = int.parse(state.pathParameters['id']!);
        return ProductDetailScreen(productId: productId);
      },
    ),

    GoRoute(
      path: '/seller-profile/:id',
      builder: (BuildContext context, GoRouterState state) {
        // Ekstrak 'id' dari path parameter
        final sellerId = state.pathParameters['id']!;
        return SellerProfileScreen(sellerId: sellerId);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (BuildContext context, GoRouterState state) {
        return const CartScreen();
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        return CheckoutScreen(
          cartItems: extra['cartItems'],
          subtotal: extra['subtotal'],
        );
      },
    ),
    GoRoute(
      path: '/order-success/:id',
      builder: (BuildContext context, GoRouterState state) {
        final orderId = int.parse(state.pathParameters['id']!);
        return OrderSuccessScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
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
    GoRoute(
      path: '/edit-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const EditProfileScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    GoRoute(
      path: '/help-center',
      builder: (BuildContext context, GoRouterState state) {
        return const HelpCenterScreen();
      },
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationSettingsScreen();
      },
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (BuildContext context, GoRouterState state) {
        return const PrivacyPolicyScreen();
      },
    ),
    GoRoute(
      path: '/language',
      builder: (BuildContext context, GoRouterState state) {
        return const LanguageScreen();
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (BuildContext context, GoRouterState state) {
        return const OrdersScreen();
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (BuildContext context, GoRouterState state) {
        return const FavoritesScreen();
      },
    ),
    GoRoute(
      path: '/address',
      builder: (BuildContext context, GoRouterState state) {
        return const AddressScreen();
      },
    ),
  ],
);
