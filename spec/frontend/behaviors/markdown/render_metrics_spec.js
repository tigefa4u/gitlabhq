import Vue from 'vue';
import { createStore } from '~/monitoring/stores';
import renderMetrics from '~/behaviors/markdown/render_metrics';

jest.mock('vue');
jest.mock('~/monitoring/stores');

describe('Render metrics for Gitlab Flavoured Markdown', () => {
  it('does nothing when no elements are found', () => {
    renderMetrics([]);

    expect(createStore).not.toHaveBeenCalled();
    expect(Vue.extend).not.toHaveBeenCalled();
  });

  it('renders a vue component when elements are found', () => {
    const element = document.createElement('div');
    renderMetrics([element]);

    expect(createStore).toHaveBeenCalled();
    expect(Vue.extend).toHaveBeenCalled();
  });
});
