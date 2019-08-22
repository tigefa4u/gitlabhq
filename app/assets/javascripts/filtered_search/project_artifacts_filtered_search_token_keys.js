import FilteredSearchTokenKeys from './filtered_search_token_keys';

const tokenKeys = [
  {
    key: 'deleted-branches',
    type: 'string',
    param: 'deleted-branches',
    symbol: '',
    icon: 'tag',
    tag: 'Yes or No', // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
    lowercaseValueOnSubmit: true,
    capitalizeTokenValue: true,
  },
];

const ProjectArtifactsFilteredSearchTokenKeys = new FilteredSearchTokenKeys(tokenKeys);

export default ProjectArtifactsFilteredSearchTokenKeys;
