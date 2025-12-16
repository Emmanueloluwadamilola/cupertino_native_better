// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:cupertino_native_better/cupertino_native_better.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await PlatformVersion.initialize();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(home: NativeTabBarExample());
//   }
// }

// class NativeTabBarExample extends StatefulWidget {
//   const NativeTabBarExample({super.key});

//   @override
//   State<NativeTabBarExample> createState() => _NativeTabBarExampleState();
// }

// class _NativeTabBarExampleState extends State<NativeTabBarExample> {
//   int _currentIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     // Determine which page to show based on standard Flutter logic
//     // (though the Native Tab Bar will handle the actual view swapping at the root)
//     return Scaffold(
//       // The native tab bar sits "above" this Scaffold in the view hierarchy
//       // when enabled. We don't render a bottomNavigationBar here.
//       // Instead, we include the controller widget in the body or simply
//       // use it as a side-effect.
//       body: Stack(
//         children: [
//           _buildPage(_currentIndex),
//           CNNativeTabBar(
//             currentTab: _currentIndex,
//             onTabChanged: (index) {
//               setState(() => _currentIndex = index);
//             },
//             tabs: [
//               CNTab(title: 'Home', sfSymbol: CNSymbol('house.fill')),
//               CNTab(
//                 title: 'Search',
//                 sfSymbol: CNSymbol('magnifyingglass'),
//                 isSearchTab: true, // Native search tab behavior
//               ),
//               CNTab(
//                 title: 'Profile',
//                 sfSymbol: CNSymbol('person.fill'),
//                 badgeCount: 3,
//               ),
//             ],
//             // Optional: Handle search callbacks
//             onSearchChanged: (query) {
//               print('Search query: $query');
//             },
//             onSearchSubmitted: (query) {
//               print('Search submitted: $query');
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPage(int index) {
//     // This content will differ based on the selected tab
//     switch (index) {
//       case 0:
//         return const Center(child: Text('Home Page'));
//       case 1:
//         return const Center(
//           child: Text('Search Page (Content under search bar)'),
//         );
//       case 2:
//         return const Center(child: Text('Profile Page'));
//       default:
//         return const SizedBox();
//     }
//   }
// }
