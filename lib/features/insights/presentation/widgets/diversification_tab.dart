import 'package:fl_chart/fl_chart.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class DiversificationTab extends StatefulWidget {
  final NetworthResponse networth;

  const DiversificationTab({super.key, required this.networth});

  @override
  State<DiversificationTab> createState() => _DiversificationTabState();
}

class _DiversificationTabState extends State<DiversificationTab> {
  late MapShapeSource _mapSource;
  late MapZoomPanBehavior _zoomPanBehavior;
  bool _isMapLoading = true;

  // --- LOGIQUE DE CALCUL DES POURCENTAGES RÉELS ---

  List<SectorExposure> get sectorAllocations {
    final rawData = widget.networth.breakdown.bySector;
    if (rawData.isEmpty) return [];

    // 1. Calculer la somme totale des montants
    double totalValue = rawData.values.fold(0, (sum, val) => sum + val.abs());

    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFFAD7BFF),
      AppColors.accentS,
    ];
    int i = 0;

    // 2. Transformer en pourcentages réels
    return rawData.entries.map((e) {
      double pct = totalValue > 0 ? (e.value.abs() / totalValue) * 100 : 0;
      return SectorExposure(
        name: e.key,
        percentage: pct,
        color: colors[i++ % colors.length],
      );
    }).toList();
  }

  List<GeographicExposure> get countryAllocations {
    final rawData = widget.networth.breakdown.byCountry;
    if (rawData.isEmpty) return [];

    double totalValue = rawData.values.fold(0, (sum, val) => sum + val.abs());

    return rawData.entries.map((e) {
      double pct = totalValue > 0 ? (e.value.abs() / totalValue) * 100 : 0;

      String risk = 'Low';
      Color riskColor = AppColors.success;
      if (pct > 60) {
        risk = 'High Concentration';
        riskColor = AppColors.error;
      } else if (pct > 30) {
        risk = 'Moderate';
        riskColor = AppColors.warning;
      }

      return GeographicExposure(
        name: _normalizeCountryName(e.key), // On normalise pour la carte
        code: e.key,
        flag: _getFlag(e.key),
        percentage: pct,
        amount: e.value,
        riskLevel: risk,
        riskColor: riskColor,
      );
    }).toList();
  }

  // --- UTILS ---

  // Important: Cette fonction doit faire correspondre tes codes (US, FR)
  // aux noms exacts dans ton world_map.json (United States, France, etc.)
  String _normalizeCountryName(String code) {
    Map<String, String> mapping = {
      'US': 'United States',
      'FR': 'France',
      'GB': 'United Kingdom',
      'DE': 'Germany',
      'JP': 'Japan',
      'CH': 'Switzerland',
      'CN': 'China',
      'BR': 'Brazil',
      'AF': 'Afghanistan',
      // Ajoute d'autres codes si nécessaire
    };
    return mapping[code.toUpperCase()] ?? code;
  }

  String _getFlag(String code) {
    return code.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = MapZoomPanBehavior(
      enableDoubleTapZooming: true,
      enablePanning: true,
      zoomLevel: 1.2,
    );
    _initMap();
  }

  Future<void> _initMap() async {
    // Simuler un léger délai pour charger l'asset
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _mapSource = MapShapeSource.asset(
          'assets/world_map.json',
          shapeDataField: 'name', // Doit matcher le champ "name" dans le JSON
          dataCount: countryAllocations.length,
          primaryValueMapper: (int index) => countryAllocations[index].name,
          shapeColorValueMapper: (int index) =>
              countryAllocations[index].percentage,
          shapeColorMappers: [
            MapColorMapper(
              from: 0,
              to: 20,
              color: AppColors.primary.withOpacity(0.3),
            ),
            MapColorMapper(
              from: 20,
              to: 50,
              color: AppColors.primary.withOpacity(0.6),
            ),
            MapColorMapper(from: 50, to: 100, color: AppColors.primary),
          ],
        );
        _isMapLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectors = sectorAllocations;
    final countries = countryAllocations;

    if (sectors.isEmpty) {
      return const Center(
        child: Text(
          "No exposure data. Sync your assets first.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sector Exposure',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // _buildBarChart(sectors), // Removed BarChart to cleaner look, using progress bars in cards instead
          // const SizedBox(height: 16),
          ...sectors.map((s) => _buildSectorItem(s)),
          const SizedBox(height: 32),
          Text(
            'Geographic Exposure',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildMapSection(countries),
          const SizedBox(height: 24),
          Text(
            'Country Breakdown',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...countries.asMap().entries.map(
            (e) => _buildCountryCard(e.key, e.value),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMapSection(List<GeographicExposure> countries) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: _isMapLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SfMaps(
                layers: [
                  MapShapeLayer(
                    source: _mapSource,
                    zoomPanBehavior: _zoomPanBehavior,
                    color: AppColors.white.withOpacity(0.05),
                    strokeColor: AppColors.white.withOpacity(0.1),
                    strokeWidth: 0.5,
                    shapeTooltipBuilder: (ctx, index) {
                      final c = countries[index];
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gray80,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '${c.name}: ${c.percentage.toStringAsFixed(1)}%',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectorItem(SectorExposure sector) {
    // final isOverexposed = sector.percentage > 40; // Removed warning styling for cleaner look

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sector.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    sector.name.substring(0, 1),
                    style: TextStyle(
                      color: sector.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sector.name,
                      style: AppTypography.headline3SemiBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sector.percentage.toStringAsFixed(1)}% exposure',
                      style: AppTypography.headline1Regular.copyWith(
                        color: AppColors.gray40,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${sector.percentage.toStringAsFixed(1)}%',
                style: AppTypography.headline3Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sector.percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.gray60.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(sector.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCard(int index, GeographicExposure country) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray60.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(country.flag, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country.name,
                  style: AppTypography.headline3Medium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _buildBadge(country.riskLevel, country.riskColor),
              ],
            ),
          ),
          Text(
            '${country.percentage.toStringAsFixed(1)}%',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class SectorExposure {
  final String name;
  final double percentage;
  final Color color;

  SectorExposure({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

class GeographicExposure {
  final String name;
  final String code;
  final String flag;
  final double percentage;
  final double amount;
  final String riskLevel;
  final Color riskColor;

  GeographicExposure({
    required this.name,
    required this.code,
    required this.flag,
    required this.percentage,
    required this.amount,
    required this.riskLevel,
    required this.riskColor,
  });
}
