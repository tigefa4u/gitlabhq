import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { GlPagination } from '@gitlab/ui';
import IssuesApp from '~/issues/components/issues_app.vue';
import IssueComponent from '~/issues/components/issue.vue';
import IssuesEmptyState from '~/issues/components/empty_state.vue';
import IssuesLoadingState from '~/issues/components/loading_state.vue';
import * as getters from '~/issues/stores/modules/issues_list/getters';
import { issuesResponseData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Issues app', () => {
  let store;
  let state;
  let actions;
  let wrapper;
  let mockedProjectSelect;
  let mockedIssuableIndex;
  let mockedFilteredSearch;

  const factory = (props = {}, options = {}) => {
    const propsData = {
      endpoint: TEST_HOST,
      createPath: '/',
      projectSelect: mockedProjectSelect,
      canBulkUpdate: true,
      issuableIndex: mockedIssuableIndex,
      filteredSearch: mockedFilteredSearch,
      emptyStateSvgPath: '/',
      emptyStateLoadingDisabledSvgPath: '/',
      ...props,
    };

    store = new Vuex.Store({
      modules: {
        issuesList: {
          namespaced: true,
          state,
          actions,
          getters,
        },
      },
    });

    wrapper = mount(localVue.extend(IssuesApp), {
      localVue,
      store,
      sync: false,
      propsData,
      ...options,
    });
  };

  beforeEach(() => {
    state = {
      loading: false,
      filters: '',
      issues: null,
      isBulkUpdating: false,
      currentPage: 1,
      totalItems: 1,
    };

    actions = {
      fetchIssues: jest.fn(),
      setCurrentPage: jest.fn(),
    };

    mockedFilteredSearch = {
      updateObject: jest.fn(),
      clearSearch: jest.fn(),
      loadSearchParamsFromURL: jest.fn(),
    };

    mockedIssuableIndex = {
      bulkUpdateSidebar: {
        bindEvents: jest.fn(),
        initDomElements: jest.fn(),
      },
    };

    mockedProjectSelect = jest.fn();

    document.body.innerHTML = '';
    window.gon = {};
  });

  it('fetches issues when mounted', () => {
    factory();
    expect(actions.fetchIssues).toHaveBeenCalled();
    expect(actions.fetchIssues.mock.calls[0]).toContain(TEST_HOST);
  });

  it('renders loading state when fetching issues', () => {
    state.loading = true;
    factory();

    const loadingState = wrapper.find(IssuesLoadingState);

    expect(loadingState.exists()).toBe(true);
    expect(loadingState.classes()).toContain('js-issues-loading');
  });

  it('renders empty state if no issues', () => {
    state.issues = [];
    factory();

    const emptyState = wrapper.find(IssuesEmptyState);

    expect(emptyState.exists()).toBe(true);
  });

  it('renders issues list when issues are present', () => {
    state.issues = issuesResponseData.slice(0, 10);
    factory();

    const issueComponent = wrapper.find(IssueComponent);

    expect(issueComponent.exists()).toBe(true);
    expect(wrapper.findAll(IssueComponent).length).toEqual(10);
  });

  it('renders issues list pagination', () => {
    state.issues = issuesResponseData;
    factory();
    expect(wrapper.find(GlPagination).exists()).toBe(true);
  });

  it('initializes issues page events', () => {
    state.issues = issuesResponseData;
    factory();

    wrapper.setData({ isInProjectPage: true });
    wrapper.vm.setupExternalEvents();

    expect(mockedIssuableIndex.bulkUpdateSidebar.bindEvents).toHaveBeenCalled();
    expect(mockedIssuableIndex.bulkUpdateSidebar.initDomElements).toHaveBeenCalled();
  });

  it('initializes project selector in issues dashboard page', () => {
    state.issues = issuesResponseData;
    factory(
      {},
      {
        data() {
          return {
            ISSUES_PER_PAGE: 20,
            isInGroupsPage: false,
            isInProjectPage: false,
            isInDashboardPage: true,
            isLoadingDisabled: false,
          };
        },
      },
    );

    expect(mockedProjectSelect).toHaveBeenCalled();
  });

  it('initializes project selector in groups issues page', () => {
    state.issues = issuesResponseData;
    factory(
      {},
      {
        data() {
          return {
            ISSUES_PER_PAGE: 20,
            isInGroupsPage: true,
            isInProjectPage: false,
            isInDashboardPage: false,
            isLoadingDisabled: false,
          };
        },
      },
    );

    expect(mockedProjectSelect).toHaveBeenCalled();
  });

  describe('Issues filters', () => {
    it('updates filters when the current page changes', () => {
      const page = 2;

      document.body.innerHTML = '<div id="content-body"></div>';
      state.issues = issuesResponseData;
      factory();

      wrapper.vm.updatePage(page);

      expect(mockedFilteredSearch.updateObject).toHaveBeenCalled();
      expect(actions.setCurrentPage.mock.calls[0]).toContain(page);
    });

    it('update filters when a label is clicked', () => {
      const label = 'Hello';
      state.issues = issuesResponseData;
      factory();

      wrapper.vm.applyLabelFilter(label);

      expect(mockedFilteredSearch.clearSearch).toHaveBeenCalled();
      expect(mockedFilteredSearch.updateObject).toHaveBeenCalled();
      expect(mockedFilteredSearch.loadSearchParamsFromURL).toHaveBeenCalled();
    });

    it('disables loading in issues dashboard page if assignee filter is incorrect', () => {
      window.gon = {
        current_username: 'not_root',
      };

      state.issues = [];
      state.filters = '?assignee_username=root';
      factory(
        {},
        {
          data() {
            return {
              ISSUES_PER_PAGE: 20,
              isInGroupsPage: false,
              isInProjectPage: false,
              isInDashboardPage: true,
              isLoadingDisabled: false,
            };
          },
        },
      );

      expect(wrapper.vm.isLoadingDisabled).toBe(true);
    });
  });
});
