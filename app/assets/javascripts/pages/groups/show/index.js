import initGroupDetails from '../shared/group_details';

document.addEventListener('DOMContentLoaded', () => {
  if (!document.querySelector('#js-group-security-dashboard')) initGroupDetails();
});
