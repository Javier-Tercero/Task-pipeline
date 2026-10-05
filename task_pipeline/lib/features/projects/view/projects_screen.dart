import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/view/profile_screen.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';
import 'package:task_pipeline/features/projects/widgets/project_stack.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';

// Marker intents for keyboard-driven carousel navigation (desktop/web —
// arrow keys are inert on mobile, since there's no physical keyboard event
// to trigger them).
class _PreviousCardIntent extends Intent {
  const _PreviousCardIntent();
}

class _NextCardIntent extends Intent {
  const _NextCardIntent();
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  double _page = 0;
  double _maxPage = 0;
  late final AnimationController _snapController;
  Timer? _scrollEndTimer;
  Duration? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _snapController =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 200),
          upperBound: 1000.0,
        )..addListener(() {
          setState(() => _page = _snapController.value.clamp(0.0, _maxPage));
        });
  }

  void _animateToPage(double target) {
    _scrollEndTimer?.cancel();
    _snapController.value = _page;
    _snapController.animateTo(target, curve: Curves.easeOut);
  }

  void _inertialScroll(double velocity, double cardWidth) {
    const friction = 0.1;
    final normalizedVelocity = -velocity / cardWidth;
    final simulation = FrictionSimulation(friction, _page, normalizedVelocity);
    if (simulation.finalX >= _maxPage ||
        simulation.finalX <= 0 ||
        simulation.finalX % 1 == 0) {
      _snapController.animateWith(simulation);
      return;
    }
    final target = simulation.finalX.round().toDouble().clamp(0.0, _maxPage);
    final newVelocity = (_page - target) * math.log(friction);
    final newSimulation = FrictionSimulation(friction, _page, newVelocity);
    _snapController.animateWith(newSimulation);
  }

  void _handleScroll(PointerScrollEvent event, double cardWidth) {
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
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
                    context.read<ProjectBloc>().add(
                      AddProject(name, summary: summary),
                    );
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

  void _randomcolorGenerator(BuildContext context) {
    final random = math.Random();
    final pallete = [
      0xFFEDE3C8,
      0xFFC97C5D,
      0xFFF4F6F0,
      0xFFFFEB7A,
      0xFF7FA9E6,
      0xFFEEAA99,
    ];
    final color = Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
    // TODO: color: is a named arg but AddProject.color is positional, and
    // AddProject now requires 2 positional args — commented out until fixed.
    // context.read<ProjectBloc>().add(AddProject('New Project', color: color.value));
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
      appBar: AppBar(
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, auth) {
            final name = auth is Authenticated ? auth.displayName : null;
            return Text(
              name == null || name.isEmpty ? 'Projects' : "$name's projects",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      body: Container(
        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            if (state is ProjectsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProjectsError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          context.read<ProjectBloc>().add(LoadProjects()),
                    ),
                  ],
                ),
              );
            }

            if (state is ProjectsLoaded) {
              if (state.projects.isEmpty) {
                return const EmptyState(
                  message: 'No projects yet. Tap + to add one.',
                );
              }

              final screenSize = MediaQuery.of(context).size;
              final screenHeight = screenSize.height;
              final screenWidth = screenSize.width;
              double cardHeight = screenHeight * 0.8;
              double cardWidth = cardHeight * 5 / 7;
              final maxWidth = screenWidth * 0.9;
              if (cardWidth > maxWidth) {
                cardWidth = maxWidth;
                cardHeight = cardWidth * 7 / 5;
              }
              _maxPage = (state.projects.length - 1).toDouble();

              return Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                      const _PreviousCardIntent(),
                  LogicalKeySet(LogicalKeyboardKey.arrowRight):
                      const _NextCardIntent(),
                },
                child: Actions(
                  actions: {
                    _PreviousCardIntent: CallbackAction<_PreviousCardIntent>(
                      onInvoke: (_) => _animateToPage(
                        (_page.round() - 1).toDouble().clamp(0.0, _maxPage),
                      ),
                    ),
                    _NextCardIntent: CallbackAction<_NextCardIntent>(
                      onInvoke: (_) => _animateToPage(
                        (_page.round() + 1).toDouble().clamp(0.0, _maxPage),
                      ),
                    ),
                  },
                  child: Focus(
                    autofocus: true,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.1,
                      ),
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _handleScroll(event, cardWidth);
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) {
                            _snapController.stop();
                            _scrollEndTimer?.cancel();
                          },
                          onHorizontalDragUpdate: (details) {
                            setState(
                              () =>
                                  _page = (_page - details.delta.dx / cardWidth)
                                      .clamp(0.0, _maxPage),
                            );
                          },
                          onHorizontalDragEnd: (details) {
                            if (details.velocity.pixelsPerSecond.dx.abs() > 1) {
                              _inertialScroll(
                                details.velocity.pixelsPerSecond.dx,
                                cardWidth,
                              );
                            } else {
                              _animateToPage(
                                _page.round().toDouble().clamp(0.0, _maxPage),
                              );
                            }
                          },
                          child: ProjectStack(
                            page: _page,
                            projects: state.projects,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            onDelete: _showDeleteDialog,
                            onFocusRequested: (index) =>
                                _animateToPage(index.toDouble()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            // ProjectsInitial — nothing to show yet.
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
