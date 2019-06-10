import { tokenKeys } from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import { urlParamsToObject } from '~/lib/utils/common_utils';

const filterTokenKeys = tokenKeys.map(token => {
  const { key, param } = token;
  const paramValue = param ? `_${param.replace('[]', '')}` : '';

  return `${key}${paramValue}`;
});

export const hasFilters = state => {
  if (!state.filters) {
    return false;
  }

  const currenFilters = Object.keys(urlParamsToObject(state.filters));

  return currenFilters.reduce((acc, val) => {
    if (!acc) {
      return filterTokenKeys.includes(val);
    }
    return acc;
  }, false);
};
export const appliedFilters = state => state.filters;
export const currentPage = state => state.currentPage;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
