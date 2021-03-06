import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:lan_file_more/common/widget/dialog.dart';
import 'package:lan_file_more/common/widget/no_resize_text.dart';
import 'package:lan_file_more/common/widget/show_modal.dart';
import 'package:lan_file_more/common/widget/text_field.dart';
import 'package:lan_file_more/model/theme_model.dart';
import 'package:lan_file_more/utils/mix_utils.dart';
import 'package:lan_file_more/utils/theme.dart';
import 'package:provider/provider.dart';

import 'file_utils.dart';

Future<void> createRenameModal(
  BuildContext context,
  SelfFileEntity file, {
  @required VoidCallback onExists,
  @required Function(String) onSuccess,
  @required Function(dynamic) onError,
}) async {
  MixUtils.safePop(context);
  ThemeModel themeModel = Provider.of<ThemeModel>(context, listen: false);
  LanFileMoreTheme themeData = themeModel.themeData;
  TextEditingController textEditingController = TextEditingController();

  showCupertinoModal(
    context: context,
    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
    builder: (BuildContext context) {
      return LanDialog(
        fontColor: themeData.itemFontColor,
        bgColor: themeData.dialogBgColor,
        title: NoResizeText('重命名'),
        action: true,
        children: <Widget>[
          LanTextField(
            style: TextStyle(textBaseline: TextBaseline.alphabetic),
            controller: textEditingController,
            placeholder: '${file.filename}',
          ),
          SizedBox(height: 10),
        ],
        onOk: () async {
          String newPath = LanFileUtils.renameNewPath(
              file.entity.path, textEditingController.text);
          if (await File(newPath).exists() ||
              await Directory(newPath).exists()) {
            onExists();
            return;
          }

          await file.entity.rename(newPath).then((value) async {
            onSuccess(textEditingController.text);
            MixUtils.safePop(context);
          }).catchError((err) {
            onError(err);
          });
        },
        onCancel: () {
          MixUtils.safePop(context);
        },
      );
    },
  );
}
