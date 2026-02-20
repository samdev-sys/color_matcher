import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> recentPalettes = const [
    {'name': 'Oceanic Deep', 'colors': [Color(0xFF132020), Color(0xFF248f8f), Color(0xFF9ac1c1), Color(0xFFd0e5e5)]},
    {'name': 'Modern Retro', 'colors': [Color(0xFFf87171), Color(0xFFfbbf24), Color(0xFF34d399), Color(0xFF60a5fa)]},
    {'name': 'Brutalist Gray', 'colors': [Color(0xFF1e293b), Color(0xFF334155), Color(0xFF64748b), Color(0xFF94a3b8)]},
  ];

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConfig.authKey, false);
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _showHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = prefs.getStringList(AppConfig.historyKey) ?? [];
    
    final List<Map<String, dynamic>> history = historyStrings.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (e) {
        return {'hex': '#000000', 'name': 'Unknown', 'timestamp': DateTime.now().toIso8601String()};
      }
    }).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await prefs.remove(AppConfig.historyKey);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('History cleared')),
                          );
                        }
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No recent scans yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final DateTime date = DateTime.parse(item['timestamp'] ?? DateTime.now().toIso8601String());
                        final String formattedTime = DateFormat('MMM dd, HH:mm').format(date);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/color/${item['hex'].replaceAll('#', '')}');
                            },
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(int.parse((item['hex'] ?? '#000000').replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                            ),
                            title: Text(
                              item['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(formattedTime),
                            trailing: Text(
                              item['hex'] ?? '#000000',
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.palette, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 24 : 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: _showHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16, 
                24, 
                isTablet ? 32 : 16, 
                120 // Space for bottom nav
              ),
              children: [
                const Text(
                  'LAST SCANNED',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                
                // Last Scanned Responsive Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTap: () => context.push('/color/248f8f'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: isTablet ? 21 / 9 : 16 / 9,
                              child: Container(
                                color: const Color(0xFF248F8F),
                                child: const Stack(
                                  children: [
                                    Positioned(
                                      bottom: 16,
                                      left: 16,
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text('98% MATCH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 32 : 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('PANTONE FORMULA GUIDE', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('Pantone 3125 C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        Text('#248F8F', style: TextStyle(fontFamily: 'monospace', color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.grey[50],
                                        radius: isTablet ? 24 : 20,
                                        child: const Icon(Icons.share, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        radius: isTablet ? 24 : 20,
                                        child: const Icon(Icons.copy, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENT PALETTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextButton(onPressed: () {}, child: const Text('See All', style: TextStyle(color: AppColors.primary))),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Palettes Grid/List
                isTablet ? 
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: recentPalettes.length,
                    itemBuilder: (context, index) => _buildPaletteCard(recentPalettes[index]),
                  ) : 
                  Column(
                    children: recentPalettes.map((p) => _buildPaletteCard(p)).toList(),
                  ),
              ],
            ),
            
            // Floating Bottom Navigation
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       _NavIcon(icon: Icons.grid_view, label: 'Home', isSelected: true),
                       const SizedBox(width: 32),
                       _NavIcon(icon: Icons.bookmark, label: 'Library', isSelected: false),
                       const SizedBox(width: 32),
                       _NavIcon(
                         icon: Icons.person,
                         label: 'Profile',
                         isSelected: false,
                         onTap: () => context.go('/profile'),
                       ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Adjust to be above nav bar if needed
        child: FloatingActionButton(
          onPressed: () => context.push('/scanner'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPaletteCard(Map<String, dynamic> palette) {
    final colors = palette['colors'] as List<Color>;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: colors.map((c) => Expanded(child: Container(height: 80, color: c))).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(palette['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('4 COLORS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
