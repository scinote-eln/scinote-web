import { FlatCompat } from '@eslint/eslintrc';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import globals from 'globals';
import { defineConfig, globalIgnores } from 'eslint/config';

// eslint-disable-next-line no-underscore-dangle
const __filename = fileURLToPath(import.meta.url);
// eslint-disable-next-line no-underscore-dangle
const __dirname = path.dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname
});

export default defineConfig([
  globalIgnores(['node_modules', './app/assets/builds/**', './public/']),
  {
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es6,
        jquery: true,
        _: true
      }
    }
  },
  // Migrate extends and plugins using FlatCompat
  ...compat.extends('airbnb', 'plugin:vue/base'),
  {
    rules: {
      'import/extensions': 'off',
      'import/no-unresolved': 'off',
      'spaced-comment': [
        'error',
        'always',
        {
          markers: ['=']
        }
      ],
      'lines-around-comment': [
        'warn',
        {
          beforeLineComment: false
        }
      ],
      'max-len': [
        'error',
        {
          code: 180
        }
      ],
      'vue/max-len': [
        'error',
        {
          code: 180,
          template: 240,
          tabWidth: 2
        }
      ],
      'comma-dangle': ['error', 'never']
    }
  }
]);
