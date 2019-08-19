import Vue from 'vue';
import Metrics from '~/monitoring/components/embed.vue';
import { createStore } from '~/monitoring/stores';

function groupAdjacentElements(acc, element, _, elements) {
  // we already added this element (from previous sibling)
  if (acc.find(group => group.includes(element))) {
    return acc;
  }

  // create new group, and add this element
  const length = acc.push([element]);
  const lastGroup = acc[length - 1];

  let currentEl = element;

  while (elements.includes(currentEl.nextElementSibling)) {
    currentEl = currentEl.nextElementSibling;
    lastGroup.push(currentEl);
  }

  return acc;
}

function addWrapperElement(group) {
  const firstEl = group[0];
  const parent = firstEl.parentNode;
  const wrapper = document.createElement('div');
  wrapper.className = 'd-flex flex-wrap';
  parent.replaceChild(wrapper, firstEl);
  group.forEach(el => wrapper.appendChild(el));
}

// TODO: Handle copy-pasting - https://gitlab.com/gitlab-org/gitlab-ce/issues/64369.
export default function renderMetrics(elements) {
  if (!elements.length) {
    return;
  }

  const groupedElements = elements.reduce(groupAdjacentElements, []);
  groupedElements.forEach(addWrapperElement);

  elements.forEach(element => {
    const { dashboardUrl } = element.dataset;
    const MetricsComponent = Vue.extend(Metrics);

    // eslint-disable-next-line no-new
    new MetricsComponent({
      el: element,
      store: createStore(),
      propsData: {
        dashboardUrl,
      },
    });
  });
}
