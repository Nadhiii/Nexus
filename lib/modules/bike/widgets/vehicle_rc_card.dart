import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/bike.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/bike_image_utils.dart';
import 'add_bike_dialog.dart';

class VehicleRCWidget extends StatefulWidget {
  final Bike bike;

  const VehicleRCWidget({super.key, required this.bike});

  @override
  State<VehicleRCWidget> createState() => _VehicleRCWidgetState();
}

class _VehicleRCWidgetState extends State<VehicleRCWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.ultra,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.backdropCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _animation.value < 0.5
                ? _buildFront()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi), // Mirror back
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  // --- FRONT SIDE (Clean & Official) ---
  Widget _buildCardBase({required Widget child}) {
    final imagePath = BikeImageUtils.getBikeImagePath(
      widget.bike.image,
      widget.bike.name,
      widget.bike.model,
    );
    final hasImage = imagePath != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      height: 200, // Fixed height for consistency during flip
      decoration: BoxDecoration(
        color: hasImage ? Colors.transparent : null,
        gradient: hasImage
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2D3D), // Muted Slate
                  Color(0xFF0A0A0A), // Near-Black
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ RC Card image load failed: $error');
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          if (hasImage)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
          // Watermark Icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              _getVehicleIcon(widget.bike),
              size: 150,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  // Decide icon based on make/model keywords (using API-provided values)
  IconData _getVehicleIcon(Bike bike) {
    final make = bike.make.toLowerCase();
    final model = bike.model.toLowerCase();

    // Scooter keywords
    const scooter = [
      'activa',
      'Honda dio',
      'jupiter',
      'maestro',
      'access',
      'pleasure',
      'fascino',
      'ray',
      'scooty',
      'ntorq',
      'burgman',
    ];

    // Common motorcycle keywords
    const moto = [
      'himalayan',
      'Royal Enfield',
      'KTM'
          'duke',
      'pulsar',
      'splendor',
      'bullet',
      'cb',
      'xpulse',
      'fz',
      'mt',
      'r15',
      'apache',
      'hornet',
      'ninja',
      'interceptor',
    ];

    // Car keywords (if you ever use this widget for cars)
    const car = [
      'swift',
      'baleno',
      'i20',
      'creta',
      'seltos',
      'city',
      'verna',
      'altroz',
      'nexon',
      'harrier',
      'xuv',
      'fortuner',
      'innova',
      'hector',
      'taigun',
    ];

    bool containsAny(List<String> keys) =>
        keys.any((k) => model.contains(k) || make.contains(k));

    if (containsAny(car)) return Icons.directions_car;
    if (containsAny(scooter)) {
      return Icons.two_wheeler; // Use bike icon for scooters
    }
    if (containsAny(moto)) return Icons.two_wheeler;

    // Fallback: prefer bike icon in Bike module
    return Icons.two_wheeler;
  }

  Widget _buildFront() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TOP ROW: Ind & Reg No
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'IND',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.bike.registrationNumber.isEmpty
                        ? 'NO REG'
                        : widget.bike.registrationNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.touch_app, color: Colors.white24, size: 18),
            ],
          ),

          // MIDDLE ROW: Owner & Model
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildInfoField(
                  'OWNER NAME',
                  widget.bike.ownerName ?? 'Unknown',
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildInfoField(
                  'MODEL',
                  '${widget.bike.make} ${widget.bike.model}',
                ),
              ),
            ],
          ),

          // BOTTOM ROW: Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoField('FUEL', widget.bike.fuelType ?? 'Petrol'),
              _buildInsuranceBadge(),
            ],
          ),
        ],
      ),
    );
  }

  // --- BACK SIDE (Technical Details) ---
  Widget _buildBack() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TECHNICAL SPECS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => _showEditDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // Details Grid
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoField(
                        'CHASSIS NO',
                        widget.bike.chassisNumber ?? '--',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoField(
                        'ENGINE NO',
                        widget.bike.engineNumber ?? '--',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoField(
                        'RTO',
                        widget.bike.rtoLocation?.split(',')[0] ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoField(
                        'YEAR',
                        widget.bike.year.toString(),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoField(
                        'INSURER',
                        widget.bike.insurer ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoField(
                        'EXPIRY',
                        widget.bike.policyExpiry != null
                            ? "${widget.bike.policyExpiry!.day}/${widget.bike.policyExpiry!.month}/${widget.bike.policyExpiry!.year}"
                            : "--",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceBadge() {
    final now = DateTime.now();
    final expiry = widget.bike.policyExpiry;

    if (expiry == null) {
      return _buildBadge('NO INFO', Colors.grey);
    }

    final isExpired = expiry.isBefore(now);
    final daysLeft = expiry.difference(now).inDays;
    final isExpiringSoon = daysLeft < 30 && !isExpired;

    if (isExpired) return _buildBadge('EXPIRED', AppColors.error);
    if (isExpiringSoon) return _buildBadge('RENEW SOON', Colors.orange);
    return _buildBadge('ACTIVE', AppColors.success);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddBikeDialog(bikeToEdit: widget.bike),
    );
  }
}
