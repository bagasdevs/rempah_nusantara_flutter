import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rempah_nusantara/screens/address_screen.dart';
import 'package:rempah_nusantara/screens/ai_tools_screen.dart';
import 'package:rempah_nusantara/screens/buyer_login_screen.dart';
import 'package:rempah_nusantara/screens/buyer_signup_screen.dart';
import 'package:rempah_nusantara/screens/cart_screen.dart';
import 'package:rempah_nusantara/screens/categories_screen.dart';
import 'package:rempah_nusantara/screens/checkout_screen.dart';
import 'package:rempah_nusantara/screens/complete_profile_screen.dart';

import 'package:rempah_nusantara/screens/edit_product_screen.dart';
import 'package:rempah_nusantara/screens/edit_profile_screen.dart';
import 'package:rempah_nusantara/screens/favorites_screen.dart';
import 'package:rempah_nusantara/screens/help_center_screen.dart';
import 'package:rempah_nusantara/screens/home_screen.dart';
import 'package:rempah_nusantara/screens/language_screen.dart';
import 'package:rempah_nusantara/screens/manage_products_screen.dart';
import 'package:rempah_nusantara/screens/notification_screen.dart';
import 'package:rempah_nusantara/screens/notification_settings_screen.dart';
import 'package:rempah_nusantara/screens/onboarding_screen.dart';
import 'package:rempah_nusantara/screens/order_success_screen.dart';
import 'package:rempah_nusantara/screens/order_status_screen.dart';
import 'package:rempah_nusantara/screens/orders_screen.dart';
import 'package:rempah_nusantara/screens/privacy_policy_screen.dart';
import 'package:rempah_nusantara/screens/product_detail_screen.dart';
import 'package:rempah_nusantara/screens/products_screen.dart';
import 'package:rempah_nusantara/screens/profile_screen.dart';

import 'package:rempah_nusantara/screens/search_screen.dart';
import 'package:rempah_nusantara/screens/seller_profile_screen.dart';
import 'package:rempah_nusantara/screens/seller_signup_screen.dart';
import 'package:rempah_nusantara/screens/settings_screen.dart';
import 'package:rempah_nusantara/screens/splash_screen.dart';

// Admin screens
import 'package:rempah_nusantara/screens/admin/admin_dashboard_screen.dart';
import 'package:rempah_nusantara/screens/admin/admin_users_screen.dart';
import 'package:rempah_nusantara/screens/admin/admin_products_screen.dart';
import 'package:rempah_nusantara/screens/admin/admin_orders_screen.dart';

// Custom page transition builder for slide animation
CustomTransitionPage<void> buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        );
      },
    ),

    GoRoute(
      path: '/',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const BuyerLoginScreen(),
        );
      },
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const BuyerSignupScreen(),
        );
      },
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const CategoriesScreen(),
        );
      },
    ),
    GoRoute(
      path: '/products',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final categoryId = state.uri.queryParameters['category'];
        final categoryName = state.uri.queryParameters['name'];
        final searchQuery = state.uri.queryParameters['search'];
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: ProductsScreen(
            categoryId: categoryId != null ? int.tryParse(categoryId) : null,
            categoryName: categoryName,
            searchQuery: searchQuery,
          ),
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final initialQuery = state.uri.queryParameters['q'];
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SearchScreen(initialQuery: initialQuery),
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const NotificationScreen(),
        );
      },
    ),
    GoRoute(
      path: '/complete-profile',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const CompleteProfileScreen(),
        );
      },
    ),
    GoRoute(
      path: '/product/:id',
      pageBuilder: (BuildContext context, GoRouterState state) {
        // Ekstrak 'id' dari path parameter dan ubah menjadi integer
        final productId = int.parse(state.pathParameters['id']!);
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: ProductDetailScreen(productId: productId),
        );
      },
    ),

    GoRoute(
      path: '/seller-profile/:id',
      pageBuilder: (BuildContext context, GoRouterState state) {
        // Ekstrak 'id' dari path parameter
        final sellerId = state.pathParameters['id']!;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SellerProfileScreen(sellerId: sellerId),
        );
      },
    ),
    GoRoute(
      path: '/cart',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const CartScreen(),
        );
      },
    ),
    GoRoute(
      path: '/checkout',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: CheckoutScreen(
            cartItems: extra['cartItems'],
            subtotal: extra['subtotal'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/order-success/:id',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final orderId = int.parse(state.pathParameters['id']!);
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: OrderSuccessScreen(orderId: orderId),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/seller-signup',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const SellerSignupScreen(),
        );
      },
    ),
    GoRoute(
      path: '/manage-products',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const ManageProductsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/edit-product',
      pageBuilder: (BuildContext context, GoRouterState state) {
        // Ambil productId dari extra. Jika tidak ada, berarti mode 'tambah'.
        final productId = state.extra as int?;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: EditProductScreen(productId: productId),
        );
      },
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const EditProfileScreen(),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const ProfileScreen(),
        );
      },
    ),
    GoRoute(
      path: '/help-center',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const HelpCenterScreen(),
        );
      },
    ),
    GoRoute(
      path: '/notification-settings',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const NotificationSettingsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const PrivacyPolicyScreen(),
        );
      },
    ),
    GoRoute(
      path: '/language',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const LanguageScreen(),
        );
      },
    ),
    GoRoute(
      path: '/orders',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const OrdersScreen(),
        );
      },
    ),
    GoRoute(
      path: '/order-status/:id',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final orderId = int.parse(state.pathParameters['id']!);
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: OrderStatusScreen(orderId: orderId),
        );
      },
    ),
    // Payment callback route for deep link from Midtrans
    GoRoute(
      path: '/payment/callback',
      redirect: (BuildContext context, GoRouterState state) {
        // Extract order_id from query parameters
        // Format: TRX-{orderId}-{timestamp}
        final transactionId = state.uri.queryParameters['order_id'];
        if (transactionId != null && transactionId.isNotEmpty) {
          // Parse order_id from transaction_id format: TRX-{orderId}-{timestamp}
          final parts = transactionId.split('-');
          if (parts.length >= 2) {
            final orderId =
                parts[1]; // Extract orderId from TRX-{orderId}-{timestamp}
            // Redirect to order status screen
            return '/order-status/$orderId';
          }
        }
        // If no valid order_id, redirect to orders page
        return '/orders';
      },
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const FavoritesScreen(),
        );
      },
    ),
    GoRoute(
      path: '/address',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AddressScreen(),
        );
      },
    ),
    GoRoute(
      path: '/ai-tools',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AiToolsScreen(),
        );
      },
    ),

    // ==================== ADMIN ROUTES ====================
    GoRoute(
      path: '/admin',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/admin/dashboard',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/admin/users',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminUsersScreen(),
        );
      },
    ),
    GoRoute(
      path: '/admin/products',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminProductsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/admin/orders',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminOrdersScreen(),
        );
      },
    ),
  ],
);
