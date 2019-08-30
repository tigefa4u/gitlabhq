import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.REQUEST_STATISTICS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_STATISTICS_SUCCESS](state, data) {
    state.isLoading = false;
    state.error = null;

    Vue.set(state, 'statistics', data);
  },
  [types.RECEIVE_STATISTICS_ERROR](state, error) {
    state.isLoading = false;
    state.error = error;
  },
};
