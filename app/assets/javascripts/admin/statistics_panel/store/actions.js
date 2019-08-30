import Api from '~/api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export const requestStatistics = ({ commit }) => commit(types.REQUEST_STATISTICS);

export const fetchStatistics = ({ dispatch }) => {
  dispatch('requestStatistics');

  Api.adminStatistics()
    .then(({ data }) => {
      dispatch('receiveStatisticsSuccess', convertObjectPropsToCamelCase(data, { deep: true }));
    })
    .catch(() => dispatch('receiveStatisticsError'));
};

export const receiveStatisticsSuccess = ({ commit }, statistics) =>
  commit(types.RECEIVE_STATISTICS_SUCCESS, statistics);
export const receiveStatisticsError = ({ commit }) => commit(types.RECEIVE_STATISTICS_ERROR);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
