import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_item_instance_component.dart';
import 'package:flutter/material.dart';
import 'package:little_light/widgets/item_list/items/base/base_inventory_item.widget.dart';

class MediumBaseInventoryItemWidget extends BaseInventoryItemWidget {
  MediumBaseInventoryItemWidget(
      DestinyItemComponent item,
      DestinyInventoryItemDefinition itemDefinition,
      DestinyItemInstanceComponent instanceInfo)
      : super(item, itemDefinition, instanceInfo);

  Widget nameBar(BuildContext context) {
    return Positioned(
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding),
          height: titleFontSize + padding * 2,
          alignment: Alignment.centerLeft,
          decoration: nameBarBoxDecoration(),
          child: nameBarTextField(context),
        ));
  }

  Widget categoryName(BuildContext context) {
    return null;
  }

  Widget itemIcon(BuildContext context) {
    return Positioned(
        top: padding * 3 + titleFontSize,
        left: padding,
        width: iconSize,
        height: iconSize,
        child: borderedIcon(context));
  }

  double get iconSize {
    return 48;
  }

  double get padding {
    return 4;
  }

  double get titleFontSize {
    return 12;
  }
}
