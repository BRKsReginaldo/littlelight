import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_item_socket_entry_definition.dart';
import 'package:bungie_api/models/destiny_item_socket_state.dart';
import 'package:bungie_api/models/destiny_socket_category_definition.dart';
import 'package:bungie_api/models/destiny_item_plug_base.dart';
import 'package:flutter/material.dart';
import 'package:little_light/services/manifest/manifest.service.dart';
import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';

class ItemPerksWidget extends StatefulWidget {
  final ManifestService manifest = ManifestService();
  final DestinyInventoryItemDefinition definition;
  final double iconSize;
  final DestinyItemComponent item;
  final bool showUnusedPerks;
  final socketCategoryHash;
  final List<DestinyItemSocketState> itemSockets;
  ItemPerksWidget(
      {Key key,
      this.iconSize = 16,
      this.socketCategoryHash,
      this.showUnusedPerks = false,
      this.definition,
      this.itemSockets,
      this.item})
      : super(key: key);

  @override
  ItemPerksWidgetState createState() {
    return ItemPerksWidgetState();
  }
}

class ItemPerksWidgetState extends State<ItemPerksWidget> {
  List<DestinyItemSocketState> _itemSockets;
  Map<String, List<DestinyItemPlugBase>> _reusablePlugs;
  List<DestinyItemSocketState> get itemSockets=>_itemSockets ?? widget.itemSockets;
  DestinyInventoryItemDefinition get definition => widget.definition;
  DestinySocketCategoryDefinition perksCatDefinition;

  @override
  void initState() {
    super.initState();
    _itemSockets = ProfileService().getItemSockets(widget?.item?.itemInstanceId);
    if(widget.showUnusedPerks){
      _reusablePlugs = ProfileService().getItemReusablePlugs(widget?.item?.itemInstanceId);
    }
    loadPerks();
  }

  loadPerks() async {
    if (definition?.sockets?.socketCategories == null) {
      return;
    }
    perksCatDefinition = await widget.manifest
        .getDefinition<DestinySocketCategoryDefinition>(
            widget.socketCategoryHash);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (perksCatDefinition == null) {
      return Container();
    }
    return buildPerks(context, perksCatDefinition);
  }

  Widget buildPerks(BuildContext context, DestinySocketCategoryDefinition def) {
    var socketCategory = definition.sockets.socketCategories.firstWhere(
        (s) => s.socketCategoryHash == def.hash,
        orElse: () => null);
    List<Widget> columns = [];
    if (socketCategory == null) return Container();
    socketCategory.socketIndexes.forEach((index) {
      columns.add(buildPerkColumn(context, index));
    });
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: columns.toList());
  }

  Widget buildPerkColumn(BuildContext context, int index) {
    if (!widget.showUnusedPerks || itemSockets == null) {
      var hash = itemSockets != null
          ? getEquippedPlugHashBySocketIndex(index)
          : getDefaultPerkBySocketIndex(index);
      return buildPerkIcon(context, hash);
    }

    List<int> hashes = getInstancePlugHashesBySocketIndex(index);
    return Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: hashes.map((h) => buildPerkIcon(context, h)).toList(),
    ));
  }

  Widget buildPerkIcon(BuildContext context, int plugHash) {
    if (plugHash == null) {
      return Container();
    }
    return Container(
      width: widget.iconSize,
      height: widget.iconSize,
      child: ManifestImageWidget<DestinyInventoryItemDefinition>(
        plugHash,
        placeholder: Container(),
      ),
    );
  }

  DestinyItemSocketState getSocketState(int index) {
    if (itemSockets == null) return null;
    return itemSockets[index];
  }

  int getEquippedPlugHashBySocketIndex(int index) {
    var entry = socketEntries[index];
    var state = getSocketState(index);
    if (!(state.isVisible ?? false)) {
      return null;
    }
    if ((state?.plugHash ?? 0) != 0) {
      return state?.plugHash;
    }
    if ((entry.singleInitialItemHash ?? 0) != 0) {
      return entry.singleInitialItemHash;
    }
    return null;
  }

  List<int> getInstancePlugHashesBySocketIndex(int index) {
    var entry = socketEntries[index];
    var state = getSocketState(index);
    var reusable = (_reusablePlugs ?? const {})["$index"];
    if (!(state.isVisible ?? false)) {
      return [];
    }
    if((reusable?.length ?? 0) > 0){
      return reusable.map((r)=>r.plugItemHash).toList();
    }
    if ((state?.plugHash ?? 0) != 0) {
      return [state?.plugHash];
    }
    if ((entry.singleInitialItemHash ?? 0) != 0) {
      return [entry.singleInitialItemHash];
    }
    return null;
  }

  int getDefaultPerkBySocketIndex(int index) {
    var entry = socketEntries[index];
    if ((entry.singleInitialItemHash ?? 0) != 0) {
      return entry.singleInitialItemHash;
    }
    if ((entry.reusablePlugItems?.length ?? 0) != 0) {
      return entry.reusablePlugItems[0].plugItemHash;
    }
    return null;
  }

  List<DestinyItemSocketEntryDefinition> get socketEntries {
    return definition.sockets.socketEntries;
  }
}
