"use client";
export default function ErrorPage({ reset }: { reset: () => void }) { return <main id="main"><h1>Something went wrong.</h1><p>The operations page could not be displayed.</p><button onClick={reset}>Try again</button></main>; }
