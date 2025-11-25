import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/models/mutualfunds.dart';
import '../../core/theme/app_typography.dart';

class MutualFundSearchScreen extends StatefulWidget {
  const MutualFundSearchScreen({super.key});

  @override
  _MutualFundSearchScreenState createState() => _MutualFundSearchScreenState();
}

class _MutualFundSearchScreenState extends State<MutualFundSearchScreen> {
  List<MutualFund> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  Future<void> _searchFunds(String query) async {
    setState(() {
      _query = query;
      if (query.length < 3) {
        _searchResults.clear();
        return;
      }
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.mfapi.in/mf/search?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _searchResults = data
              .map((json) => MutualFund.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to fetch data. Please try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred. Please check your connection.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Mutual Funds')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _searchFunds,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for funds (e.g., SBI Small Cap)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return _buildErrorState();
    } else if (_query.length < 3) {
      return _buildInitialState();
    } else if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    } else {
      return _buildResultsList();
    }
  }

  Widget _buildInitialState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for any mutual fund',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter at least 3 characters to begin.',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final fund = _searchResults[index];
        return ListTile(
          title: Text(fund.schemeName),
          subtitle: Text(
            fund.schemeCode,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          onTap: () {
            Navigator.of(context).pop(fund);
          },
        );
      },
    );
  }
}
