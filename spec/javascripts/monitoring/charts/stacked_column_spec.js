import { shallowMount } from '@vue/test-utils';
import StackedColumnChart from '~/monitoring/components/charts/stacked_column.vue';
import { graphDataPrometheusQueryRange } from '../mock_data';

describe('Stacked column chart component', () => {
  let stackedColumnChart;
  const containerWidth = 200;

  beforeEach(() => {
    stackedColumnChart = shallowMount(StackedColumnChart, {
      propsData: {
        graphData: graphDataPrometheusQueryRange,
        containerWidth,
      },
    })
  });

  afterEach(() => {
    stackedColumnChart.destroy();
  });

  describe('with graphData present', () => {
    it('chartData should return an array of arrays', () => {
      expect(stackedColumnChart.vm.chartData.length).toBe(4);
    });
  });
});
