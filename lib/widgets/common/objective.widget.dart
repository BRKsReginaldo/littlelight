import 'dart:math';

import 'package:bungie_api/models/destiny_objective_definition.dart';
import 'package:bungie_api/models/destiny_objective_progress.dart';
import 'package:flutter/material.dart';
import 'package:little_light/utils/destiny_data.dart';

class ObjectiveWidget extends StatelessWidget {
  final DestinyObjectiveDefinition definition;
  final Color color;
  final bool forceComplete;

  final DestinyObjectiveProgress objective;

  final String placeholder;
  final bool parentCompleted;

  const ObjectiveWidget(
      {Key key,
      this.definition,
      this.color,
      this.parentCompleted,
      this.objective,
      this.forceComplete = false,
      this.placeholder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(4),
        child: Row(children: [
          buildCheck(context),
          Expanded(
            child: buildBar(context),
          )
        ]));
  }

  Widget buildCheck(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: 1, color: this.color ?? Colors.grey.shade300)),
        width: 22,
        height: 22,
        padding: EdgeInsets.all(2),
        child: buildCheckFill(context));
  }

  buildCheckFill(BuildContext context) {
    if (!isComplete) return null;
    return Container(color: barColor);
  }

  bool get isComplete{
    return objective?.complete == true || forceComplete;
  }

  buildBar(BuildContext context) {
    if (definition == null) return Container();
    if ((definition?.completionValue ?? 0) <= 1) {
      return Container(
          padding: EdgeInsets.only(left: 8), child: buildTitle(context));
    }
    return Container(
        margin: EdgeInsets.only(left: 4),
        height: 22,
        decoration: isComplete ? null : BoxDecoration(
            border: Border.all(
                width: 1, color: this.color ?? Colors.grey.shade300)),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: buildProgressBar(context),
            ),
            Positioned.fill(
                left: 4,
                right: 4,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: buildTitle(context)),
                      buildCount(context)
                    ]))
          ],
        ));
  }

  buildTitle(BuildContext context) {
    String title = definition?.progressDescription ?? "";
    if (title.length == 0) {
      title = placeholder ?? "";
    }

    return Container(
        child: Text(title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: this.color ?? Colors.grey.shade300)));
  }

  buildCount(BuildContext context) {
    int progress = objective?.progress ?? 0;
    int total = definition.completionValue ?? 0;
    if (total <= 1) return Container();
    if (!definition.allowOvercompletion) {
      progress = min(total, progress);
    }

    if(forceComplete){
      progress = total;
    }

    return Text("$progress/$total",
        style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: this.color ?? Colors.grey.shade300));
  }

  buildProgressBar(BuildContext context) {
    int progress = objective?.progress ?? 0;
    int total = definition.completionValue ?? 0;
    Color color = Color.lerp(barColor, Colors.black, .1);
    if(isComplete) return Container();
    return Container(
        margin: EdgeInsets.all(2),
        color: Colors.blueGrey.shade800,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: min(progress / total, 1),
          child: Container(color: color),
        ));
  }

  Color get barColor{
    if(parentCompleted == true){
      return color;
    }
    return DestinyData.objectiveProgress;
  }
}
