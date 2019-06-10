import axios from '~/lib/utils/axios_utils';

export default {
  fetchIssues(endpoint, filters, state) {
    return axios.get(`${endpoint}`, {
      params: {
        ...filters,
        state,
        with_labels_details: true, // ensures we more details for labels
      },
    });
  },
};
