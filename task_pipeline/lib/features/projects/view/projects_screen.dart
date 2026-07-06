import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';
import 'package:task_pipeline/features/projects/widgets/project_stack.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}


class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {

  double _page = 0;
  double _maxPage = 0;
  late final AnimationController _snapController;
  Timer? _scrollEndTimer;
  Duration? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
      upperBound: 1000.0,
    )..addListener(() {
        setState(() => _page = _snapController.value.clamp(0.0, _maxPage));
      });
  }

  void _animateToPage(double target) {
    _scrollEndTimer?.cancel();
    _snapController.value = _page;
    _snapController.animateTo(target, curve:Curves.easeOut);
  }

  void _inertialScroll(double velocity, double cardWidth) {
    const friction = 0.1;
    final normalizedVelocity = -velocity / cardWidth;
    final simulation = FrictionSimulation(friction, _page, normalizedVelocity);
    if (simulation.finalX >= _maxPage || simulation.finalX <= 0 ||simulation.finalX % 1 == 0) {
      _snapController.animateWith(simulation);
      return;
    }
      final target = simulation.finalX.round().toDouble().clamp(0.0, _maxPage);
      final newVelocity = (_page - target) * math.log(friction);
      final newSimulation = FrictionSimulation(friction, _page, newVelocity);
      _snapController.animateWith(newSimulation);
  }

  void _handleScroll(PointerScrollEvent event, double cardWidth) {
    final delta = event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    setState(() => _page = (_page + delta / cardWidth).clamp(0.0, _maxPage));

    final now = event.timeStamp;
    double velocity = 0;
    if (_lastScrollTime != null) {
      final elapsed = (now - _lastScrollTime!).inMilliseconds;
      if (elapsed > 0) velocity = delta / elapsed;
    }
    _lastScrollTime = now;

    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 200), () {
      if (velocity.abs() >= 1) {
        _inertialScroll(velocity * 1000, cardWidth);
      } else {
        if (delta >= 0) {
          _animateToPage(_page.ceilToDouble().clamp(0.0, _maxPage));
        } else {
          _animateToPage(_page.floorToDouble().clamp(0.0, _maxPage));
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _snapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final summaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Project name'),
              ),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(hintText: 'Project summary'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  // Use outer context — dialog context may not carry the bloc.
                  final summary = summaryController.text.trim();
                  if (summary.isNotEmpty) {
                    context.read<ProjectBloc>().add(AddProject(name, summary: summary));
                  } else {
                    context.read<ProjectBloc>().add(AddProject(name));
                  }
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      summaryController.dispose();
    });
  }

  void _showEditDialog(BuildContext context, Project project) {
    final nameController = TextEditingController(text: project.name);
    final summaryController = TextEditingController(text: project.summary);


    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(project.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
              ),
              TextField(
                controller: summaryController,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Project summary'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final summary = summaryController.text.trim();
                final newName = name.isNotEmpty ? name : null;
                final newSummary = summary.isNotEmpty ? summary : null;
                if (newName != null || newSummary != null) {
                  context.read<ProjectBloc>().add(
                        EditProject(project.id, newName: newName, newSummary: newSummary),
                      );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      summaryController.dispose();
    });
  }

  void _showDeleteDialog(BuildContext context, Project project) {

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Are you sure you want to delete ${project.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<ProjectBloc>().add(DeleteProject(project.id));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete project'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectsError) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ProjectBloc>().add(LoadProjects()),
                ),
              ],
            ));
          }
          if (state is ProjectsLoaded) {
            if (state.projects.isEmpty) {
              return const EmptyState(message: 'No projects yet. Tap + to add one.');
            }
            final screenHeight = MediaQuery.of(context).size.height;
            final cardHeight = screenHeight * 0.8;
            final cardWidth = cardHeight * 5 / 7;
            _maxPage = (state.projects.length - 1).toDouble();
            return Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.1),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _handleScroll(event, cardWidth);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart:(_){
                    _snapController.stop();
                    _scrollEndTimer?.cancel();
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() => _page = (_page - details.delta.dx / cardWidth).clamp(0.0, _maxPage));
                  },
                  onHorizontalDragEnd: (details) {
                    if (details.velocity.pixelsPerSecond.dx.abs() > 1) {
                      _inertialScroll(details.velocity.pixelsPerSecond.dx, cardWidth);
                    } else {
                      _animateToPage(_page.round().toDouble().clamp(0.0, _maxPage));
                    }
                  },
                  child: ProjectStack(
                    page: _page,
                    projects: state.projects,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    onEdit: _showEditDialog,
                    onDelete: _showDeleteDialog,
                    onFocusRequested: (index) => _animateToPage(index.toDouble()),
                  ),
                ),
              ),
            );
          }
          // ProjectsInitial — nothing to show yet.
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
