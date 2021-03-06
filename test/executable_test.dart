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

@TestOn('vm')

import 'dart:io';

import 'package:test/test.dart';

const String projectWithMissingDeps = 'test_fixtures/missing';
const String projectWithOverPromotedDeps = 'test_fixtures/over_promoted';
const String projectWithUnderPromotedDeps = 'test_fixtures/under_promoted';
const String projectWithUnusedDeps = 'test_fixtures/unused';
const String projectWithAnalyzer = 'test_fixtures/analyzer';
const String projectWithNoProblems = 'test_fixtures/valid';

ProcessResult checkProject(String projectPath, {List<String> ignoredPackages = const []}) {
  Process.runSync('pub', ['get'], workingDirectory: projectPath);

  final args = ['run', 'dependency_validator'];

  if (ignoredPackages.isNotEmpty) {
    args..add('--ignore')..add(ignoredPackages.join(','));
  }

  final result = Process.runSync('pub', args, workingDirectory: projectPath);
  return result;
}

void main() {
  group('dependency_validator', () {
    test('fails when there are packages missing from the pubspec', () {
      final result = checkProject(projectWithMissingDeps);

      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('These packages are used in lib/ but are not dependencies:'));
      expect(result.stderr, contains('yaml'));
    });

    test('fails when there are over promoted packages', () {
      final result = checkProject(projectWithOverPromotedDeps);

      expect(result.exitCode, 1);
      expect(result.stderr,
          contains('These packages are only used outside lib/ and should be downgraded to dev_dependencies:'));
      expect(result.stderr, contains('path'));
    });

    test('fails when there are under promoted packages', () {
      final result = checkProject(projectWithUnderPromotedDeps);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('These packages are used in lib/ and should be promoted to actual dependencies:'));
      expect(result.stderr, contains('logging'));
    });

    test('fails when there are unused packages', () {
      final result = checkProject(projectWithUnusedDeps);

      expect(result.exitCode, 1);
      expect(result.stderr,
          contains('These packages may be unused, or you may be using executables or assets from these packages:'));
      expect(result.stderr, contains('dart_dev'));
    });

    test('warns when the analyzer pacakge is depended on but not used', () {
      final result = checkProject(projectWithAnalyzer, ignoredPackages: ['analyzer']);

      expect(result.exitCode, 0);
      expect(result.stderr, contains('You do not need to depend on `analyzer` to run the Dart analyzer.'));
    });

    test('passes when all dependencies are used and valid', () {
      final result = checkProject(projectWithNoProblems);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No infractions found, valid is good to go!'));
    });

    test('passes when there are unused packages, but the unused packages are ignored', () {
      final result = checkProject(projectWithUnusedDeps, ignoredPackages: ['dart_dev']);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No infractions found, unused is good to go!'));
    });

    test('passes when there are missing packages, but the missing packages are ignored', () {
      final result = checkProject(projectWithMissingDeps, ignoredPackages: ['yaml']);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No infractions found, missing is good to go!'));
    });
  });
}
