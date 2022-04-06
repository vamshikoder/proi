import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ProviderScope(child: ProiApp()));
}

// ! -------- Models --------
@immutable
class Node {
  final String uniqueKey = DateTime.now().toString();
  final Offset offset;
  Node({required this.offset});

  Node copyWith({Offset? offset}) {
    return Node(offset: offset!);
  }
}

// ! -------- Providers --------

class NodesNotifier extends StateNotifier<List<Node>> {
  NodesNotifier() : super([]);

  // take the node Id [which is time stamp of a node that is captured during each node creation] and also offset provided by
  void updateNodePosition(Node selectedNode,
      {Offset? offset, double? dx = 0, double? dy = 0}) {
    Offset newOffset;
    if (offset != null) {
      newOffset = offset;
    } else {
      newOffset = Offset(dx!, dy!);
    }
    state = [
      for (final node in state)
        if (node != selectedNode) node else node.copyWith(offset: newOffset)
    ];
  }

  void addNode(Offset offset) {
    state = [...state, Node(offset: offset)];
  }

  void deleteNode(Node node) {
    state = [
      for (final tempNode in state)
        if (tempNode != node) tempNode
    ];
  }
}

final nodesProvider = StateNotifierProvider<NodesNotifier, List<Node>>((ref) {
  return NodesNotifier();
});

final isNodeSearchVisibleProvider = StateProvider<bool>((ref) {
  return false;
});

final sandboxScaleProvider = StateProvider<double>(((ref) {
  return 100;
}));

final sandboxPositionProvider = StateProvider<Offset>(((ref) {
  return const Offset(-2000, -2000);
}));

// ! -------- UI --------

class ProiApp extends StatelessWidget {
  const ProiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(70, 255, 99, 1),
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SandBox(),
    );
  }
}

class NodeWidget extends ConsumerWidget {
  const NodeWidget({
    Key? key,
    required this.node,
  }) : super(key: key);
  final Node node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: node.offset.dx,
      top: node.offset.dy,
      child: GestureDetector(
        onDoubleTap: () => ref.read(nodesProvider.notifier).deleteNode(node),
        onPanUpdate: (details) => ref
            .read(nodesProvider.notifier)
            .updateNodePosition(node, offset: details.globalPosition),
        child: Container(
          height: 100,
          width: 100,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            color: Colors.white,
            boxShadow: [BoxShadow()],
          ),
        ),
      ),
    );
  }
}

class SandBox extends ConsumerWidget {
  const SandBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Node> nodes = ref.watch(nodesProvider);
    Offset sandboxPosition = ref.watch(sandboxPositionProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: IconButton(
        onPressed: () {
          ref.read(nodesProvider.notifier).addNode(const Offset(100, 0));
        },
        color: Theme.of(context).primaryColor,
        icon: const Icon(
          Icons.add,
        ),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            // maxScale: 2.0,
            // minScale: 0.1,

            onInteractionUpdate: (details) {
              final delta = details.focalPointDelta;
              if (delta.dx + sandboxPosition.dx < 2000 &&
                  delta.dx + sandboxPosition.dx > -2000) {
                ref.read(sandboxPositionProvider.notifier).state =
                    ref.read(sandboxPositionProvider.notifier).state +
                        Offset(delta.dx, 0);

                for (final node in nodes) {
                  ref.read(nodesProvider.notifier).updateNodePosition(node,
                      offset: node.offset + Offset(delta.dx, 0));
                }
              }
              // ! nodes aren't move in [dy]
              if (delta.dy + sandboxPosition.dy < 2000 &&
                  delta.dy + sandboxPosition.dy > -2000) {
                ref.read(sandboxPositionProvider.notifier).state =
                    ref.read(sandboxPositionProvider.notifier).state +
                        Offset(0, delta.dy);

                for (final node in nodes) {
                  ref.read(nodesProvider.notifier).updateNodePosition(node,
                      offset: node.offset + Offset(0, delta.dy));
                }
                // nodes.isNotEmpty ? dev.log("${nodes.first.offset}") : null;
              }
            },
            child: Stack(
              // alignment: Alignment.center,
              children: [
                Positioned(
                  left: sandboxPosition.dx,
                  top: sandboxPosition.dy,
                  child: Container(
                    height: 10000,
                    width: 10000,
                    color: Colors.black,
                    child: GridPaper(
                      color: Colors.grey.withOpacity(0.5),
                      interval: 50,
                      // divisions: 1,
                      // subdivisions: 2,
                    ),
                  ),
                ),
                if (nodes.isNotEmpty)
                  ...[for (final node in nodes) NodeWidget(node: node)]
                      .toList(),
              ],
            ),
            // ),
          ),
          const MenuBar(),
        ],
      ),
    );
  }
}

class MenuBar extends StatelessWidget {
  const MenuBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      // color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "project-name.py",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Theme.of(context).primaryColor),
              ),
              IconButton(
                  onPressed: () {},
                  padding: const EdgeInsets.only(left: 16),
                  icon: const Icon(
                    Icons.download_for_offline_rounded,
                    // color: Colors.white,
                  )),
              const Spacer(),
              IconButton(
                  onPressed: () {},
                  padding: const EdgeInsets.only(left: 32),
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    // color: Colors.white,
                  )),
              IconButton(
                  padding: const EdgeInsets.only(left: 32),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.settings_rounded,
                    // color: Colors.white,
                  )),
            ],
          ),
          Text("PROI v0.0.0",
              style: Theme.of(context).textTheme.subtitle2?.copyWith(
                  fontSize: 8, color: Theme.of(context).primaryColor))
        ],
      ),
    );
  }
}
