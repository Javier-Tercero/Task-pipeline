import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';


class EditProjectScreen extends StatefulWidget {
  final Project project;
  final double cardWidth;
  final double cardHeight;
  const EditProjectScreen({super.key, required this.project, required this.cardWidth, required this.cardHeight});
  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late final _nameController = TextEditingController(text: widget.project.name);
  late final _summaryController = TextEditingController(text: widget.project.summary);
  late final double cardWidth = widget.cardWidth;
  late final double cardHeight = widget.cardHeight;
  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = cardHeight * 0.1;
    final innerWidth = cardWidth - padding;

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
              tag: widget.project.id, // MUST match the card's tag
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
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                // Matches ProjectCard's name Text style, so the
                                // field doesn't look visually different from
                                // how the name reads on the card itself.
                                style: TextStyle(
                                  fontSize: (innerWidth * 0.07).clamp(14, double.infinity),fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600.withValues(alpha: 0.5),
                                  ),
                                  hintText: 'Project name',
                                ),
                              ),
                              TextField(
                                controller: _summaryController,
                                maxLines: null,
                                textAlign: TextAlign.justify,
                                // Matches ProjectCard's summary Text style.
                                style: TextStyle(
                                  fontSize: (innerWidth * 0.03).clamp(12, double.infinity), color: Colors.grey),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600.withValues(alpha: 0.5),
                                  ),
                                  hintText: 'Project summary',
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: _save,
                                    child: const Text('Save'),
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
    context.read<ProjectBloc>().add(
      EditProject(
        widget.project.id,
        newName: name, // always set — required
        newSummary: summary.isNotEmpty ? summary : null, // summary stays optional
      ),
    );
    Navigator.pop(context);
  }
}
