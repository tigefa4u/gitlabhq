import flash from '~/flash';
import { __ } from '~/locale';
import { getParameterValues } from '~/lib/utils/url_utility';
import _ from 'underscore';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import { ISSUE_STATES } from '../../../constants';
import service from '../../../services/issues_service';
import * as types from './mutation_types';

/**
 * Return a object containg order and sort values
 * for issues filter. This is necessary to maintain
 * URL compatibility for current issues filters while
 * keeping backward compatibility for issues API
 * @param {String} sort
 */
const transformSortFilter = sort => {
  const orderMap = {
    created: 'created_at',
    updated: 'updated_at',
    due_date: 'due_date',
    priority: 'priority',
    milestone: 'milestone',
    popularity: 'popularity',
    label_priority: 'label_priority',
  };

  if (!sort) {
    return null;
  }

  if (sort.lastIndexOf('desc') === -1) {
    return {
      orderBy: orderMap[sort],
      sort: 'asc',
    };
  }

  const splitIndex = sort.lastIndexOf('_');
  const orderValue = sort.slice(0, splitIndex);
  const sortValue = sort.slice(splitIndex + 1);

  return {
    orderBy: orderMap[orderValue],
    sort: sortValue,
  };
};

export const setFilters = ({ commit }, value) => {
  commit(types.SET_FILTERS, value);
};

export const setLoadingState = ({ commit }, value) => {
  commit(types.SET_LOADING_STATE, value);
};

export const setBulkUpdateState = ({ commit }, value) => {
  commit(types.SET_BULK_UPDATE_STATE, value);
};

export const fetchIssues = ({ commit, dispatch, getters }, endpoint) => {
  dispatch('setLoadingState', true);

  // we always update state from the window.location
  // as it may not be avaliable in our store
  const [currentState] = getParameterValues('state');

  // only set state if it does not exist
  const state = !currentState ? ISSUE_STATES.OPENED : null;
  const appliedFilters = urlParamsToObject(getters.appliedFilters);
  const filters = _.omit(appliedFilters, ['label_name', 'sort']);

  // map label parameter to supported API value
  if (appliedFilters.label_name && Array.isArray(appliedFilters.label_name)) {
    filters.labels = appliedFilters.label_name.join(',');
  }

  // transform and apply order_by and sort filters
  if (appliedFilters.sort) {
    const { sort, orderBy } = transformSortFilter(appliedFilters.sort) || {};
    filters.sort = sort;
    filters.order_by = orderBy;
  }

  return service
    .fetchIssues(endpoint, filters, state)
    .then(({ data, headers }) => {
      dispatch('setTotalItems', headers['x-total']);
      dispatch('setCurrentPage', headers['x-page']);
      commit(types.SET_ISSUES_DATA, data);
    })
    .then(() => dispatch('setLoadingState', false))
    .catch(() => flash(__('An error occurred while loading issues')));
};

export const setCurrentPage = ({ commit }, value) => {
  commit(types.SET_CURRENT_PAGE, value);
};

export const setTotalItems = ({ commit }, value) => {
  commit(types.SET_TOTAL_ITEMS, value);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
