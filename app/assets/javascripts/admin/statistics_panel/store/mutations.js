import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.REQUEST_STATISTICS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_STATISTICS_SUCCESS](state, data) {
    state.isLoading = false;
    state.hasError = false;

    Vue.set(state, 'statistics', data);
  },
  [types.RECEIVE_STATISTICS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
};
