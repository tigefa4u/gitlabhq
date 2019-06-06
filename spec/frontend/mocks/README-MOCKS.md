Hello! This is where you place module mocks for Jest tests, so we can keep them all in one place.

- Place mocks for NPM packages, like `jquery`, into `node/`.
- Place mocks for GitLab classes and scripts into `gitlab/`.

Make sure to register the mock in `test_setup.js` if you add a new one. Jest will then automatically load the mock whenever you import the mocked package.

Mocks must export the same fields as the mocked module. So, if you're mocking a CommonJS package, use `module.exports` instead of the ES6 `export`.