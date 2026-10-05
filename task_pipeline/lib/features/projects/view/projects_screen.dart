import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/logic/guest_sign_up_memory.dart';
import 'package:task_pipeline/features/auth/view/auth_screen.dart';
import 'package:task_pipeline/features/auth/view/profile_screen.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';
import 'package:task_pipeline/features/projects/view/edit_projects_screen.dart';
import 'package:task_pipeline/shared/widgets/cross_pattern_painter.dart';
import 'package:task_pipeline/features/projects/widgets/project_stack.dart';
import 'package:task_pipeline/features/tasks/view/tasks_screen.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';
import 'package:task_pipeline/shared/widgets/poker_chip_button.dart';

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

  /// After a guest signs up from a project's task screen and verifies their
  /// email, the app is rebuilt fresh; this brings them back to that project:
  /// the carousel on its card, and its task screen open on top.
  void _returnToProject(BuildContext context, ProjectState state) {
    if (state is! ProjectsLoaded) return;
    // Only a signed-up account returns; a guest who backed out of signing up
    // mustn't be moved around.
    if (context.read<AuthBloc>().state is! Authenticated) return;
    final memory = context.read<GuestSignUpMemory>();
    final id = memory.returnToProjectId;
    if (id == null) return;
    final index = state.projects.indexWhere((project) => project.id == id);
    if (index < 0) return;
    memory.returnToProjectId = null;

    final project = state.projects[index];
    setState(() => _page = index.toDouble());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasksScreen(
          projectId: project.id,
          projectName: project.name,
          projectColor: Theme.of(context).colorScheme.primary.toARGB32(),
        ),
      ),
    );
  }

  /// A guest's "Sign up": opens the create-account form, which upgrades the
  /// guest account. From here there's no project to come back to.
  void _signUpGuest(BuildContext context) {
    context.read<GuestSignUpMemory>().returnToProjectId = null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen(startCreating: true)),
    );
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

  /// The carousel card's size: a 5:7 card fitted inside the screen,
  /// constrained by whichever axis is limiting, so it survives portrait and
  /// landscape without overflowing (contain-fit, the same math AspectRatio uses).
  ({double width, double height}) _cardSizeFor(Size screenSize) {
    var height = screenSize.height * 0.8;
    var width = height * 5 / 7;
    final maxWidth = screenSize.width * 0.9;
    if (width > maxWidth) {
      width = maxWidth;
      height = width * 7 / 5;
    }
    return (width: width, height: height);
  }

  /// Opens the project editor with no project, which creates one. The add
  /// button and the editor share a Hero tag, so the new card grows out of it.
  void _openNewProject(BuildContext context) {
    final card = _cardSizeFor(MediaQuery.of(context).size);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) =>
            EditProjectScreen(cardWidth: card.width, cardHeight: card.height),
      ),
    );
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
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Stack(
        children: [
          // Its own layer, so the carousel animating on top doesn't
          // make the pattern repaint every frame.
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: CrossPatternPainter(color: green)),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: BlocConsumer<ProjectBloc, ProjectState>(
                listener: _returnToProject,
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

                    final screenHeight = MediaQuery.of(context).size.height;
                    final card = _cardSizeFor(MediaQuery.of(context).size);
                    final cardWidth = card.width;
                    final cardHeight = card.height;
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
                          _PreviousCardIntent:
                              CallbackAction<_PreviousCardIntent>(
                                onInvoke: (_) => _animateToPage(
                                  (_page.round() - 1).toDouble().clamp(
                                    0.0,
                                    _maxPage,
                                  ),
                                ),
                              ),
                          _NextCardIntent: CallbackAction<_NextCardIntent>(
                            onInvoke: (_) => _animateToPage(
                              (_page.round() + 1).toDouble().clamp(
                                0.0,
                                _maxPage,
                              ),
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
                                    () => _page =
                                        (_page - details.delta.dx / cardWidth)
                                            .clamp(0.0, _maxPage),
                                  );
                                },
                                onHorizontalDragEnd: (details) {
                                  if (details.velocity.pixelsPerSecond.dx
                                          .abs() >
                                      1) {
                                    _inertialScroll(
                                      details.velocity.pixelsPerSecond.dx,
                                      cardWidth,
                                    );
                                  } else {
                                    _animateToPage(
                                      _page.round().toDouble().clamp(
                                        0.0,
                                        _maxPage,
                                      ),
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
          ),
          // Where the app bar's account button used to be.
          Positioned(
            // Below the status bar / notch, like the app bar was.
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            // A guest gets "Sign up" here instead of their account page.
            child: BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) =>
                  (previous is Guest) != (current is Guest),
              builder: (context, auth) => auth is Guest
                  ? PokerChipButton(
                      size: 40,
                      icon: Icons.person_add_alt_1,
                      tooltip: 'Sign up to keep your projects',
                      onPressed: () => _signUpGuest(context),
                    )
                  : PokerChipButton(
                      size: 40,
                      icon: Icons.account_circle,
                      tooltip: 'Account',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      // The chip carries the Hero itself (FloatingActionButton used to), so the
      // new-project card still grows out of it.
      floatingActionButton: Hero(
        tag: newProjectHeroTag,
        child: PokerChipButton(
          icon: Icons.add,
          tooltip: 'Add Project',
          onPressed: () => _openNewProject(context),
        ),
      ),
    );
  }
}
