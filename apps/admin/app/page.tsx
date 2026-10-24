import type { PropertyPage } from '@mogul/contracts';
import Link from 'next/link';
export const dynamic = 'force-dynamic';
export default async function Operations({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q = '' } = await searchParams;
  let data: PropertyPage | null = null;
  try {
    const url = new URL('/api/v1/properties', process.env.API_BASE_URL ?? 'http://127.0.0.1:3001');
    url.searchParams.set('q', q.slice(0, 80));
    const response = await fetch(url, { cache: 'no-store', signal: AbortSignal.timeout(4000) });
    if (!response.ok) throw new Error('Unavailable');
    data = await response.json() as PropertyPage;
  } catch { /* Render an honest recovery path; no fallback fixture data. */ }
  return <>
    <header><Link href="/" className="wordmark">MOGUL <span>CLUB</span></Link><span className="badge">DEVELOPMENT DEMO</span></header>
    <main id="main">
      <p className="eyebrow">OPERATIONS / PROPERTY LIBRARY</p>
      <h1>A clear view of every property.</h1>
      <p className="intro">Explore the discovery catalogue served by the Mogul Club API. All records are synthetic. No investments are available.</p>
      <section className="notice" aria-label="Demo access"><strong>Read-only demonstration</strong><p>Staff sign-in, property editing and approval workflows are not available yet. This page grants no administrative access.</p></section>
      <section aria-labelledby="properties-heading">
        <div className="section-heading"><h2 id="properties-heading">Property library</h2><span>{data ? `${data.total} synthetic records` : 'Connection unavailable'}</span></div>
        <form role="search"><label htmlFor="q">Search by name or location</label><div className="search"><input id="q" name="q" type="search" maxLength={80} defaultValue={q} placeholder="Property name, city or state"/><button type="submit">Search</button></div></form>
        {!data ? <div role="alert" className="state"><h3>We couldn’t load the property library.</h3><p>Check that the API and MongoDB are running, then try again.</p><Link href={`/?q=${encodeURIComponent(q)}`}>Retry connection</Link></div> : data.items.length === 0 ? <div role="status" className="state"><h3>No properties found.</h3><p>Try a different name or location.</p><Link href="/">Clear search</Link></div> :
          <div className="table-wrap" role="region" aria-label="Property library table" tabIndex={0}><table><caption className="sr-only">Synthetic property records, not investment offerings</caption><thead><tr><th scope="col">Property</th><th scope="col">Location</th><th scope="col">Type</th><th scope="col">Illustrative value</th><th scope="col">Status</th></tr></thead><tbody>{data.items.map(property => <tr key={property.id}><th scope="row">{property.name}<small>{property.bedrooms} beds · {property.bathrooms} baths · {property.areaSqFt.toLocaleString('en-US')} sq ft</small></th><td>{property.city}, {property.state}</td><td>{property.propertyType}</td><td>{new Intl.NumberFormat('en-US', { style: 'currency', currency: property.currency, maximumFractionDigits: 0 }).format(property.illustrativeValueMinor / 100)}<small>Synthetic amount</small></td><td><span className="status">Demo only</span></td></tr>)}</tbody></table></div>}
      </section>
      <footer><strong>Built on transparent records.</strong><p>Demo data is not a verified valuation, a securities offering or a promise of returns. Financial execution is disabled.</p></footer>
    </main>
  </>;
}
