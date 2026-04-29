import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/localization/app_strings.dart';
import '../../core/location/address_search_service.dart';

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.strings,
  });

  final TextEditingController controller;
  final String labelText;
  final AppStrings strings;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _searchService = GeocodingAddressSearchService();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _isSelectingSuggestion = false;
  double? _userLatitude;
  double? _userLongitude;
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Fetch user location once without prompting for permission.
  Future<void> _tryFetchUserLocation() async {
    if (_locationFetched) return;
    _locationFetched = true;
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _userLatitude = last.latitude;
        _userLongitude = last.longitude;
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 5));
        _userLatitude = pos.latitude;
        _userLongitude = pos.longitude;
      }
    } catch (_) {
      // Location unavailable — search still works without bias.
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _tryFetchUserLocation();
    } else if (!_isSelectingSuggestion) {
      _debounce?.cancel();
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;
    _debounce?.cancel();
    final query = widget.controller.text.trim();
    if (query.length < 3) {
      if (_isSearching || _suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    final results = await _searchService.search(
      query,
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
    );
    if (!mounted) return;
    if (widget.controller.text.trim() != query) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _selectSuggestion(AddressSuggestion suggestion) {
    _isSelectingSuggestion = false;
    widget.controller.removeListener(_onTextChanged);
    widget.controller.value = TextEditingValue(
      text: suggestion.fullAddress,
      selection:
          TextSelection.collapsed(offset: suggestion.fullAddress.length),
    );
    setState(() {
      _suggestions = [];
      _isSearching = false;
    });
    widget.controller.addListener(_onTextChanged);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (!_isSearching &&
            _suggestions.isEmpty &&
            _focusNode.hasFocus &&
            widget.controller.text.trim().length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.strings.noAddressSuggestions,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Material(
            elevation: 3,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            color: cs.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions
                  .map(
                    (s) => InkWell(
                      onTapDown: (_) => _isSelectingSuggestion = true,
                      onTapCancel: () => _isSelectingSuggestion = false,
                      onTap: () => _selectSuggestion(s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (s.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      s.subtitle!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
