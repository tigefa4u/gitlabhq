import Api from '~/api';

import $ from 'jquery';
import Flash from '../flash';
import FileTemplateTypeSelector from './template_selectors/type_selector';
import BlobCiYamlSelector from './template_selectors/ci_yaml_selector';
import DockerfileSelector from './template_selectors/dockerfile_selector';
import GitignoreSelector from './template_selectors/gitignore_selector';
import LicenseSelector from './template_selectors/license_selector';

export default class FileTemplateMediator {
  constructor({ editor, currentAction, projectId }) {
    this.editor = editor;
    this.currentAction = currentAction;
    this.projectId = projectId;

    this.initTemplateSelectors();
    this.initTemplateTypeSelector();
    this.initDomElements();
    this.initDropdowns();
    this.initPageEvents();
    this.initDefaultContent();
  }

  initTemplateSelectors() {
    // Order dictates template type dropdown item order
    this.templateSelectors = [
      GitignoreSelector,
      BlobCiYamlSelector,
      DockerfileSelector,
      LicenseSelector,
    ].map(TemplateSelectorClass => new TemplateSelectorClass({ mediator: this }));
  }

  initTemplateTypeSelector() {
    this.typeSelector = new FileTemplateTypeSelector({
      mediator: this,
      dropdownData: this.templateSelectors.map(templateSelector => {
        const cfg = templateSelector.config;

        return {
          name: cfg.name,
          key: cfg.key,
        };
      }),
    });
  }

  initDomElements() {
    const $templatesMenu = $('.template-selectors-menu');
    const $undoMenu = $templatesMenu.find('.template-selectors-undo-menu');
    const $fileEditor = $('.file-editor');

    this.$templatesMenu = $templatesMenu;
    this.$undoMenu = $undoMenu;
    this.$undoBtn = $undoMenu.find('button');
    this.$templateSelectors = $templatesMenu.find('.template-selector-dropdowns-wrap');
    this.$filenameInput = $fileEditor.find('.js-file-path-name-input');
    this.$fileContent = $fileEditor.find('#file-content');
    this.$commitForm = $fileEditor.find('form');
    this.$navLinks = $fileEditor.find('.nav-links');
  }

  initDropdowns() {
    if (this.currentAction === 'create') {
      this.typeSelector.show();
    } else {
      this.hideTemplateSelectorMenu();
    }

    this.displayMatchedTemplateSelector();
  }

  initPageEvents() {
    this.listenForFilenameInput();
    this.prepFileContentForSubmit();
    this.listenForPreviewMode();
  }

  initDefaultContent() {
    const { config } = this.templateSelectors[1]
    
    this.fetchFileTemplate(config.type, config.defaultTemplate)
      .then(file => {
        this.setEditorContent(file)
      })
    
    this.setFilename(config.name)
    this.displayMatchedTemplateSelector();
  }

  listenForFilenameInput() {
    this.$filenameInput.on('keyup blur', () => {
      this.displayMatchedTemplateSelector();
    });
  }

  prepFileContentForSubmit() {
    this.$commitForm.submit(() => {
      this.$fileContent.val(this.editor.getValue());
    });
  }

  listenForPreviewMode() {
    this.$navLinks.on('click', 'a', e => {
      const urlPieces = e.target.href.split('#');
      const hash = urlPieces[1];
      if (hash === 'preview') {
        this.hideTemplateSelectorMenu();
      } else if (hash === 'editor' && !this.typeSelector.isHidden()) {
        this.showTemplateSelectorMenu();
      }
    });
  }

  selectTemplateType(item, e) {
    if (e) {
      e.preventDefault();
    }

    this.templateSelectors.forEach(selector => {
      if (selector.config.name === this.getFilename()) {
        selector.show();
      } else {
        selector.hide();
      }
    });

    this.typeSelector.setToggleText(item.name);

    this.cacheToggleText();
  }

  selectTemplateTypeOptions(options) {
    this.selectTemplateType(options.selectedObj, options.e);
  }

  selectTemplateFile(selector, query, data) {
    selector.renderLoading();
    // in case undo menu is already there
    this.destroyUndoMenu();
    this.fetchFileTemplate(selector.config.type, query, data)
      .then(file => {
        this.showUndoMenu();
        this.setEditorContent(file);
        selector.renderLoaded();
      })
      .catch(err => new Flash(`An error occurred while fetching the template: ${err}`));
  }

  displayMatchedTemplateSelector() {
    const currentInput = this.getFilename();
    this.templateSelectors.forEach(selector => {
      const match = selector.config.pattern.test(currentInput);

      if (match) {
        this.typeSelector.show();
        this.selectTemplateType(selector.config);
        this.showTemplateSelectorMenu();
      } else {
        this.clearEditorContent()
      }
    });
  }

  fetchFileTemplate(type, query, data = {}) {
    return new Promise(resolve => {
      const resolveFile = file => resolve(file);
     
      Api.projectTemplate(this.projectId, type, query, data, resolveFile);
    });
  }

  clearEditorContent() {
    this.editor.setValue("")
  }

  setEditorContent(file) {
    if (!file && file !== '') return;

    const newValue = file.content || file;

    this.editor.setValue(newValue, 1);

    this.editor.focus();

    this.editor.navigateFileStart();
  }

  findTemplateSelectorByKey(key) {
    return this.templateSelectors.find(selector => selector.config.key === key);
  }

  showUndoMenu() {
    this.$undoMenu.removeClass('hidden');

    this.$undoBtn.on('click', e => {
      e.preventDefault()
      this.restoreFromCache();
      this.clearEditorContent();
      this.destroyUndoMenu();
    });
  }

  destroyUndoMenu() {
    this.cacheFileContents();
    this.cacheToggleText();
    this.$undoMenu.addClass('hidden');
    this.$undoBtn.off('click');
  }

  hideTemplateSelectorMenu() {
    this.$templatesMenu.hide();
  }

  showTemplateSelectorMenu() {
    this.$templatesMenu.show();
  }

  cacheToggleText() {
    this.cachedToggleText = this.getTemplateSelectorToggleText();
  }

  cacheFileContents() {
    this.cachedContent = this.editor.getValue();
    this.cachedFilename = this.getFilename();
  }

  restoreFromCache() {
    this.setEditorContent(this.cachedContent);
    this.setTemplateSelectorToggleText();
  }

  getTemplateSelectorToggleText() {
    return this.$templateSelectors
      .find('.js-template-selector-wrap:visible .dropdown-toggle-text')
      .text();
  }

  setTemplateSelectorToggleText() {
      return this.$templateSelectors
      .find('.js-template-selector-wrap:visible .dropdown-toggle-text')
      .text(this.cachedToggleText);
  }

  getTypeSelectorToggleText() {
    return this.typeSelector.getToggleText();
  }

  getFilename() {
    return this.$filenameInput.val();
  }

  setFilename(filename) {
    this.$filenameInput.val(filename)
  }

  getSelected() {
    return this.templateSelectors.find(selector => selector.selected);
  }
}
