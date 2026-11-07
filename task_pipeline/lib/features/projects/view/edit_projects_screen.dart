import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/shared/extensions/context.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';

/// Hero tag shared by the "add project" button and the editor it opens, so the
/// new card grows out of the button.
const String newProjectHeroTag = 'new-project';

/// Edits a project, or creates one when [project] is null.
class EditProjectScreen extends StatefulWidget {
  final Project? project;
  final double cardWidth;
  final double cardHeight;

  /// When creating: called with the new project's ID once its card is in the
  /// carousel, just before this screen closes, so the carousel can centre it
  /// for the card to shrink onto.
  final void Function(String id)? onCreated;

  const EditProjectScreen({
    super.key,
    this.project,
    required this.cardWidth,
    required this.cardHeight,
    this.onCreated,
  });
  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late final _nameController = TextEditingController(
    text: widget.project?.name,
  );
  late final _summaryController = TextEditingController(
    text: widget.project?.summary,
  );
  late final double cardWidth = widget.cardWidth;
  late final double cardHeight = widget.cardHeight;

  bool get _creating => widget.project == null;

  // While a new project is being saved: the buttons are disabled.
  bool _saving = false;

  // The new project's ID once its card is in the carousel. The Hero takes it
  // as its tag, so closing flies onto that card instead of the add button.
  String? _createdId;

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;
    final padding = cardHeight * 0.1;
    final innerWidth = cardWidth - padding;
    final hintStyle = TextStyle(
      color: Colors.grey.shade600.withValues(alpha: 0.5),
    );

    return Scaffold(
      // Transparent, so the carousel underneath shows around the card (the
      // route is pushed non-opaque, see ProjectStack).
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.02,
            vertical: screenSize.height * 0.02,
          ),
          child: SizedBox.expand(
            // Card shrink-wraps by default — force it to fill the safe area so
            // the Hero has a full-screen rect to land on.
            child: Hero(
              // MUST match the carousel card's tag, or the add button's.
              tag: _createdId ?? widget.project?.id ?? newProjectHeroTag,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.3),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        // Subtract the scroll view's vertical padding (24 top + 24 bottom)
                        // so content + padding fits the viewport exactly, instead of
                        // pushing the bottom buttons 48px off-screen.
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              // Cue that this card doesn't exist yet.
                              if (_creating)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'New project',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ),
                              TextField(
                                controller: _nameController,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                // Matches ProjectCard's name Text style, so the
                                // field doesn't look visually different from
                                // how the name reads on the card itself.
                                style: TextStyle(
                                  fontSize: (innerWidth * 0.07).clamp(
                                    14,
                                    double.infinity,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: hintStyle,
                                  hintText: 'Title',
                                ),
                              ),
                              TextField(
                                controller: _summaryController,
                                maxLines: null,
                                textAlign: TextAlign.justify,
                                // Matches ProjectCard's summary Text style.
                                style: TextStyle(
                                  fontSize: (innerWidth * 0.03).clamp(
                                    12,
                                    double.infinity,
                                  ),
                                  color: Colors.grey,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: hintStyle,
                                  hintText: 'Description',
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: _saving ? null : _save,
                                    child: Text(_creating ? 'Create' : 'Save'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400.withValues(alpha: 0.5),
          content: const Text('Add project name'),
        ),
      );
      return; // stay on the edit screen so they can fix it
    }
    final summary = _summaryController.text.trim();
    final project = widget.project;
    if (project == null) {
      _create(name, summary.isNotEmpty ? summary : null);
      return;
    }
    context.read<ProjectBloc>().add(
      EditProject(
        project.id,
        newName: name, // always set — required
        newSummary: summary.isNotEmpty
            ? summary
            : null, // summary stays optional
      ),
    );
    Navigator.pop(context);
  }

  /// Saves a new project, then closes onto its card in the carousel, the same
  /// way an edit closes onto the card it edited.
  ///
  /// That card only exists once the project comes back from the database, so
  /// this waits for it first. It's usually instant: Firestore shows a write
  /// locally before the server has confirmed it.
  Future<void> _create(String name, String? summary) async {
    final bloc = context.read<ProjectBloc>();
    final id = bloc.newProjectId();
    setState(() => _saving = true);

    // Listen before adding, so the state that brings the project can't be
    // missed. Gives up after 3 seconds, or on an error.
    final arrived = bloc.stream
        .map<bool?>((state) {
          if (state is ProjectsLoaded) {
            return state.projects.any((p) => p.id == id) ? true : null;
          }
          return state is ProjectsError ? false : null;
        })
        .firstWhere((found) => found != null, orElse: () => false)
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
    bloc.add(AddProject(id, name, summary: summary));

    final found = await arrived == true;
    if (!mounted) return;
    if (found) widget.onCreated?.call(id);
    // Without the card (an error, or a very slow save) the tag stays the add
    // button's, so the editor shrinks back into it as before.
    setState(() => _createdId = found ? id : null);
    // Close on the next frame, once the carousel shows the card centred and
    // this Hero carries its tag: that's when the flight picks its target.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }
}
