import Vue from 'vue';
import Metrics from '~/monitoring/components/embed.vue';
import { createStore } from '~/monitoring/stores';

// TODO: Handle copy-pasting.
export default function renderMetrics(elements) {
  if (elements.length < 1) {
    return;
  }

  elements.each((index, element) => {
    const link = element.dataset.dashboardUrl;
    const MetricsComponent = Vue.extend(Metrics);

    const renderedComponent = new MetricsComponent({
      el: element,
      store: createStore(),
      propsData: {
        link,
      },
    });

    renderedComponent.$mount();
  });
}
