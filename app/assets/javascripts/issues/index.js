import Vue from 'vue';
import projectSelect from '~/project_select';
import IssuableIndex from '~/issuable_index';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import store from './stores';
import IssuesApp from './components/issues_app.vue';
import IssuesFilteredSearch from './issues_filtered_search';

export default () => {
  const el = document.querySelector('#js-issues-list');

  if (!el) return null;

  const { endpoint, canUpdate, createPath } = el.dataset;
  const canBulkUpdate = Boolean(canUpdate);

  // Set default filters from URL
  store.dispatch('issuesList/setFilters', window.location.search);

  // Setup filterd search component
  const filteredSearch = new IssuesFilteredSearch(store.state.issuesList.filters);

  // Setup issue page handlers
  const issuableIndex = new IssuableIndex(ISSUABLE_INDEX.ISSUE);

  return new Vue({
    el,
    store,
    components: {
      IssuesApp,
    },
    mounted() {
      filteredSearch.setup();
    },
    created() {
      this.dataset = this.$options.el.dataset;
    },
    render(createElement) {
      return createElement('issues-app', {
        props: {
          endpoint,
          createPath,
          projectSelect,
          canBulkUpdate,
          issuableIndex,
          filteredSearch,
          emptyStateSvgPath: this.dataset.emptyStateSvgPath,
          emptyStateLoadingDisabledSvgPath: this.dataset.emptyStateLoadingDisabledSvgPath,
        },
      });
    },
  });
};
