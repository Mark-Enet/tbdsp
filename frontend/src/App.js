import './App.css';
import { useEffect, useMemo, useState } from 'react';

const DOMAIN_CARDS = [
  {
    name: 'blogging',
    databases: ['postgresql'],
    description: 'Schemas for posts, authors, comments, and related analytics.',
  },
  {
    name: 'ecommerce',
    databases: ['postgresql', 'mysql'],
    description: 'Schemas for catalog, carts, orders, and operational reporting.',
  },
];

function App() {
  const [health, setHealth] = useState({
    state: 'checking',
    checkedAt: null,
    detail: 'Checking backend connectivity...',
  });

  const domainCount = useMemo(() => DOMAIN_CARDS.length, []);

  useEffect(() => {
    let cancelled = false;

    const apiCandidates = [
      '/api/domains',
      `${window.location.protocol}//${window.location.hostname}:5000/api/domains`,
    ];

    const fetchDomains = async () => {
      let lastError = null;

      for (const endpoint of apiCandidates) {
        try {
          const response = await fetch(endpoint, {
            method: 'GET',
            headers: { Accept: 'application/json' },
          });

          const contentType = response.headers.get('content-type') || '';
          if (!response.ok || !contentType.includes('application/json')) {
            throw new Error(`Unexpected response from ${endpoint}`);
          }

          const payload = await response.json();
          return { payload, endpoint };
        } catch (error) {
          lastError = error;
        }
      }

      throw lastError || new Error('No API endpoint responded');
    };

    const checkApiHealth = async () => {
      try {
        const { payload, endpoint } = await fetchDomains();
        const domains = Array.isArray(payload) ? payload.length : 0;

        if (!cancelled) {
          setHealth({
            state: 'up',
            checkedAt: new Date(),
            detail: `API reachable via ${endpoint}. Returned ${domains} domain${domains === 1 ? '' : 's'}.`,
          });
        }
      } catch (error) {
        if (!cancelled) {
          setHealth({
            state: 'down',
            checkedAt: new Date(),
            detail: `API check failed: ${error.message}`,
          });
        }
      }
    };

    checkApiHealth();
    const intervalId = window.setInterval(checkApiHealth, 30000);

    return () => {
      cancelled = true;
      window.clearInterval(intervalId);
    };
  }, []);

  const statusClassName =
    health.state === 'up'
      ? 'status-pill status-pill--up'
      : health.state === 'down'
      ? 'status-pill status-pill--down'
      : 'status-pill status-pill--checking';

  const statusLabel =
    health.state === 'up' ? 'Online' : health.state === 'down' ? 'Offline' : 'Checking';

  return (
    <div className="app-shell">
      <header className="hero">
        <p className="eyebrow">TBDSP</p>
        <h1>Tabular Data &amp; Benchmarking Schema Playground</h1>
        <p className="hero-copy">
          Browse curated schema packs across multiple domains and database engines,
          with API access ready for local experimentation.
        </p>
      </header>

      <main className="main-grid">
        <section className="panel">
          <div className="panel-header">
            <h2>Available Domains</h2>
            <span>{domainCount} total</span>
          </div>
          <div className="domain-grid">
            {DOMAIN_CARDS.map((domain) => (
              <article key={domain.name} className="domain-card">
                <h3>{domain.name}</h3>
                <p>{domain.description}</p>
                <ul>
                  {domain.databases.map((database) => (
                    <li key={`${domain.name}-${database}`}>{database}</li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </section>

        <section className="panel">
          <div className="panel-header">
            <h2>API Status</h2>
            <span className={statusClassName}>{statusLabel}</span>
          </div>
          <p className="status-text">{health.detail}</p>
          {health.checkedAt && (
            <p className="status-timestamp">
              Last checked: {health.checkedAt.toLocaleString()}
            </p>
          )}
          <p className="status-note">
            Endpoint: <code>/api/domains</code>
          </p>
        </section>
      </main>
    </div>
  );
}

export default App;
