import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlToast } from '@gitlab/ui';
import PanelType from '~/monitoring/components/panel_type.vue';
import EmptyChart from '~/monitoring/components/charts/empty_chart.vue';
import TimeSeriesChart from '~/monitoring/components/charts/time_series.vue';
import { createStore } from '~/monitoring/stores';
import { graphDataPrometheusQueryRange } from './mock_data';

describe('Panel Type component', () => {
  let store;
  let panelType;
  const dashboardWidth = 100;
  const exampleText = 'example_text';

  describe('When no graphData is available', () => {
    let glEmptyChart;
    // Deep clone object before modifying
    const graphDataNoResult = JSON.parse(JSON.stringify(graphDataPrometheusQueryRange));
    graphDataNoResult.queries[0].result = [];

    beforeEach(() => {
      panelType = shallowMount(PanelType, {
        propsData: {
          clipboardText: 'dashboard_link',
          dashboardWidth,
          graphData: graphDataNoResult,
        },
      });
    });

    afterEach(() => {
      panelType.destroy();
    });

    describe('Empty Chart component', () => {
      beforeEach(() => {
        glEmptyChart = panelType.find(EmptyChart);
      });

      it('is a Vue instance', () => {
        expect(glEmptyChart.isVueInstance()).toBe(true);
      });

      it('it receives a graph title', () => {
        const props = glEmptyChart.props();

        expect(props.graphTitle).toBe(panelType.vm.graphData.title);
      });
    });
  });

  describe('when Graph data is available', () => {
    let clipboardText;
    let link;
    const localVue = createLocalVue();
    localVue.use(GlToast);

    beforeEach(() => {
      store = createStore();
      panelType = shallowMount(PanelType, {
        localVue,
        propsData: {
          clipboardText: exampleText,
          dashboardWidth,
          graphData: graphDataPrometheusQueryRange,
        },
        store,
      });

      link = () => panelType.find('.js-chart-link');
      clipboardText = () => link().element.dataset.clipboardText;
    });

    afterEach(() => {
      panelType.destroy();
    });

    describe('Time Series Chart panel type', () => {
      it('is rendered', () => {
        expect(panelType.find(TimeSeriesChart).isVueInstance()).toBe(true);
        expect(panelType.find(TimeSeriesChart).exists()).toBe(true);
      });

      it('sets clipboard text on the dropdown', () => {
        expect(clipboardText()).toBe(exampleText);
      });

      it('creates a toast when clicking on the "Generate link to chart" link', () => {
        spyOn(panelType.vm.$toast, 'show').and.stub();

        link().vm.$emit('click');

        expect(panelType.vm.$toast.show).toHaveBeenCalled();
      });
    });
  });

  describe('when downloading metrics data as CSV', () => {
    beforeEach(() => {
      graphDataPrometheusQueryRange.y_label = 'metric';
      store = createStore();
      panelType = shallowMount(PanelType, {
        propsData: {
          clipboardText: exampleText,
          dashboardWidth,
          graphData: graphDataPrometheusQueryRange,
        },
        store,
      });
    });

    afterEach(() => {
      panelType.destroy();
    });

    describe('csvText', () => {
      it('converts metrics data from json to csv', () => {
        const header = `timestamp,${graphDataPrometheusQueryRange.y_label}`;
        const data = graphDataPrometheusQueryRange.queries[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;

        expect(panelType.vm.csvText).toMatch(`^${header}\r\n${firstRow}`);
      });
    });

    describe('downloadCsv', () => {
      it('produces a link with a Blob', () => {
        expect(panelType.vm.downloadCsv).toContain(`blob:`);
      });
    });
  });
});
