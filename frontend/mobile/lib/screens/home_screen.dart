import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/route_provider.dart';
import '../widgets/route_card.dart';
import 'add_route_screen.dart';
import 'checklist_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    await routeProvider.loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('שלום ${user?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChecklistScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<RouteProvider>(
          builder: (context, routeProvider, _) {
            if (routeProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (routeProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: AppTheme.error),
                    const SizedBox(height: 20),
                    Text(
                      'שגיאה בטעינת המסלולים',
                      style: AppTheme.headline3,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('נסה שוב'),
                    ),
                  ],
                ),
              );
            }

            if (routeProvider.routes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_bus_outlined,
                      size: 100,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'אין לך מסלולים קבועים',
                      style: AppTheme.headline3,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'הוסף מסלול כדי להתחיל לקבל התרעות',
                      style: AppTheme.bodyLarge,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddRouteScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('הוסף מסלול ראשון'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routeProvider.routes.length,
              itemBuilder: (context, index) {
                final route = routeProvider.routes[index];
                return RouteCard(route: route);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddRouteScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('הוסף מסלול'),
      ),
    );
  }
}
