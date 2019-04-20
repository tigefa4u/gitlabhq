import Vue from 'vue';
import Api from '~/api';
import VueResource from 'vue-resource';
import * as constants from '../constants';

Vue.use(VueResource);

export default {
  poll(data = {}) {
    const endpoint = data.notesData.notesPath;
    const { lastFetchedAt } = data;
    const options = {
      headers: {
        'X-Last-Fetched-At': lastFetchedAt ? `${lastFetchedAt}` : undefined,
      },
    };

    return Vue.http.get(endpoint, options);
  },
};
