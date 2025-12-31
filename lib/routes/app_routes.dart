import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/features/auth/provider/auth_provider.dart';
import 'package:flutter_assesment_1/routes/app_named.dart';
import 'package:flutter_assesment_1/features/home/pages/home_page.dart';
import 'package:flutter_assesment_1/features/home/pages/add_product_page.dart';
import 'package:flutter_assesment_1/features/auth/pages/signup_page.dart';
import 'package:flutter_assesment_1/features/auth/pages/login_page.dart';
import 'package:flutter_assesment_1/features/auth/pages/profile_page.dart';
import 'package:flutter_assesment_1/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_assesment_1/features/home/pages/category_list_page.dart';
import 'package:flutter_assesment_1/features/home/pages/create_category_page.dart';
import 'package:flutter_assesment_1/features/home/pages/category_products_page.dart';
import 'package:flutter_assesment_1/features/home/pages/product_details_page.dart';
import 'package:flutter_assesment_1/features/home/models/product_model.dart'; // For Category type

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final authNotifier = ValueNotifier(ref.read(authProvider));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: authNotifier,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn =
          state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.signUp;

      if (isLoggedIn && isLoggingIn) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Auth Route (Separate from Shell)
      GoRoute(
        path: AppRoutes.signUp,
        name: AppRoutes.signUpName,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),

      // Shell Route for Bottom Nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Products
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'add-product',
                    name: AppRoutes.addProductName,
                    parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) => const AddProductPage(),
                  ),
                  GoRoute(
                    path: AppRoutes.productDetails,
                    name: AppRoutes.productDetailsName,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final product = state.extra as Product;
                      return ProductDetailsPage(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Categories
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoryListPage(),
                routes: [
                  GoRoute(
                    path: 'create', // /categories/create
                    name: AppRoutes.createCategoryName,
                    parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) {
                      final category = state.extra as Category?;
                      return CreateCategoryPage(categoryToEdit: category);
                    },
                  ),
                  GoRoute(
                    path: 'products', // /categories/products
                    name: AppRoutes.categoryProductsName,
                    parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) {
                      final category = state.extra as Category;
                      return CategoryProductsPage(category: category);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});
