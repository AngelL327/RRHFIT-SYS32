import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final String initialQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  // Optional: provide columns for sorting. If provided, the widget will
  // show a sort modal and return the selected column key via onSortSelected.
  final VoidCallback? onFilterPressed;
  final Map<String, String>? sortColumns;
  final String? currentSortColumn;
  final bool? currentSortAsc;
  final ValueChanged<String?>? onSortSelected;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Buscar',
    this.initialQuery = '',
    required this.onChanged,
    this.onClear,
    this.onFilterPressed,
    this.sortColumns,
    this.currentSortColumn,
    this.currentSortAsc,
    this.onSortSelected,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // initialize controller eagerly to avoid timing issues where initState
  // might attempt to add a listener to an uninitialized variable in JS builds.
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ensure initial text is set and then add the listener
    _controller.text = widget.initialQuery;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => widget.onChanged(_controller.text.trim());

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, minWidth: 200),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          widget.onClear?.call();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
        if (widget.onFilterPressed != null || widget.sortColumns != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () async {
              // priority: call provided onFilterPressed if present
              if (widget.onFilterPressed != null) {
                widget.onFilterPressed!();
                return;
              }

              // otherwise, if sortColumns provided, show modal here and
              // report the selected key via onSortSelected
              if (widget.sortColumns == null) return;

              final choice = await showModalBottomSheet<String?>(
                context: context,
                builder: (ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(title: Text('Ordenar por')),
                        ...widget.sortColumns!.keys.map((label) {
                          final key = widget.sortColumns![label]!;
                          final isSelected = widget.currentSortColumn == key;
                          return ListTile(
                            title: Text(label),
                            trailing: isSelected
                                ? Icon(widget.currentSortAsc == true ? Icons.arrow_upward : Icons.arrow_downward)
                                : null,
                            onTap: () => Navigator.of(ctx).pop(key),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.clear),
                          title: const Text('Limpiar orden'),
                          onTap: () => Navigator.of(ctx).pop(''),
                        ),
                      ],
                    ),
                  );
                },
              );

              // normalize: '' means clear -> return null
              if (widget.onSortSelected != null) {
                if (choice == null) return;
                widget.onSortSelected!(choice.isEmpty ? null : choice);
              }
            },
          ),
        ],
      ],
    );
  }
}