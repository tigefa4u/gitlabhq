import $ from 'jquery';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';
import Wikis from './wikis';
import GLForm from '../../../gl_form';

document.addEventListener('DOMContentLoaded', () => {
  new Wikis(); // eslint-disable-line no-new
  new ShortcutsWiki(); // eslint-disable-line no-new
  new GLForm($('.wiki-form')); // eslint-disable-line no-new
});
