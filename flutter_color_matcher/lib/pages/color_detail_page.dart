import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/gemini_service.dart';
import '../theme.dart';

class ColorDetailPage extends StatefulWidget {
  final String hex;
  const ColorDetailPage({super.key, required this.hex});

  @override
  State<ColorDetailPage> createState() => _ColorDetailPageState();
}

class _ColorDetailPageState extends State<ColorDetailPage> {
  final GeminiService _geminiService = GeminiService();
  bool _loading = true;
  ColorData? _analysis;
  List<HarmonyColor> _harmonies = [];
  late Color _displayColor;

  @override
  void initState() {
    super.initState();
    _displayColor = _parseColor(widget.hex);
    _fetchData();
  }

  Color _parseColor(String hexStr) {
    hexStr = hexStr.replaceAll('#', '');
    if (hexStr.length == 6) {
      hexStr = 'FF$hexStr';
    }
    return Color(int.parse('0x$hexStr'));
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final hexWithHash = widget.hex.startsWith('#') ? widget.hex : '#${widget.hex}';
    
    final results = await Future.wait([
      _geminiService.getColorAnalysis(hexWithHash),
      _geminiService.generateHarmoniousPalette(hexWithHash),
    ]);

    if (mounted) {
      setState(() {
        _analysis = results[0] as ColorData?;
        _harmonies = results[1] as List<HarmonyColor>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Collapsible Header with flexible height
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _GlassButton(icon: Icons.arrow_back_ios_new, onTap: () => context.pop()),
            ),
            actions: [
              _GlassButton(icon: Icons.favorite_border, onTap: () {}),
              const SizedBox(width: 8),
              _GlassButton(icon: Icons.share, onTap: () {}),
              const SizedBox(width: 16),
            ],
            backgroundColor: _displayColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _displayColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COLOR PALETTE PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.black54)),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _analysis?.name ?? 'Loading...', 
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('#${widget.hex.toUpperCase()}', style: const TextStyle(fontSize: 18, fontFamily: 'monospace', color: Colors.black45)),
                  ],
                ),
              ),
            ),
          ),

          // Detailed Content
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? screenWidth * 0.1 : 24, 
                vertical: 32
              ),
              decoration: const BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _loading 
                  ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: CircularProgressIndicator(),
                  )) 
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Info Card
                        _buildResponsiveCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('PANTONE MATCHING SYSTEM', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(_analysis?.pantone ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.verified, color: Colors.white24),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 32),
                              Row(
                                children: [
                                  Expanded(child: _InfoItem('HEX CODE', '#${widget.hex.toUpperCase()}')),
                                  Expanded(child: _InfoItem('COLOR NAME', _analysis?.name ?? 'N/A')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Color Spaces
                        _buildResponsiveCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.format_paint, color: AppColors.primary),
                                  SizedBox(width: 12),
                                  Text('Color Spaces', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _DetailRow(
                                label: 'RGB Values', 
                                value: _analysis != null ? '${_analysis!.rgb.r}, ${_analysis!.rgb.g}, ${_analysis!.rgb.b}' : '...',
                              ),
                              const SizedBox(height: 16),
                              _DetailRow(
                                label: 'Psychology', 
                                value: _analysis?.description ?? '...',
                              ),
                            ],
                          ),
                        ),
                         const SizedBox(height: 32),
                         
                         // Harmonies
                         const Text('Harmonious Palette', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 16),
                         GridView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                             crossAxisCount: isTablet ? 3 : 2,
                             crossAxisSpacing: 16,
                             mainAxisSpacing: 16,
                             childAspectRatio: 1.2,
                           ),
                           itemCount: _harmonies.length,
                           itemBuilder: (context, index) {
                             final harmony = _harmonies[index];
                             return GestureDetector(
                               onTap: () => context.push('/color/${harmony.hex.replaceAll('#', '')}'),
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.05),
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: Colors.white10),
                                 ),
                                 child: Column(
                                   children: [
                                     Expanded(
                                       child: Container(
                                         decoration: BoxDecoration(
                                           color: _parseColor(harmony.hex),
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                       ),
                                     ),
                                     const SizedBox(height: 8),
                                     Text(harmony.type, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                                      Text(harmony.hex.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                   ],
                                 ),
                               ),
                             );
                           },
                         ),
                         const SizedBox(height: 100), // Space for bottom actions
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
        color: AppColors.backgroundDark.withOpacity(0.95),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                 onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add, size: 18),
                    SizedBox(width: 8),
                    Text('Save'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, height: 1.5)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }
}
