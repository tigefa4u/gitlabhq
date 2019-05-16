/* eslint-disable import/prefer-default-export */

/**
 * Implements Async Action Creator pattern from Redux for Vuex.
 *
 * @param asyncRequest callback function which accepts the same paramters as a Vuex action and returns a Promise
 * @param requestMutation Vuex mutation to be committed before making the async request
 * @param receiveMutation Vuex mutation to be committed after the async request succeeds
 * @param receiveErrorMutation Vuex mutation to be committed after the async request failed
 * @returns {function(*=, *=): *} created Vuex action
 *
 * @see https://redux.js.org/advanced/async-actions#async-action-creators
 */
export const createAsyncAction = ({
  asyncRequest,
  requestMutation,
  receiveMutation,
  receiveErrorMutation,
}) => {
  if (!requestMutation || !receiveMutation || !receiveErrorMutation) {
    throw new Error(
      'The requestMutation, receiveMutation, and receiveErrorMutation parameters are required!',
    );
  }

  return (context, payload) => {
    const { commit } = context;

    if (payload) {
      commit(requestMutation, { payload });
    } else {
      commit(requestMutation);
    }

    return (payload ? asyncRequest(context, payload) : asyncRequest(context))
      .then(result => {
        commit(receiveMutation, payload ? { payload, result } : { result });
        return result;
      })
      .catch(error => {
        commit(receiveErrorMutation, payload ? { payload, error } : { error });
        throw error;
      });
  };
};
