import rusage from 'getrusage';

const MS_PER_S = 1000;
const IS_DEBUGGING = process.execArgv.join(' ').includes('--inspect-brk');

let testTimeoutMS;

export const setTestTimeout = newTimeoutMS => {
  testTimeoutMS = newTimeoutMS;
  jest.setTimeout(newTimeoutMS);
};

// Allows slow tests to set their own timeout.
// Useful for tests with jQuery, which is very slow in big DOMs.
let temporaryTimeoutMS = null;
export const setTestTimeoutOnce = newTimeoutMS => {
  temporaryTimeoutMS = newTimeoutMS;
};

export const initializeTestTimeout = defaultTimeoutMS => {
  setTestTimeout(defaultTimeoutMS);

  let testStartTimeS;

  // https://github.com/facebook/jest/issues/6947
  beforeEach(() => {
    testStartTimeS = rusage.getcputime();
  });

  afterEach(() => {
    let timeoutMS = testTimeoutMS;
    if (Number.isFinite(temporaryTimeoutMS)) {
      timeoutMS = temporaryTimeoutMS;
      temporaryTimeoutMS = null;
    }

    const elapsedMS = (rusage.getcputime() - testStartTimeS) * MS_PER_S;

    // Disable the timeout error when debugging. It is meaningless because
    // debugging always takes longer than the test timeout.
    if (elapsedMS > timeoutMS && !IS_DEBUGGING) {
      throw new Error(
        `Test took too long (${elapsedMS}ms > ${timeoutMS}ms)!`,
      );
    }
  });
};
