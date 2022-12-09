import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/generic.dart';
import '../../util/preferences.dart';
import '../base/period_dropdown.dart';
import '../entity/entity_display.dart';

class PeriodSelector<T extends Entity> extends StatefulWidget {
  final DisplayType displayType;
  final PagedRequest<T> request;
  final EntityWidgetBuilder<T> detailWidgetBuilder;
  final EntityAndItemsWidgetBuilder<T> subtitleWidgetBuilder;

  const PeriodSelector({
    super.key,
    this.displayType = DisplayType.list,
    required this.request,
    required this.detailWidgetBuilder,
    required this.subtitleWidgetBuilder,
  });

  @override
  State<StatefulWidget> createState() => _PeriodSelectorState<T>();
}

class _PeriodSelectorState<T extends Entity> extends State<PeriodSelector<T>> {
  late DisplayType _displayType;

  final _entityDisplayComponentKey = GlobalKey<EntityDisplayState>();
  late StreamSubscription _periodChangeSubscription;

  @override
  void initState() {
    super.initState();

    _displayType = widget.displayType;

    _periodChangeSubscription = Preferences.period.changes.listen((value) {
      if (mounted) {
        setState(() {
          _entityDisplayComponentKey.currentState?.getInitialItems();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IntrinsicWidth(
                    child: DefaultTabController(
                      length: 2,
                      initialIndex: _displayType.index,
                      child: TabBar(
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.transparent,
                          tabs: const [Icon(Icons.list), Icon(Icons.grid_view)],
                          onTap: (index) {
                            setState(() {
                              _displayType = DisplayType.values[index];
                            });
                          }),
                    ),
                  ),
                  const PeriodDropdownButton(),
                ],
              ),
            ),
          ),
          Expanded(
            child: EntityDisplay<T>(
              key: _entityDisplayComponentKey,
              displayType: _displayType,
              request: widget.request,
              detailWidgetBuilder: widget.detailWidgetBuilder,
              subtitleWidgetBuilder: widget.subtitleWidgetBuilder,
            ),
          ),
        ],
      );

  @override
  void dispose() {
    _periodChangeSubscription.cancel();
    super.dispose();
  }
}
