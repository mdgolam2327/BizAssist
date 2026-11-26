import type { Config } from 'tailwindcss';
const config: Config = { content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'], theme: { extend: { colors: { ink: '#172b3a', leaf: '#168767' }, fontFamily: { display: ['Manrope', 'sans-serif'] } } }, plugins: [] };
export default config;
