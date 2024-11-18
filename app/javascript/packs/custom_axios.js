import axios from 'axios';

const instance = axios.create({
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json'
  }
});

function getUrlsInput() {
  const input = document.querySelector('input[name=axios-urls]');
  if (input) {
    return input;
  }

  const urlsInput = document.createElement('input');
  urlsInput.setAttribute('type', 'hidden');
  urlsInput.setAttribute('name', 'axios-urls');
  urlsInput.setAttribute('value', '[]');
  document.querySelector('body').appendChild(urlsInput);

  return urlsInput;
}

function addUrl(url) {
  const input = getUrlsInput();
  const urls = JSON.parse(input.value);
  if (!urls.includes(url)) {
    urls.push(url);
    input.value = JSON.stringify(urls);
  }
}

function isUrlExist(url) {
  const input = getUrlsInput();
  const urls = JSON.parse(input.value);
  return urls.includes(url);
}

function removeUrl(url) {
  const input = getUrlsInput();
  const urls = JSON.parse(input.value);
  const index = urls.indexOf(url);
  if (index > -1) {
    urls.splice(index, 1);
    input.value = JSON.stringify(urls);
  }
}

instance.interceptors.request.use(
  (config) => {
    const updatedConfig = config;
    const csrfToken = document.querySelector('[name=csrf-token]').content;
    updatedConfig.headers['X-CSRF-Token'] = csrfToken;

    const controller = new AbortController();

    if (updatedConfig.method !== 'get') {
      if (isUrlExist(updatedConfig.url)) {
        controller.abort();
      }
      addUrl(updatedConfig.url);
    }

    return {
      ...updatedConfig,
      signal: controller.signal
    };
  },
  (error) => (Promise.reject(error))
);

instance.interceptors.response.use(
  (response) => {
    const { config } = response;

    if (config.method !== 'get') {
      removeUrl(config.url);
    }

    return response;
  },
  (error) => (Promise.reject(error))
);

export default instance;
