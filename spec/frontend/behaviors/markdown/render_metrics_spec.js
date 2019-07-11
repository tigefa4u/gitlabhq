import Vue from 'vue';
import renderMetrics from '~/behaviors/markdown/render_metrics';
import { TEST_HOST } from 'helpers/test_constants';

const originalExtend = Vue.extend;

describe('Render metrics for Gitlab Flavoured Markdown', () => {
  const mockMount = jest.fn();
  const mockMetrics = function Metrics() {
    this.$mount = mockMount;
  };

  beforeEach(() => {
    Vue.extend = () => mockMetrics;
  });

  afterEach(() => {
    Vue.extend = originalExtend;
    mockMount.mockReset();
  });

  it('does nothing when no elements are found', () => {
    renderMetrics([]);

    expect(mockMount).not.toHaveBeenCalled();
  });

  it('renders a vue component when elements are found', () => {
    const element = document.createElement('div');
    element.setAttribute('data-dashboard-url', TEST_HOST);

    renderMetrics([element]);

    expect(mockMount).toHaveBeenCalled();
  });
});
