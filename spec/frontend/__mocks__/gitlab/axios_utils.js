/* global jest */

const axios = jest.requireActual('~/lib/utils/axios_utils').default;

// Fail tests for unmocked requests
axios.defaults.adapter = config => {
  const message =
    `Unexpected unmocked request: ${JSON.stringify(config, null, 2)}\n` +
    'Consider using the `axios-mock-adapter` in tests.';
  const error = new Error(message);
  error.config = config;
  throw error;
};

export default axios;
