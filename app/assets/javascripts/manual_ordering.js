import Sortable from 'sortablejs';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import {
  getBoardSortableDefaultOptions,
  sortableStart,
} from '~/boards/mixins/sortable_default_options';
import axios from '~/lib/utils/axios_utils';

function updateIssue(url, { move_before_id, move_after_id }) {
  return axios
    .put(`${url}/reorder`, {
      move_before_id,
      move_after_id,
    })
    .catch(() => {
      createFlash(s__("ManualOrdering|Couldn't save the order of the issues"));
    });
}

export default function initManualOrdering() {
  const issueList = document.querySelector('.manual-ordering');
  if (!issueList || !(gon.features && gon.features.manualSorting)) {
    return;
  }

  const options = getBoardSortableDefaultOptions({
    scroll: true,
    dataIdAttr: 'data-id',
    fallbackOnBody: false,
    group: {
      name: 'issues',
    },
    draggable: 'li.issue',
    onStart: () => {
      sortableStart();
    },
    onUpdate: event => {
      const el = event.item;

      const url = el.getAttribute('url');

      const prev = el.previousElementSibling;
      const next = el.nextElementSibling;

      const beforeId = prev && prev.dataset.id;
      const afterId = next && next.dataset.id;

      updateIssue(url, { move_after_id: afterId, move_before_id: beforeId });
    },
  });

  Sortable.create(issueList, options);
}
