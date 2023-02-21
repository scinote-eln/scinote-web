#!/usr/bin/env node

const { spawn, execSync } = require('child_process');
const enginePaths = execSync('ls -d $PWD/addons/*').toString().split('\n').filter((p) => !!p);
enginePaths.forEach(enginePath => {
  spawn('yarn', ['install'], {
    env: process.env,
    cwd: enginePath,
    stdio: 'inherit'
  });
});
