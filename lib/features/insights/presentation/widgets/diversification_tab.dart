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
      const Color(0xFF3861FB),
      const Color(0xFF00D16C),
      const Color(0xFFFFAA00),
      const Color(0xFFFF4D4D),
      const Color(0xFFAD7BFF),
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
      Color riskColor = const Color(0xFF00D16C);
      if (pct > 60) {
        risk = 'High Concentration';
        riskColor = const Color(0xFFFF4D4D);
      } else if (pct > 30) {
        risk = 'Moderate';
        riskColor = const Color(0xFFFFAA00);
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
              color: const Color(0xFF3861FB).withOpacity(0.3),
            ),
            MapColorMapper(
              from: 20,
              to: 50,
              color: const Color(0xFF3861FB).withOpacity(0.6),
            ),
            const MapColorMapper(from: 50, to: 100, color: Color(0xFF3861FB)),
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
          _buildBarChart(sectors),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildBarChart(List<SectorExposure> sectors) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray70),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100, // Limite à 100%
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sectors[v.toInt()].name.substring(0, 3).toUpperCase(),
                    style: TextStyle(color: AppColors.gray40, fontSize: 10),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (v, m) => Text(
                  '${v.toInt()}%',
                  style: TextStyle(color: AppColors.gray40, fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: AppColors.gray70, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sectors
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.percentage,
                      color: e.value.color,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMapSection(List<GeographicExposure> countries) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray70),
      ),
      child: _isMapLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SfMaps(
                layers: [
                  MapShapeLayer(
                    source: _mapSource,
                    zoomPanBehavior: _zoomPanBehavior,
                    color: Colors.white.withOpacity(0.05),
                    strokeColor: AppColors.gray70.withOpacity(0.3),
                    shapeTooltipBuilder: (ctx, index) {
                      final c = countries[index];
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${c.name}: ${c.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Les autres widgets (_buildSectorItem, _buildCountryCard, _buildBadge) restent identiques à ton code précédent...
  Widget _buildSectorItem(SectorExposure sector) {
    final isOverexposed = sector.percentage > 40;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverexposed
            ? const Color(0xFFFF4D4D).withOpacity(0.05)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverexposed
              ? const Color(0xFFFF4D4D).withOpacity(0.3)
              : AppColors.gray70,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: sector.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sector.name,
              style: AppTypography.headline3Medium.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          if (isOverexposed)
            _buildBadge('Overexposed', const Color(0xFFFF4D4D)),
          const SizedBox(width: 8),
          Text(
            '${sector.percentage.toStringAsFixed(1)}%',
            style: AppTypography.headline3Bold.copyWith(color: sector.color),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCard(int index, GeographicExposure country) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray70),
      ),
      child: Row(
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 22)),
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
              color: AppColors.primary,
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
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
