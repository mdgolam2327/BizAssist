import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'BizAssist ERP | Business, in sync', description: 'A flexible business workspace for your operations.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
