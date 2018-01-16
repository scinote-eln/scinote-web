import { createLoader } from 'react-hijack';

const componentLoader = createLoader((module) => import('' + module));

export default componentLoader;

