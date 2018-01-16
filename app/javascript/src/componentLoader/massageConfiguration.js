const massageConfiguration = (config, identifier) => {
  const result = {
    [identifier]: {}
  };

  Object.keys(config)
    .forEach(
      addon => Object.keys(config[addon])
        .forEach(
          component => {
            if (config[addon][component].areas.indexOf(identifier) !== -1) {
              result[identifier][component] = config[addon][component];
            }
          }
        )
    );

    return result;
};

export default massageConfiguration;
