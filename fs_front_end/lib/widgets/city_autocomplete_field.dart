import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http_client;

import '../theme/app_colors.dart';

class CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final Color? cursorColor;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.cursorColor,
    this.onSelected,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  Timer? _debounce;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.trim().length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchCities(value.trim()),
    );
  }

  Future<void> _fetchCities(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'city': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'fr',
      });
      final resp = await http_client
          .get(uri, headers: {
            'Accept-Language': 'fr',
            'User-Agent': 'FiveStar5v5App/1.0',
          })
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final seen = <String>{};
        final cities = <String>[];
        for (final item in data) {
          final addr = item['address'] as Map<String, dynamic>?;
          if (addr == null) continue;
          final name = (addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['municipality']) as String?;
          if (name != null && seen.add(name)) cities.add(name);
          if (cities.length >= 5) break;
        }
        setState(() => _suggestions = cities);
      }
    } catch (_) {}
  }

  void _select(String city) {
    widget.controller.text = city;
    widget.controller.selection =
        TextSelection.collapsed(offset: city.length);
    widget.onSelected?.call(city);
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          style: widget.style,
          cursorColor: widget.cursorColor,
          decoration: widget.decoration,
          onChanged: _onChanged,
          onSubmitted: widget.onSubmitted,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.asMap().entries.map((e) {
                final isLast = e.key == _suggestions.length - 1;
                return InkWell(
                  onTap: () => _select(e.value),
                  borderRadius: BorderRadius.vertical(
                    top: e.key == 0 ? const Radius.circular(10) : Radius.zero,
                    bottom:
                        isLast ? const Radius.circular(10) : Radius.zero,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom:
                                  BorderSide(color: AppColors.border2),
                            ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_city_outlined,
                          size: 14,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.value,
                          style: GoogleFonts.dmSans(
                            color: AppColors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
