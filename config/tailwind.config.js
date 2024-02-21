const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/javascript/**/*.vue',
    './app/assets/javascripts/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './addons/**/*.{erb,haml,html,slim,vue}'
  ],
  corePlugins: {
    preflight: false
  },
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        transparent: 'transparent',
        current: 'currentColor',
        'sn-white': '#FFFFFF',
        'sn-super-light-grey': '#F9F9F9',
        'sn-light-grey': '#EAECF0',
        'sn-sleepy-grey': '#D0D5DD',
        'sn-grey': '#98A2B3',
        'sn-dark-grey': '#475467',
        'sn-black': '#1D2939',
        'sn-blue': '#104DA9',
        'sn-science-blue': '#3B99FD',
        'sn-super-light-blue': '#F0F8FF',
        'sn-blue-hover': '#2D5FAA',
        'sn-science-blue-hover': '#79B4F3',
        'sn-alert-green': '#5EC66F',
        'sn-alert-violet': '#6F2DC1',
        'sn-alert-brittlebush': '#E9A845',
        'sn-alert-passion': '#DF3562',
        'sn-alert-turqoise': '#46C3C8',
        'sn-alert-bloo': '#3070ED',
        'sn-alert-blue-disabled': '#87A6D4',
        'sn-alert-green-disabled': '#AEE3B7',
        'sn-alert-violet-disabled': '#B796E0',
        'sn-alert-brittlebush-disabled': '#F4D3A2',
        'sn-alert-passion-disabled': '#EF9AB0',
        'sn-alert-turqoise-disabled': '#A2E1E3',
        'sn-alert-science-blue-disabled': '#9DCCFE',
        'sn-delete-red': '#CE0C24',
        'sn-delete-red-hover': '#AD0015',
        'sn-delete-red-disabled': '#F5D7DB',
        'sn-coral': '#FB565B',
        'sn-background-blue': '#DBE4F2',
        'sn-background-green': '#E7F7E9',
        'sn-background-violet': '#E9DFF6',
        'sn-background-brittlebush': '#FCF2E3',
        'sn-background-passion': '#FAE1E7',
        'sn-background-turqoise': '#E3F6F7',
        'sn-background-bloo': '#E2F0FF'
      },
      boxShadow: {
        'flyout-shadow': '0px 1px 4px rgba(35, 31, 32, 0.15)',
        'sn-menu-sm': '0px 16px 32px 0px rgba(16, 24, 40, 0.07)',
        'sn-classic-drop-shadow': '0px 0px 64px -12px rgba(16, 24, 40, 0.16)',
      },
      transitionTimingFunction: {
        sharp: 'cubic-bezier(.4, 0, .6, 1)',
      },
    }
  },
  blocklist: [
    'collapse',
    'container'
  ],
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('@tailwindcss/line-clamp')
  ]
}
