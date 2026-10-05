import 'package:flutter/material.dart';
import 'package:task_pipeline/features/projects/widgets/project_card.dart';
import 'package:task_pipeline/features/tasks/view/tasks_screen.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/features/projects/view/edit_projects_screen.dart';
/// Renders the focused-carousel stack of [ProjectCard]s for the given [page].
///
/// Cards are positioned and scaled based on their distance from [page], using
/// a small set of keyframes interpolated continuously so there's no snapping
/// as the user scrolls. Cards are painted farthest-first so nearer ones
/// correctly cover farther ones regardless of side.
class ProjectStack extends StatelessWidget {
  final double page;
  final List<Project> projects;
  final double cardWidth;
  final double cardHeight;
  final void Function(BuildContext context, Project project) onDelete;
  final void Function(int index) onFocusRequested;

  const ProjectStack({
    super.key,
    required this.page,
    required this.projects,
    required this.cardWidth,
    required this.cardHeight,
    required this.onDelete,
    required this.onFocusRequested,
  });

  static const List<({double distance, double scale, double offset})> _keyframes = [
    (distance: 0, scale: 1.0, offset: 0.0), // centered: full size
    (distance: 1, scale: 0.8, offset: 0.9), // first neighbour: smaller, fully visible
    (distance: 2, scale: 0.6, offset: 1.1), // second neighbour: partially hidden
    (distance: 3, scale: 0.6, offset: 1.2), // third+ neighbour: ~90% hidden
  ];

  ({double scale, double offset}) _cardTransformFor(double distance) {
    if (distance <= _keyframes.first.distance) {
      return (scale: _keyframes.first.scale, offset: _keyframes.first.offset);
    }
    if (distance >= _keyframes.last.distance) {
      return (
        scale: _keyframes.last.scale,
        offset: _keyframes.last.offset + 0.1 * (distance - _keyframes.last.distance),
      );
    }
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final a = _keyframes[i];
      final b = _keyframes[i + 1];
      if (distance >= a.distance && distance <= b.distance) {
        final t = (distance - a.distance) / (b.distance - a.distance);
        return (
          scale: a.scale + (b.scale - a.scale) * t,
          offset: a.offset + (b.offset - a.offset) * t,
        );
      }
    }
    return (scale: _keyframes.last.scale, offset: _keyframes.last.offset);
  }

  @override
  Widget build(BuildContext context) {
    const renderRadius = 3;
    final centerIndex = page.round();

    final indices = <int>[
      for (var i = centerIndex - renderRadius; i <= centerIndex + renderRadius; i++)
        if (i >= 0 && i < projects.length) i,
    ];
    // Farthest first, so nearer cards paint on top and correctly cover farther ones.
    indices.sort((a, b) => (b - page).abs().compareTo((a - page).abs()));

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: indices.map((index) {
          final project = projects[index];
          final delta = index - page;
          final transform = _cardTransformFor(delta.abs());
          final shift = delta.sign * transform.offset * cardWidth;

          return Transform.translate(
            key: ValueKey(project.id),
            offset: Offset(shift, 0),
            child: Transform.scale(
              scale: transform.scale,
              child: Hero(
                tag:project.id,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: ProjectCard(
                    project: project,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    scale: transform.scale,
                    onEdit: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, _, _) => EditProjectScreen(project: project, cardWidth: cardWidth, cardHeight: cardHeight),
                      ),
                    ),
                    onDelete: () => onDelete(context, project),
                    onTap: () {
                      if (delta.abs() < 1.5) {
                        if (delta.abs() >= 0.5) {
                          // Slightly off-center — snap to it first.
                          onFocusRequested(index);
                        }
                        // Already centered — navigate to its tasks.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TasksScreen(
                              projectId: project.id,
                              projectName: project.name,
                              projectColor: Theme.of(context).colorScheme.primary.toARGB32(),
                            ),
                          ),
                        );
                      } else {
                        // Off-center — bring it into focus first.
                        onFocusRequested(index);
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
