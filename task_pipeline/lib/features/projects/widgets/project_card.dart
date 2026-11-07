import 'package:flutter/material.dart';
import 'package:task_pipeline/models/project.dart';

/// A tappable card representing a single project.
class ProjectCard extends StatelessWidget {
  final Project project;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.cardWidth,
    required this.cardHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final padding = cardHeight * 0.1;
    final innerWidth = cardWidth - padding;
    final innerHeight = cardHeight - padding * 1.5;
    return RepaintBoundary(
      child:Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.3),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding * 0.5, vertical: padding).copyWith(bottom: padding * 0.5),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    project.name,
                    style: TextStyle(fontSize: (innerWidth * 0.07).clamp(14, double.infinity), fontWeight: FontWeight.bold),
                  ),
                ),
                if (project.summary != null)
                  Positioned(
                    top: innerHeight / 3,
                    left: 0,
                    right: 0,
                    child: Text(
                      project.summary!,
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: (innerWidth * 0.03).clamp(12, double.infinity), color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
