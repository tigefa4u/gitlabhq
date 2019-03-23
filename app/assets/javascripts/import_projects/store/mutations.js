import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },

  [types.REQUEST_REPOS](state, options = {}) {
    state.isLoadingRepos = true;
    state.currentPage = options.page || 1;
  },

  [types.RECEIVE_REPOS_SUCCESS](
    state,
    { importedProjects, providerRepos, namespaces, totalItems },
  ) {
    state.isLoadingRepos = false;

    state.importedProjects = importedProjects;
    state.providerRepos = providerRepos;
    state.namespaces = namespaces;

    state.totalItems = totalItems || importedProjects.length + providerRepos.length; // OR can be removed when X-total exists. Just here to demonstrate.
  },

  [types.RECEIVE_REPOS_ERROR](state) {
    state.isLoadingRepos = false;
  },

  [types.REQUEST_IMPORT](state, repoId) {
    state.reposBeingImported.push(repoId);
  },

  [types.RECEIVE_IMPORT_SUCCESS](state, { importedProject, repoId }) {
    const existingRepoIndex = state.reposBeingImported.indexOf(repoId);
    if (state.reposBeingImported.includes(repoId))
      state.reposBeingImported.splice(existingRepoIndex, 1);

    const providerRepoIndex = state.providerRepos.findIndex(
      providerRepo => providerRepo.id === repoId,
    );
    state.providerRepos.splice(providerRepoIndex, 1);
    state.importedProjects.unshift(importedProject);
  },

  [types.RECEIVE_IMPORT_ERROR](state, repoId) {
    const repoIndex = state.reposBeingImported.indexOf(repoId);
    if (state.reposBeingImported.includes(repoId)) state.reposBeingImported.splice(repoIndex, 1);
  },

  [types.RECEIVE_JOBS_SUCCESS](state, updatedProjects) {
    updatedProjects.forEach(updatedProject => {
      const existingProject = state.importedProjects.find(
        importedProject => importedProject.id === updatedProject.id,
      );

      Vue.set(existingProject, 'importStatus', updatedProject.importStatus);
    });
  },
};
