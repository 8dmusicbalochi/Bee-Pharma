/** @type {import('tailwindcss').Config} */
import defaultTheme from 'tailwindcss/defaultTheme';

export default {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
    './index.html'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2563EB', // Medical Blue
          foreground: '#FFFFFF',
        },
        secondary: {
          DEFAULT: '#FFFFFF', // Clean White
          foreground: '#020617',
        },
        success: '#10B981', // Success Green
        warning: '#F59E0B', // Warning Amber
      },
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
        mono: ['monospace', ...defaultTheme.fontFamily.mono],
      },
    },
  },
  plugins: [],
};
