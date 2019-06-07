/**
 * @module
 *
 * This module enables the automatic injection of manual mocks into Jest test suites. Mocks are placed in the `spec/frontend/mocks` directory, mirroring the directory structure of the source modules, and they are automatically registered with Jest. In tests, it suffices to `import` a mocked module and the mock will automatically be injected.
 *
 * - Place mocks for NPM packages, like `jquery`, into `mocks/node/`.
 * - Place mocks for GitLab CE scripts into `mocks/ce/`.
 * - Support for EE-specific mocks is on the way.
 * - Support for virtual mocks is on the way.
 *
 * Mocks must export the same fields as the mocked module. So, if you're mocking a CommonJS package, use `module.exports` instead of the ES6 `export`.
 *
 * Jest kinda does automatic injection if you put mocks in a `__mocks__` directory beside the source file. This has a few drawbacks:
 *
 * - Mocks are spread throughout the codebase.
 * - Jest's auto-injection behaviour inconsistent and doesn't behave exactly as documented.
 * - Sometimes you still have to call jest.mock(), sometimes you don't. This is confusing.
 */

import fs from 'fs';
import path from 'path';

import readdir from 'readdir-enhanced';

const MAX_DEPTH = 20;
const prefixMap = [
  // E.g. the mock ce/foo/bar maps to require path ~/foo/bar
  { mocksRoot: 'ce', requirePrefix: '~' },
  // { mocksRoot: 'ee', requirePrefix: 'ee' }, // We'll deal with EE-specific mocks later
  { mocksRoot: 'node', requirePrefix: '' },
  // { mocksRoot: 'virtual', requirePrefix: '' }, // We'll deal with virtual mocks later
];

const mockFileFilter = stats => stats.isFile() && stats.path.endsWith('.js');

const getMockFiles = root => readdir.sync(root, { deep: MAX_DEPTH, filter: mockFileFilter });

// Function that performs setting a mock. This has to be overridden by the unit test, because
// jest.setMock can't be overwritten across files.
// Use require() because jest.setMock expects the CommonJS exports object
// eslint-disable-next-line import/no-dynamic-require, global-require
const defaultSetMock = (source, mock) => jest.setMock(source, require(mock));

// eslint-disable-next-line import/prefer-default-export
export const setupManualMocks = function setupManualMocks(setMock = defaultSetMock) {
  prefixMap.forEach(({ mocksRoot, requirePrefix }) => {
    const mocksRootAbsolute = path.join(__dirname, mocksRoot);
    if (!fs.existsSync(mocksRootAbsolute)) {
      return;
    }

    getMockFiles(path.join(__dirname, mocksRoot)).forEach(mockPath => {
      const mockPathNoExt = mockPath.substring(0, mockPath.length - path.extname(mockPath).length);
      const sourcePath = path.join(requirePrefix, mockPathNoExt);
      const mockPathRelative = `./${path.join(mocksRoot, mockPathNoExt)}`;

      try {
        setMock(sourcePath, mockPathRelative);
      } catch (e) {
        if (e.message.includes('Could not locate module')) {
          // The corresponding mocked module doesn't exist. Raise a better error.
          // Eventualy, we may support virtual mocks (mocks whose path doesn't directly correspond
          // to a module, like with the `ee_else_ce` prefix).
          throw new Error(
            `A manual mock was defined for module ${sourcePath}, but the module doesn't exist!`,
          );
        }
      }
    });
  });
};
