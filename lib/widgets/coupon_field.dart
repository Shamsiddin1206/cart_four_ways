import 'package:flutter/material.dart';

/// Owns only its text controller. Typing never touches cart state.
class CouponField extends StatefulWidget {
  const CouponField({
    super.key,
    required this.appliedCoupon,
    required this.error,
    required this.onApply,
  });

  final String? appliedCoupon;
  final String? error;
  final void Function(String code) onApply;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Coupon code',
              errorText: widget.error,
              helperText: widget.appliedCoupon == null
                  ? null
                  : 'Applied: ${widget.appliedCoupon}',
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => widget.onApply(_controller.text.trim()),
          child: const Text('Apply'),
        ),
      ],
    ),
  );
}
