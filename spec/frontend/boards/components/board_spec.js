import Vue from 'vue';
import { mount, shallowMount } from '@vue/test-utils'
import Board from '~/boards/components/board';
import List from '~/boards/models/list';

describe('Board Compoennt', () => {
  let wrapper;
  let list;
  let el;

  beforeEach((done) => {
    el = document.createElement('div');
    document.body.appendChild(el);
    // wrapper = new Board({
    //   propsData: {
    //     boardId: '1',
    //     disabled: false,
    //     issueLinkBase: '/',
    //     rootPath: '/',
    //     // list: new List({
    //     //   id: 1,
    //     //   position: 0,
    //     //   title: 'test',
    //     //   list_type: 'backlog',
    //     // }),
    //   },
    // }).$mount(el);

    wrapper = shallowMount(Board, {
      propsData: {
        boardId: '1',
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        list: new List({
          id: 1,
          position: 0,
          title: 'test',
          list_type: 'backlog',
        }),
      }
    })
    console.log(wrapper.$el)
    Vue.nextTick(done);
  });

  describe('when clicking the collpase icon', () => {
    describe('when logged out', () => {
      it('sets localStorage isExpanded', () => {
        // vm.loggedIn = false;
        // wrapper.vm.toggleExpanded();
        // Vue.nextTick()
        //   .then(() => {
        //     vm.$el.querySelector('.board-title-caret').click();
        //   })
        //   .then(() => {
        //     expect(vm.$el.classList.contains('is-collapsed')).toBe(true);
        //     done();
        //   })
        //   .catch(done.fail);
      });
    });

    // describe('when logged out', () => {
    //   it('', () => {

    //   });
    // });
  });
});