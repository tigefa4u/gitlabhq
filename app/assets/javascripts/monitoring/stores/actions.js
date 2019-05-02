import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';
import { s__, __ } from '../../locale';

const MAX_REQUESTS = 3;

function backOffRequest(makeRequestCallback) {
  let requestCounter = 0;
  return backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.NO_CONTENT) {
          requestCounter += 1;
          if (requestCounter < MAX_REQUESTS) {
            next();
          } else {
            stop(new Error(__('Failed to connect to the prometheus server')));
          }
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  });
}

export const setMetricsEndpoint = ({ commit }, metricsEndpoint) => {
  commit(types.SET_METRICS_ENDPOINT, metricsEndpoint);
};

export const setDeploymentsEndpoint = ({ commit }, deploymentsEndpoint) => {
  commit(types.SET_DEPLOYMENTS_ENDPOINT, deploymentsEndpoint);
};

export const setEnvironmentsEndpoint = ({ commit }, environmentsEndpoint ) => {
  commit(types.SET_ENVIRONMENTS_ENDPOINT, environmentsEndpoint);
};

export const requestMetricsData = () => ({ commit }) => commit(types.REQUEST_METRICS_DATA);
export const receiveMetricsDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_METRICS_DATA_SUCCESS, data);
export const receiveMetricsDataFailure = ({ commit }, error) =>
  commit(types.RECEIVE_METRICS_DATA_FAILURE, error);

export const fetchMetricsData = ({ state, dispatch }, params) => {
  dispatch('requestMetricsData');

  return backOffRequest(() => axios.get(state.metricsEndpoint, { params }))
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.data || !response.success) {
        dispatch('receiveMetricsDataFailure', null);
        createFlash(s__('Metrics|Unexpected metrics data response from prometheus endpoint'));
      }
      dispatch('receiveMetricsDataSuccess', response.data);
    })
    .catch(error => {
      dispatch('receiveMetricsDataFailure', error);
      createFlash(s__('Metrics|There was an error while retrieving metrics'));
    });
};

export const fetchDeploymentsData = ({ state }) => {
  if (!state.deploymentEndpoint) {
    return Promise.resolve([]);
  }
  return backOffRequest(() => axios.get(state.deploymentEndpoint))
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.deployments) {
        createFlash(
          s__('Metrics|Unexpected deployment data response from prometheus endpoint'),
        );
      }
      return response.deployments;
    })
    .catch(() => {
      createFlash(s__('Metrics|There was an error getting deployment information.'));
    });
};

export const fetchEnvironmentsData = ({ state }) => {
  return axios
    .get(state.environmentsEndpoint)
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.environments) {
        createFlash(
          s__('Metrics|There was an error fetching the environments data, please try again'),
        );
      }
      return response.environments;
    })
    .catch(() => {
      createFlash(s__('Metrics|There was an error getting environments information.'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
