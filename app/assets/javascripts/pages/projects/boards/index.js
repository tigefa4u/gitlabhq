import UsersSelect from '~/users_select';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initBoards from '~/boards';
import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  initBoards();

  // TODO: Just for testing - remove this. (pd)
    $('.btn-patricks-test-367346').click(function() {
        var response;
        var data = {
            ids: [183, 184, 185],
            from_list_id: 5,
            to_list_id: 7,
            move_before_id: 186,
            move_after_id: null
        };
        axios.put("/-/boards/2/issues/move_multiple", data).then(({ response }) => {

        });
    });

    $('.btn-patricks-test-367347').click(function() {
        var response;
        var data = {
            id: 183,
            from_list_id: 5,
            to_list_id: 7,
            move_before_id: 186
        };
        axios.put("/-/boards/2/issues/183", data).then(({ response }) => {

        });
    });

});
