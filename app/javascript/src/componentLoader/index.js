import { createLoader } from 'react-hijack';

const componentLoader = createLoader((module) => import('./components/' + module));

export default componentLoader;
