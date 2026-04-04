import type { UserConfig } from "@commitlint/types";
import { RuleConfigSeverity } from "@commitlint/types";

const Configuration: UserConfig = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    'scope-enum': [
      2,
      'always',
      [
        'plugins.development',
        'plugins.reporting',
      ]
    ],
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'perf',
        'docs',
        'style',
        'chore',
        'refactor',
        'test',
        'build',
        'ci',
        'security',
        'release',
      ],
    ],
  },
  defaultIgnores: false,
  ignores: [(commit) => commit.startsWith('Merge pull request')],
  prompt: {
    settings: {
      enableMultipleScopes: true,
    },
  },
};

export default Configuration;
