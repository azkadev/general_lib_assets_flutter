// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps

import "dart:io";

import "package:general_lib/general_lib.dart";

import "package:path/path.dart" as path;
import "package:yaml/yaml.dart";
import "package:yaml_writer/yaml_writer.dart";

// void main(List<String> args) async {
//   Directory directory_assets = Directory(join(Directory.current.path, "lib", "assets"));
//   List<String> paths = [];
//   RegExp replace_from = RegExp(r"/home/galaxeus/Documents/galaxeus/app/general_machine_system_services/library/general_lib_assets_flutter/lib/assets", caseSensitive: false,);
//   await directory_assets.recursive(
//     onData: (fileSystemEntity) {
//       paths.add(fileSystemEntity.path.replaceAll(replace_from, "packages/general_lib_assets_flutter/assets"));
//     },
//   );
//   paths.sort();
//   String messages = """

//   assets:
//     - ${paths.join("\n    - ")}

// """;
//   print(messages);
// }

void main(List<String> args) async {
  await GenerateAssetsFlutter.autoSetAssetsPubspec(
      baseDirectory: Directory.current, isPackages: true);
}

class GenerateAssetsFlutter {
  static List<String> getAssets({
    required String packageName,
    required Directory baseDirectory,
    required bool isPackages,
    bool isFontsOnly = false,
  }) {
    if (packageName.trim().isEmpty) {
      File file =
          File(path.join(baseDirectory.uri.toFilePath(), "pubspec.yaml"));
      Map yaml_code = (loadYaml(file.readAsStringSync(), recover: true) as Map);
      packageName = yaml_code["name"];
    }

    Directory directory = Directory(() {
      if (isPackages) {
        return path.join(baseDirectory.uri.toFilePath(), "lib", "assets");
      }
      return path.join(baseDirectory.uri.toFilePath(), "assets");
    }());

    List<FileSystemEntityChildren> directorys =
        directory.listSync(recursive: true).toTree();
    List<String> datas = [];
    for (FileSystemEntityChildren fileSystemEntityChildren in directorys) {
      if (fileSystemEntityChildren.fileSystemEntityType ==
          FileSystemEntityType.directory) {
      } else {
        if (fileSystemEntityChildren.fileSystemEntityType ==
            FileSystemEntityType.file) {
          bool is_font = false;
          if (RegExp("(.(t|o)tf)", caseSensitive: false).hashData(path.basename(
              fileSystemEntityChildren.fileSystemEntity.uri.toFilePath()))) {
            is_font = true;
          }
          if (isFontsOnly) {
            if (is_font == false) {
              continue;
            }
          } else {
            if (is_font) {
              continue;
            }
          }

          if (isPackages) {
            datas.add("packages/${packageName}/assets/${path.relative(
              fileSystemEntityChildren.fileSystemEntity.path,
              from: directory.uri.toFilePath(),
            )}");
          } else {
            datas.add("assets/${path.relative(
              fileSystemEntityChildren.fileSystemEntity.path,
              from: directory.uri.toFilePath(),
            )}");
          }
        }
      }
    }
    return datas.toSet().toList();
  }

  static Future<Map> autoSetAssetsPubspec({
    required Directory baseDirectory,
    required bool isPackages,
  }) async {
    File file = File(path.join(baseDirectory.uri.toFilePath(), "pubspec.yaml"));
    Map yaml_code = (loadYaml(file.readAsStringSync(), recover: true) as Map);
    Map yaml_code_edit = yaml_code.clone();
    String packageName = yaml_code["name"];

    List<String> asset_datas = getAssets(
      packageName: packageName,
      baseDirectory: baseDirectory,
      isPackages: isPackages,
      isFontsOnly: false,
    );

    getAssets(
      packageName: packageName,
      baseDirectory: baseDirectory,
      isPackages: isPackages,
      isFontsOnly: true,
    );

    if (yaml_code_edit["flutter"] is Map == false) {
      yaml_code_edit["flutter"] = {};
    }

    if (yaml_code_edit["flutter"]["assets"] is List == false) {
      yaml_code_edit["flutter"]["assets"] = [];
    }

    List assets = yaml_code_edit["flutter"]["assets"];

    for (var element in asset_datas) {
      if (!assets.contains(element)) {
        assets.add(element);
      }
    }

    assets = assets.toSet().toList();
    assets.sort();
    yaml_code_edit["flutter"]["assets"] = assets;
    await file.writeAsString(YamlWriter().write(yaml_code_edit));
    return {"@type": "ok"};
  }
}
