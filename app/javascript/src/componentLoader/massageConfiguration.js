const massageConfiguration = (config, identifier) => {
  let result = {};

  const addons = Object.keys(config);
  if (addons.length > 0) {

    result = {
      [identifier]: {}
    };

    addons.forEach(
      addon => Object.keys(config[addon])
        .forEach(
          component => {
            if (config[addon][component].areas.indexOf(identifier) !== -1) {
              result[identifier][component] = config[addon][component];
            }
          }
        )
      );
    }
    
    return result;
};

export default massageConfiguration;
