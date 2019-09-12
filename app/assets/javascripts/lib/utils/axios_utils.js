import axios from 'axios';
import csrf from './csrf';

axios.defaults.headers.common[csrf.headerKey] = csrf.token;
// Used by Rails to check if it is a valid XHR request
axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

// Maintain a global counter for active requests
// see: spec/support/wait_for_requests.rb
axios.interceptors.request.use(config => {
  window.activeVueResources = window.activeVueResources || 0;
  window.activeVueResources += 1;
  return config;
});

// Remove the global counter
axios.interceptors.response.use(
  response => {
    window.activeVueResources -= 1;
    return response;
  },
  err => {
    window.activeVueResources -= 1;
    return Promise.reject(err);
  },
);

if (window.gon && window.gon.features && window.gon.features.suppressAjaxNavigationErrors) {
  let isUserNavigating = false;
  window.addEventListener('beforeunload', () => {
    isUserNavigating = true;
  });

  // Ignore AJAX errors caused by requests
  // being cancelled due to browser navigation
  axios.interceptors.response.use(
    response => response,
    err => {
      if (isUserNavigating && err.code === 'ECONNABORTED') {
        // If the user is navigating away from the current page,
        // prevent .catch() handlers from being called by
        // returning a Promise that never resolves
        return new Promise(() => {});
      }

      // The error is not related to browser navigation,
      // so propagate the error
      return Promise.reject(err);
    },
  );
}

export default axios;

/**
 * @return The adapter that axios uses for dispatching requests. This may be overwritten in tests.
 *
 * @see https://github.com/axios/axios/tree/master/lib/adapters
 * @see https://github.com/ctimmerm/axios-mock-adapter/blob/v1.12.0/src/index.js#L39
 */
export const getDefaultAdapter = () => axios.defaults.adapter;
