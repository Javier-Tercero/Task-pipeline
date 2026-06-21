import 'package:flutter/material.dart';
import 'package:task_pipeline/models/project.dart';

/// A tappable card representing a single project.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.6,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxHeight * 0.1;
                final cardWidth = constraints.maxHeight - padding * 0.5;
                final innerHeight = constraints.maxHeight - padding * 2;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding * 0.5, vertical: padding),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          project.name,
                          style: TextStyle(fontSize: (cardWidth * 0.07).clamp(14, double.infinity), fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontSize: (cardWidth * 0.03).clamp(12, double.infinity), color: Colors.grey),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: onEdit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: onDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
