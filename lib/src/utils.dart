// Copyright 2017 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:logging/logging.dart';

final RegExp importExportPackageRegex =
    new RegExp(r'''^(import|export)\s+['"]package:([a-zA-Z_]+)\/.+$''', multiLine: true);

const dependenciesKey = 'dependencies';
const dependencyValidatorPackageName = 'dependency_validator';
const devDependenciesKey = 'dev_dependencies';
const nameKey = 'name';
const transformersKey = 'transformers';

final Logger logger = new Logger('dependency_validator');

String bulletItems(Iterable<String> items) => items.map((l) => '  * $l').join('\n');

Iterable<File> listDartFilesIn(String dirPath) {
  if (!FileSystemEntity.isDirectorySync(dirPath)) return const [];
  final allFiles = new Directory(dirPath)
      .listSync(recursive: true)
      // TODO use .whereType in Dart2
      .where((entity) => entity is File) as Iterable<File>;
  return allFiles.where((entity) => !entity.path.contains('/packages/') && entity.path.endsWith('.dart'));
}

void logDependencyInfractions(String infraction, Iterable<String> dependencies) {
  final sortedDependencies = dependencies.toList()..sort();
  logger.warning([infraction, bulletItems(sortedDependencies), ''].join('\n'));
}
