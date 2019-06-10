import MockAdapter from 'axios-mock-adapter';
import statusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import * as issuesActions from '~/issues/stores/modules/issues_list/actions';
import * as types from '~/issues/stores/modules/issues_list/mutation_types';
import testAction from '../../../../helpers/vuex_action_helper';
import { issuesResponseData } from '../../../mock_data';
import { setWindowLocation } from '../../../../helpers/url_util_helper';

describe('Issues List Actions', () => {
  it('Should set filter value', done => {
    const issueFilter = 'hello=world';

    testAction(
      issuesActions.setFilters,
      issueFilter,
      {},
      [{ type: types.SET_FILTERS, payload: issueFilter }],
      [],
      done,
    );
  });

  it('Should set loading state', done => {
    const loadingState = 'loading';

    testAction(
      issuesActions.setLoadingState,
      loadingState,
      {},
      [{ type: types.SET_LOADING_STATE, payload: loadingState }],
      [],
      done,
    );
  });

  it('Should set bulk update state', done => {
    const bulkUpdateState = 'updating';

    testAction(
      issuesActions.setBulkUpdateState,
      bulkUpdateState,
      {},
      [{ type: types.SET_BULK_UPDATE_STATE, payload: bulkUpdateState }],
      [],
      done,
    );
  });

  it('Should set current page', done => {
    const currentPage = 1;

    testAction(
      issuesActions.setCurrentPage,
      currentPage,
      {},
      [{ type: types.SET_CURRENT_PAGE, payload: currentPage }],
      [],
      done,
    );
  });

  it('Should set total Items', done => {
    const totalItems = 200;

    testAction(
      issuesActions.setTotalItems,
      totalItems,
      {},
      [{ type: types.SET_TOTAL_ITEMS, payload: totalItems }],
      [],
      done,
    );
  });

  it('should fetch issues', done => {
    const totalIssues = 1000;
    const currentPage = 1;
    const issuesEndpoint = '/issues';
    const appliedFilters = 'scope=all&utf8=%E2%9C%93&state=opened&page=2';
    const mock = new MockAdapter(axios);
    const { search } = window.location;

    mock.onGet(issuesEndpoint).reply(statusCodes.OK, JSON.stringify({ ...issuesResponseData }), {
      'x-total': totalIssues,
      'x-page': currentPage,
    });

    setWindowLocation({
      search: `?${appliedFilters}`,
    });

    testAction(
      issuesActions.fetchIssues,
      issuesEndpoint,
      { appliedFilters },
      [{ type: types.SET_ISSUES_DATA, payload: { ...issuesResponseData } }],
      [
        { type: 'setLoadingState', payload: true },
        { type: 'setTotalItems', payload: totalIssues },
        { type: 'setCurrentPage', payload: currentPage },
        { type: 'setLoadingState', payload: false },
      ],
      () => {
        mock.restore();
        window.location.search = search;
        done();
      },
    );
  });
});
