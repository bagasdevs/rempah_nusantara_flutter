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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: AppColors.surface,
      child: Row(
        children: List.generate(
          steps.length,
          (index) => Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStep(index)),
                if (index < steps.length - 1)
                  Expanded(child: _buildConnector(index)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    final isCompleted = index < currentStep;
    final isActive = index == currentStep;
    final isPending = index > currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : isActive
                ? AppColors.primary
                : AppColors.background,
            border: Border.all(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.white
                          : isPending
                          ? AppColors.textHint
                          : AppColors.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          steps[index],
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isCompleted || isActive
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConnector(int index) {
    final isCompleted = index < currentStep;

    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? AppColors.primary : AppColors.border,
    );
  }
}
