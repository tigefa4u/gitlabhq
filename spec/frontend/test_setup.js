import Vue from 'vue';
import * as jqueryMatchers from 'custom-jquery-matchers';
import Translate from '~/vue_shared/translate';
import { initializeTestTimeout } from './helpers/timeout';
import { loadHTMLFixture, setHTMLFixture } from './helpers/fixtures';

process.on('unhandledRejection', global.promiseRejectionHandler);

// Explicitly set mocks
// Use require() because jest.setMock() expects CommonJS exports as a parameter
// Tip: jest.setMock(name, exportObj) is equivalent to jest.mock(name, () => exportObj)
jest.setMock('jquery', require('./mocks/node/jquery'));
jest.setMock('~/lib/utils/axios_utils', require('./mocks/gitlab/axios_utils'));

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runAllTimers();
  }),
);

initializeTestTimeout(500);

Vue.config.devtools = false;
Vue.config.productionTip = false;

Vue.use(Translate);

// workaround for JSDOM not supporting innerText
// see https://github.com/jsdom/jsdom/issues/1245
Object.defineProperty(global.Element.prototype, 'innerText', {
  get() {
    return this.textContent;
  },
  configurable: true, // make it so that it doesn't blow chunks on re-running tests with things like --watch
});

// convenience wrapper for migration from Karma
Object.assign(global, {
  loadFixtures: loadHTMLFixture,
  setFixtures: setHTMLFixture,

  // The following functions fill the fixtures cache in Karma.
  // This is not necessary in Jest because we make no Ajax request.
  loadJSONFixtures() {},
  preloadFixtures() {},
});

// custom-jquery-matchers was written for an old Jest version, we need to make it compatible
Object.entries(jqueryMatchers).forEach(([matcherName, matcherFactory]) => {
  expect.extend({
    [matcherName]: matcherFactory().compare,
  });
});
