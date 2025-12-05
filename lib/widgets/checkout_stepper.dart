import 'package:flutter/material.dart';
import 'package:myapp/config/app_theme.dart';

class CheckoutStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const CheckoutStepper({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            // Step item
            final stepIndex = index ~/ 2;
            return _buildStep(stepIndex);
          } else {
            // Connector
            final stepIndex = index ~/ 2;
            return _buildConnector(stepIndex);
          }
        }),
      ),
    );
  }

  Widget _buildStep(int index) {
    final isCompleted = index < currentStep;
    final isActive = index == currentStep;
    final isPending = index > currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with number or checkmark
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? AppColors.primary
                : Colors.grey[100],
            border: Border.all(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.white
                          : isPending
                          ? Colors.grey[400]
                          : AppColors.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Step label
        SizedBox(
          width: 80,
          child: Text(
            steps[index],
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isCompleted || isActive
                  ? AppColors.textPrimary
                  : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int index) {
    final isCompleted = index < currentStep;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 3,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
