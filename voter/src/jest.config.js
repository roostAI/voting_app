module.exports = {
        testEnvironment: 'node',
        testRegex: '(/__tests__/.*|(\.|/)(test|spec))\.(jsx?|tsx?)$',
        moduleFileExtensions: ['js', 'jsx', 'ts', 'tsx'],
        transform: {
          '^.+\.(jsx?|tsx?)$': 'babel-jest',
        },
      };