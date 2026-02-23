import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/bike.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import 'add_bike.dart';

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
      duration: AppAnimations.slow,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
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

  // --- BASE CARD DESIGN ---
  Widget _buildCardBase({required Widget child, bool isBack = false}) {
    return Container(
      height: 240, // Increased from 220 to give the text breathing room
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0F172A), // Slate 900
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Subtle background pattern/mesh
          Positioned(
            right: -50,
            bottom: -50,
            child: Icon(
              Icons.fingerprint,
              size: 250,
              color: Colors.white.withOpacity(0.02),
            ),
          ),
          if (isBack)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                color: Colors.black.withOpacity(0.8),
              ), // Magnetic stripe look
            ),
          child,
        ],
      ),
    );
  }

  // --- FRONT SIDE ---
  Widget _buildFront() {
    return _buildCardBase(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TOP: IND Plate & Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.orange,
                          ), // Chakra
                          SizedBox(height: 2),
                          Text(
                            'IND',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        widget.bike.registrationNumber.isEmpty
                            ? 'UNREGISTERED'
                            : widget.bike.registrationNumber,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.sim_card,
                  color: Color(0xFFFFD700),
                  size: 32,
                ), // Gold Chip
              ],
            ),

            // MIDDLE: Model & Class
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.bike.make} ${widget.bike.model}'.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '2-WHEELER • ${widget.bike.fuelType?.toUpperCase() ?? 'PETROL'}',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            // BOTTOM: Owner & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OWNER NAME',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        widget.bike.ownerName?.toUpperCase() ?? 'UNKNOWN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildInsuranceBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- BACK SIDE ---
  Widget _buildBack() {
    return _buildCardBase(
      isBack: true,
      child: Padding(
        // Reduced top padding from 80 to 72, and bottom to 16
        padding: const EdgeInsets.only(
          top: 72,
          left: 24,
          right: 24,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TECHNICAL DETAILS",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) =>
                        ModernAddBikeScreen(bikeToEdit: widget.bike),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16
            Expanded(
              child: Column(
                // Changed from spaceEvenly to spaceBetween to prevent overflow
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoField(
                          'CHASSIS NO',
                          widget.bike.chassisNumber ?? 'N/A',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoField(
                          'ENGINE NO',
                          widget.bike.engineNumber ?? 'N/A',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoField(
                          'RTO LOCATION',
                          widget.bike.rtoLocation?.split(',')[0] ?? 'N/A',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoField(
                          'MFG YEAR',
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
                          'INSURANCE EXPIRY',
                          widget.bike.policyExpiry != null
                              ? "${widget.bike.policyExpiry!.day}/${widget.bike.policyExpiry!.month}/${widget.bike.policyExpiry!.year}"
                              : "N/A",
                        ),
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

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 8,
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceBadge() {
    final now = DateTime.now();
    final expiry = widget.bike.policyExpiry;

    if (expiry == null) return _buildBadge('NO INSURANCE', Colors.grey);
    final isExpired = expiry.isBefore(now);
    final isExpiringSoon = expiry.difference(now).inDays < 30 && !isExpired;

    if (isExpired) return _buildBadge('EXPIRED', AppColors.error);
    if (isExpiringSoon) return _buildBadge('RENEW SOON', Colors.orange);
    return _buildBadge('ACTIVE', AppColors.success);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
