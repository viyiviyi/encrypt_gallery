import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future? _init;

Future initHive() {
  if (_init != null) return _init!;
  _init = Hive.initFlutter('encrypt_gallery')
      .then((value) => Hive.registerAdapter(ImageDirAdapter()));
  return _init!;
}
