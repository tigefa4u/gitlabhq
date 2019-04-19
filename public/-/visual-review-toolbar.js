///////////////////////////////////////////////
/////////////////// STYLES ////////////////////
///////////////////////////////////////////////

const wrapperStyles = `
  position: sticky;
  top: 0;
  display: flex;
  justify-content: space-around;
  width: 100vw;
  padding: 1rem;
  background-color: coral;
  color: mintcream;
  font-family: 'Avenir Next', sans-serif;
  font-size: 1rem;
`;

const formStyles = `
  display: flex;
  flex-direction: column;
  padding: 0 1rem;
`;

const labelStyles = `
  display: inline-block;
  width: 100%;
`;

const buttonWrapperStyles = `
  margin-top: 1rem;
  display: flex;
  align-items: baseline;
`;

const buttonStyles = `
  font-size: .75rem;
  background-color: #2a0094;
  color: white;
`

const messageStyles =  `
  padding: 0 1rem;
`

const agentStyles =  `
  padding: 0 1rem;
  font-size: .6rem;
`

///////////////////////////////////////////////
/////////////////// STATE ////////////////////
///////////////////////////////////////////////

const PERSONAL_TOKEN = 'personal access token';
const RESOURCE_OWNER = 'resource owner';
const data = {};

///////////////////////////////////////////////
///////////////// COMPONENTS //////////////////
///////////////////////////////////////////////
const note = `
  <p id='gitlab-validation-note' style='${messageStyles}'></p>
`;

const comment = `
  <div>
    <label for='gitlab-comment' style='${labelStyles}'>Comment:</label>
    <textarea id='gitlab-comment' name='gitlab-comment' rows='3' cols='80'></textarea>
  </div>
  <div class='button' style='${buttonWrapperStyles}'>
    <button style='${buttonStyles}' type='button' id='gitlab-comment-button'> ✨ Comment ✨ </button>
    ${note}
  </div>
`

const login = `
  <div id='gitlab-form-wrapper' style='${formStyles}'>
    <div> Enter your Gitlab credentials. </div>
    <div>
      <label for='username' style='${labelStyles}'>Username:</label>
      <input type='text' id='gitlab-username' name='username'>
    </div>
    <div>
      <label for='password' style='${labelStyles}'>Password:</label>
      <input type='password' id='gitlab-password' name='password'>
    </div>
    <div> Or, if you use 2-factor authentication, please generate and provide an access token </div>
    <div>
      <label for='password' style='${labelStyles}'>Access token:</label>
      <input type='password' id='gitlab-token' name='token'>
    </div>
    <div class='button' style='${buttonWrapperStyles}'>
      <button style='${buttonStyles}' type='button' id='gitlab-login'> 🌈 Submit ☄️ </button>
      ${note}
    </div>
  </div>
`

///////////////////////////////////////////////
//////////////// INTERACTIONS /////////////////
///////////////////////////////////////////////

// from https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator
function getBrowserId (sUsrAg) {
  var aKeys = ["MSIE", "Edge", "Firefox", "Safari", "Chrome", "Opera"],
      nIdx = aKeys.length - 1;

  for (nIdx; nIdx > -1 && sUsrAg.indexOf(aKeys[nIdx]) === -1; nIdx--);

  return aKeys[nIdx];
}

function addCommentButtonEvent () {
  // get user agent data
  const { innerWidth,
          innerHeight,
          navigator: {
            platform, userAgent
          } } = window;
  const browser = getBrowserId(userAgent);

  const scriptName = 'ReviewAppToolbar';
  const projectId = document.querySelector(`script[data-name='${scriptName}']`).getAttribute('data-project');
  const discussionId = document.querySelector(`script[data-name='${scriptName}']`).getAttribute('data-discussion');
  const commentButton = document.getElementById('gitlab-comment-button');

  const details = {
    platform,
    browser,
    userAgent,
    innerWidth,
    innerHeight,
    projectId,
    discussionId
  };
  commentButton.onclick = postComment.bind(null, details);
}

function authorizeUser () {

  // Clear any old errors
  clearNote();

  // if they give us a token, we don't need to go get one
  const token = document.getElementById('gitlab-token').value;

  if (token) {
    authSuccess(token, PERSONAL_TOKEN)
    return;
  }

  // NOTE: This is vestigial user validation that may be removed, pending
  // OAuth solution decisions.
  // otherwise, get the data for the request out of the form
  const username = document.getElementById('gitlab-username').value;
  const password = document.getElementById('gitlab-password').value;
  const note = document.getElementById('gitlab-validation-note');

  // validate
  if (!(username && password) && !token) {
    note.innerText = 'Please enter username and password or token'
    return;
  }

  if (!token && (username && !password) || (!username && password)) {
    note.innerText = 'Please enter both username and password'
    return;
  }

  // call the success function
  authSuccess(token, RESOURCE_OWNER)

}

function authSuccess (token, accessType) {
  const formWrapper = document.getElementById('gitlab-form-wrapper');
  data.accessType = accessType;
  data.token = token;
  formWrapper.innerHTML = comment;
  addCommentButtonEvent();
}

function clearNote () {
  const note = document.getElementById('gitlab-validation-note');
  note.innerText = '';
}

function confirmAndClear (discussionId) {
  const commentBox = document.getElementById('gitlab-comment');
  const note = document.getElementById('gitlab-validation-note');

  commentBox.value = '';
  note.innerText = `Your comment was successfully posted to issue #${discussionId}`;

  // we can add a fade animation here
  setTimeout(() => note.innerText = '', 3000)

}

function postComment ({
  platform,
  browser,
  userAgent,
  innerWidth,
  innerHeight,
  projectId,
  discussionId
}) {

  // Clear any old errors
  clearNote();

  const commentText = document.getElementById('gitlab-comment').value;
  const detailText = `
    \n\n -----
    \n Posted from ${platform} | ${browser} | ${innerWidth} x ${innerHeight}.
    \n *User agent: ${userAgent}*
  `;

  const url = `
    https://gitlab.com/api/v4/projects/${projectId}/issues/${discussionId}/discussions?body=
    ${encodeURIComponent(commentText)}${encodeURIComponent(detailText)}
  `;

  fetch(url, {
     method: 'POST',
     headers: {
      'PRIVATE-TOKEN': data.token
    }
  })
  .then((response) => {

    if (response.ok) {
      confirmAndClear(discussionId);
      return;
    }

    throw new Error(`${response.status}: ${response.statusText}`)

  })
  .catch((err) => postError(`Something went wrong. ${err.message}`));

}

function postError (message) {
  const note = document.getElementById('gitlab-validation-note');

  note.innerText = message;
}

///////////////////////////////////////////////
///////////////// INJECTION //////////////////
///////////////////////////////////////////////

window.addEventListener('load', (event) => {
  // add elements
  const container = document.createElement('div');
  container.setAttribute('style', wrapperStyles);
  container.setAttribute('id', 'gitlab-review-container');
  container.insertAdjacentHTML('beforeend', login);

  // finally prepend everything to the body
  document.body.insertBefore(container, document.body.firstChild);

  // add handlers (TODO: Put these in a function)
  const loginButton = document.getElementById('gitlab-login');
  if (loginButton) { loginButton.onclick = authorizeUser; }
});
