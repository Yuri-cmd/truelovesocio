// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class DishItemWidget extends StatefulWidget {
  final String name;
  final String price;
  final bool isActive;
  final String imageUrl;
  final Function(bool) onToggle;

  const DishItemWidget({
    super.key,
    required this.name,
    required this.price,
    required this.isActive,
    required this.imageUrl,
    required this.onToggle,
  });

  @override
  _DishItemWidgetState createState() => _DishItemWidgetState();
}

class _DishItemWidgetState extends State<DishItemWidget> {
  late bool status;

  @override
  void initState() {
    super.initState();
    status = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark 
            ? Border.all(color: Colors.white12, width: 0.5) 
            : Border.all(color: Colors.black.withAlpha(8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Image Section
              Stack(
                children: [
                  Hero(
                    tag: 'dish_image_${widget.name}',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                      ),
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'images/default.jpg',
                          fit: BoxFit.cover,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: Colors.red[200],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (!status)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha(100),
                        child: const Center(
                          child: Icon(Icons.visibility_off_rounded, color: Colors.white70),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'S/ ${widget.price}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status ? 'ACTIVO' : 'INACTIVO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: status ? Colors.green[600] : Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FlutterSwitch(
                      width: 48.0,
                      height: 24.0,
                      valueFontSize: 10.0,
                      toggleSize: 18.0,
                      value: status,
                      borderRadius: 30.0,
                      padding: 3.0,
                      activeColor: Colors.red[700]!,
                      inactiveColor: isDark ? Colors.white10 : Colors.grey[300]!,
                      onToggle: (val) {
                        setState(() {
                          status = val;
                          widget.onToggle(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}