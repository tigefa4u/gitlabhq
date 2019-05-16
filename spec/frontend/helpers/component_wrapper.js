/* eslint-disable import/prefer-default-export, global-require, import/no-dynamic-require */
import { shallowMount, createLocalVue } from '@vue/test-utils';

export const createComponentFactory = (component, callback = () => {}) => {
  const localVue = createLocalVue();
  let wrapper = null;

  const setWrapper = newWrapper => {
    if (wrapper) {
      wrapper.destroy();
    }

    wrapper = newWrapper;
    callback(newWrapper);

    return newWrapper;
  };

  const create = (...options) =>
    setWrapper(
      shallowMount(component, {
        localVue,
        // async will become default in the next release
        // https://github.com/vuejs/vue-test-utils/issues/1137
        sync: false,
        ...options,
      }),
    );

  afterEach(() => setWrapper(null));

  return create;
};
