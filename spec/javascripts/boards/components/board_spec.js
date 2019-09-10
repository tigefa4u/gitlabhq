import Vue from 'vue';
import Board from '~/boards/components/board';
import List from '~/boards/models/list';
import { mockBoardService } from '../mock_data';

describe('Board component', () => {
  let vm;

  const createComponent = ({ gon = {}, collapsed = false, listType = 'backlog' } = {}) => {
    if (Object.prototype.hasOwnProperty.call(gon, 'current_user_id')) {
      window.gon = gon;
    } else {
      window.gon = {};
    }
    const el = document.createElement('div');
    document.body.appendChild(el);

    vm = new Board({
      propsData: {
        boardId: '1',
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        list: new List({
          id: 1,
          position: 0,
          title: 'test',
          list_type: listType,
          collapsed,
        }),
      },
    }).$mount(el);
  };

  const cleanUpTests = () => {
    vm.$destroy();

    // remove the component from the DOM
    document.querySelector('.board').remove();

    localStorage.removeItem(`${vm.uniqueKey}.expanded`);
  };

  describe('List', () => {
    beforeEach(() => {
      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });
    });

    it('board is expandable when list type is closed', () => {
      expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
    });

    it('board is expandable when list type is label', () => {
      expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
    });

    it('board is not expandable when list type is blank', () => {
      expect(new List({ id: 1, list_type: 'blank' }).isExpandable).toBe(false);
    });
  });

  describe('when clicking the header', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent();

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('does not collapse', done => {
      vm.list.isExpanded = true;
      vm.$el.querySelector('.board-header').click();

      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('is-collapsed')).toBe(false);

        done();
      });
    });
  });

  describe('when clicking the collapse icon', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent();

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('collapses', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.$el.classList.contains('is-collapsed')).toBe(true);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('when clicking the expand icon', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent();

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('expands', done => {
      vm.list.isExpanded = false;

      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('when collapsed is false', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent();

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('is expanded when collapsed is false', () => {
      expect(vm.list.isExpanded).toBe(true);
      expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
    });
  });

  describe('when list type is blank', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent({ listType: 'blank' });

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('does not render add issue button when list type is blank', done => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.issue-count-badge-add-button')).toBeNull();

        done();
      });
    });
  });

  describe('when list type is backlog', () => {
    beforeEach(done => {
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent();

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('board is expandable', () => {
      expect(vm.$el.classList.contains('is-expandable')).toBe(true);
    });
  });

  describe('when logged in', () => {
    beforeEach(done => {
      spyOn(List.prototype, 'update');
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent({ gon: { current_user_id: 1 } });

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('calls list update', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.list.update).toHaveBeenCalledTimes(1);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('when logged out', () => {
    beforeEach(done => {
      spyOn(List.prototype, 'update');
      loadFixtures('boards/show.html');

      gl.boardService = mockBoardService({
        boardsEndpoint: '/',
        listsEndpoint: '/',
        bulkUpdatePath: '/',
        boardId: 1,
      });

      createComponent({ collapsed: false });

      Vue.nextTick(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    // can only be one or the other cant toggle window.gon.current_user_id states.
    it('clicking on the caret does not call list update', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.list.update).toHaveBeenCalledTimes(0);
          done();
        })
        .catch(done.fail);
    });

    it('sets expanded to be the opposite of its value when toggleExpanded is called', done => {
      const expanded = true;
      vm.list.isExpanded = expanded;
      vm.toggleExpanded();

      Vue.nextTick()
        .then(() => {
          expect(vm.list.isExpanded).toBe(!expanded);
          expect(localStorage.getItem(`${vm.uniqueKey}.expanded`)).toBe(String(!expanded));

          done();
        })
        .catch(done.fail);
    });

    it('does render add issue button', () => {
      expect(vm.$el.querySelector('.issue-count-badge-add-button')).not.toBeNull();
    });
  });
});
