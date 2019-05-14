/* eslint-disable import/prefer-default-export, global-require, import/no-dynamic-require */
import { shallowMount, createLocalVue } from '@vue/test-utils';

const getComponentFileNameFromTest = () => {
  const testFileName = module.parent.filename;
  return testFileName
    .replace('spec/frontend', 'app/assets/javascripts')
    .replace('_spec.js', '.vue');
};

export const createComponentWrapper = (options = {}, destroyHook = afterEach) => {
  const { componentFileName = getComponentFileNameFromTest() } = options;
  const { default: component } = require(componentFileName);
  const localVue = createLocalVue();

  const wrapper = shallowMount(component, {
    localVue,

    // async will become default in the next release
    // https://github.com/vuejs/vue-test-utils/issues/1137
    sync: false,

    ...options,
  });

  destroyHook(() => {
    wrapper.destroy();
  });

  return wrapper;
};
