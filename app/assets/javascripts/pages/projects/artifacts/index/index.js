import initFilteredSearch from '~/pages/search/init_filtered_search';
import ProjectArtifactsFilteredSearchTokenKeys from '~/filtered_search/project_artifacts_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ARTIFACTS,
    filteredSearchTokenKeys: ProjectArtifactsFilteredSearchTokenKeys,
  });
});
