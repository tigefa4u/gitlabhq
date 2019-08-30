import Api from '~/api';
import { s__ } from '~/locale';
import createFlash from '~/flash';
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

export const receiveStatisticsError = ({ commit }) => {
  commit(types.RECEIVE_STATISTICS_ERROR);
  createFlash(s__('AdminDashboard|Error loading the statistics. Please try again'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
