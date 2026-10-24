import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Mogul Club | Demo operations', description: 'Read-only synthetic property demonstration' };
export default function Layout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body><a className="skip" href="#main">Skip to content</a>{children}</body></html>;
}
