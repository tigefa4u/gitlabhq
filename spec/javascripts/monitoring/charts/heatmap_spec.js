import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import Heatmap from '~/monitoring/components/charts/heatmap.vue';
import * as types from '~/monitoring/stores/mutation_types';
import MonitoringMock from '../mock_data';

describe('Heatmap component', () => {
  let heatmapChart;
  let store;
  let mockGraphData;

  beforeEach(() => {
    store = createStore();
    store.commit(`monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`, MonitoringMock.data);

    [mockGraphData] = store.state.monitoringDashboard.groups[0].metrics;

    heatmapChart = shallowMount(Heatmap, {
      propsData: {
        graphData: mockGraphData,
        containerWidth: 100,
      },
      store,
    });
  });

  afterEach(() => {
    heatmapChart.destroy();
  });

  describe('wrapped components', () => {
    describe('GitLab UI heatmap chart', () => {
      let glHeatmapChart;

      beforeEach(() => {
        glHeatmapChart = heatmapChart.find(GlHeatmap);
      });

      it('is a Vue instance', () => {
        expect(glHeatmapChart.isVueInstance()).toBe(true);
      });
    });
  });
});
