import 'package:flutter/material.dart';
import '../../models/inventory_data.dart';
import '../../models/user_data.dart';

/// Enum for sell multipliers
enum SellMultiplier {
  x1(1, '1x'),
  x10(10, '10x'),
  x100(100, '100x'),
  all(-1, 'All');

  final int value;
  final String label;

  const SellMultiplier(this.value, this.label);
}

/// Dialog for selling inventory items
class SellItemDialog extends StatefulWidget {
  final InventoryItem item;
  final int currentQuantity;
  final UserData? userData;

  const SellItemDialog({
    super.key,
    required this.item,
    required this.currentQuantity,
    required this.userData,
  });

  @override
  State<SellItemDialog> createState() => _SellItemDialogState();
}

class _SellItemDialogState extends State<SellItemDialog> {
  SellMultiplier _selectedMultiplier = SellMultiplier.x1;
  bool _isSelling = false;

  int get _quantityToSell {
    if (_selectedMultiplier == SellMultiplier.all) {
      return widget.currentQuantity;
    }
    return _selectedMultiplier.value.clamp(0, widget.currentQuantity);
  }

  int get _coinsToReceive {
    return widget.item.sellAmount * _quantityToSell;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildItemDisplay(),
            const SizedBox(height: 24),
            _buildMultiplierSelector(),
            const SizedBox(height: 24),
            _buildSellInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sell Item',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildItemDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Item icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.item.icon.isNotEmpty
                ? Image.asset(
                    widget.item.icon,
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 32);
                    },
                  )
                : const Icon(Icons.inventory_2, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available: ${widget.currentQuantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${widget.item.sellAmount} coins each',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: SellMultiplier.values.map((multiplier) {
            final isDisabled = multiplier != SellMultiplier.all &&
                multiplier.value > widget.currentQuantity;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildMultiplierButton(multiplier, isDisabled),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiplierButton(SellMultiplier multiplier, bool isDisabled) {
    final isSelected = _selectedMultiplier == multiplier;
    
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedMultiplier = multiplier;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade200
              : isSelected
                  ? Colors.blue.shade600
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : isSelected
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Text(
          multiplier.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDisabled
                ? Colors.grey.shade400
                : isSelected
                    ? Colors.white
                    : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSellInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selling: $_quantityToSell',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$_coinsToReceive',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSelling ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSelling || _quantityToSell <= 0 ? null : _handleSell,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sell ($_coinsToReceive)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSell() async {
    if (widget.userData == null) {
      _showErrorSnackBar('User data not available');
      return;
    }

    setState(() {
      _isSelling = true;
    });

    try {
      final success = await widget.userData!.sellItem(
        itemId: widget.item.id,
        quantity: _quantityToSell,
        sellAmountPerItem: widget.item.sellAmount,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sold $_quantityToSell ${widget.item.name} for $_coinsToReceive coins!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isSelling = false;
        });
        _showErrorSnackBar('Failed to sell item. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSelling = false;
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
