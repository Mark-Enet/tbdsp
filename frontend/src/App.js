import './App.css';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

const FILE_LABELS = {
  schema: 'Schema SQL',
  sample_data: 'Sample Data',
  readme: 'Readme',
  erd: 'ER Diagram',
};

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function Highlight({ text, query }) {
  if (!text) return null;
  if (!query) return <>{text}</>;
  const parts = text.split(new RegExp(`(${escapeRegex(query)})`, 'gi'));
  if (parts.length === 1) return <>{text}</>;
  return (
    <>
      {parts.map((part, i) =>
        i % 2 === 1 ? <mark key={i} className="hl">{part}</mark> : (part || null)
      )}
    </>
  );
}

function App() {
  // ── Stable API base list ────────────────────────────────────────────
  const apiBases = useMemo(() => {
    const hostBase = `${window.location.protocol}//${window.location.hostname}:5000`;
    return ['', hostBase];
  }, []);

  const requestJson = useCallback(
    async (path) => {
      let lastError = null;
      for (const base of apiBases) {
        const endpoint = `${base}${path}`;
        try {
          const response = await fetch(endpoint, {
            method: 'GET',
            headers: { Accept: 'application/json' },
          });
          const ct = response.headers.get('content-type') || '';
          if (!response.ok || !ct.includes('application/json')) {
            throw new Error(`Unexpected response from ${endpoint}`);
          }
          return await response.json();
        } catch (error) {
          lastError = error;
        }
      }
      throw lastError || new Error('No API endpoint responded');
    },
    [apiBases],
  );

  // ── API health (polls every 30 s) ────────────────────────────────────
  const [health, setHealth] = useState({ state: 'checking', checkedAt: null, detail: 'Checking…' });

  useEffect(() => {
    let cancelled = false;
    const check = async () => {
      try {
        const data = await requestJson('/api/meta/domains');
        if (!cancelled) {
          setHealth({
            state: 'up',
            checkedAt: new Date(),
            detail: `API online. ${Array.isArray(data) ? data.length : 0} domain(s) indexed.`,
          });
        }
      } catch (e) {
        if (!cancelled) {
          setHealth({ state: 'down', checkedAt: new Date(), detail: `API check failed: ${e.message}` });
        }
      }
    };
    check();
    const id = window.setInterval(check, 30000);
    return () => { cancelled = true; window.clearInterval(id); };
  }, [requestJson]);

  // ── Domains ─────────────────────────────────────────────────────────
  const [metaDomains, setMetaDomains] = useState([]);
  const [domainsError, setDomainsError] = useState('');
  const [selectedDomain, setSelectedDomain] = useState('');

  useEffect(() => {
    let cancelled = false;
    const load = async () => {
      try {
        const meta = await requestJson('/api/meta/domains');
        if (!cancelled) {
          if (Array.isArray(meta) && meta.length > 0) {
            setMetaDomains(meta);
            setSelectedDomain((prev) => prev || meta[0]?.name || '');
          } else {
            const fs = await requestJson('/api/domains');
            if (!cancelled) {
              setMetaDomains(
                (Array.isArray(fs) ? fs : []).map((name) => ({
                  name,
                  table_count: null,
                  column_count: null,
                  engine_count: null,
                })),
              );
              setSelectedDomain((prev) => prev || (Array.isArray(fs) ? fs[0] : '') || '');
            }
          }
          setDomainsError('');
        }
      } catch (e) {
        if (!cancelled) setDomainsError(e.message);
      }
    };
    load();
    return () => { cancelled = true; };
  }, [requestJson]);

  // ── Engines for selected domain ──────────────────────────────────────
  const [engines, setEngines] = useState([]);
  const [selectedEngine, setSelectedEngine] = useState('');

  useEffect(() => {
    let cancelled = false;
    setEngines([]);
    setSelectedEngine('');
    if (!selectedDomain) return;
    const load = async () => {
      try {
        const data = await requestJson(
          `/api/meta/domains/${encodeURIComponent(selectedDomain)}/engines`,
        );
        if (!cancelled && Array.isArray(data) && data.length) {
          setEngines(data);
          const targetEngine = pendingNav.current?.engine;
          const match = targetEngine && data.find((e) => e.engine === targetEngine);
          setSelectedEngine(match ? targetEngine : data[0].engine);
        }
      } catch (_) {}
    };
    load();
    return () => { cancelled = true; };
  }, [requestJson, selectedDomain]);

  // ── Tables list ──────────────────────────────────────────────────────
  const [tables, setTables] = useState([]);
  const [tablesLoading, setTablesLoading] = useState(false);
  const [selectedTable, setSelectedTable] = useState('');

  useEffect(() => {
    let cancelled = false;
    setTables([]);
    setSelectedTable('');
    if (!selectedDomain || !selectedEngine) return;
    setTablesLoading(true);
    const load = async () => {
      try {
        const data = await requestJson(
          `/api/meta/domains/${encodeURIComponent(selectedDomain)}/${encodeURIComponent(selectedEngine)}/tables`,
        );
        if (!cancelled) {
          const rows = Array.isArray(data) ? data : [];
          setTables(rows);
          const target = pendingNav.current?.table;
          if (target && rows.find((t) => t.name === target)) {
            setSelectedTable(target);
            pendingNav.current = null;
          }
        }
      } catch (_) {
        if (!cancelled) { setTables([]); pendingNav.current = null; }
      } finally {
        if (!cancelled) setTablesLoading(false);
      }
    };
    load();
    return () => { cancelled = true; };
  }, [requestJson, selectedDomain, selectedEngine]);

  // ── Table detail ─────────────────────────────────────────────────────
  const [tableDetail, setTableDetail] = useState(null);
  const [tableDetailLoading, setTableDetailLoading] = useState(false);
  const tableDetailRef = useRef(null);
  const [hlCursor, setHlCursor] = useState(0);
  const [hlTotal, setHlTotal] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setTableDetail(null);
    if (!selectedDomain || !selectedEngine || !selectedTable) return;
    setTableDetailLoading(true);
    const load = async () => {
      try {
        const data = await requestJson(
          `/api/meta/domains/${encodeURIComponent(selectedDomain)}/${encodeURIComponent(selectedEngine)}/tables/${encodeURIComponent(selectedTable)}`,
        );
        if (!cancelled) setTableDetail(data);
      } catch (_) {
        if (!cancelled) setTableDetail(null);
      } finally {
        if (!cancelled) setTableDetailLoading(false);
      }
    };
    load();
    return () => { cancelled = true; };
  }, [requestJson, selectedDomain, selectedEngine, selectedTable]);

  // ── File schemas (for Files tab) ─────────────────────────────────────
  const [fileSchemas, setFileSchemas] = useState([]);

  useEffect(() => {
    let cancelled = false;
    if (!selectedDomain) return;
    requestJson(`/api/schemas/${encodeURIComponent(selectedDomain)}`)
      .then((data) => { if (!cancelled) setFileSchemas(Array.isArray(data) ? data : []); })
      .catch(() => { if (!cancelled) setFileSchemas([]); });
    return () => { cancelled = true; };
  }, [requestJson, selectedDomain]);

  // ── File preview ─────────────────────────────────────────────────────
  const [preview, setPreview] = useState({ loading: false, error: '', domain: '', database: '', filename: '', content: '' });

  const openPreview = useCallback(
    async (domain, database, filename) => {
      setPreview({ loading: true, error: '', domain, database, filename, content: '' });
      let lastErr = null;
      for (const base of apiBases) {
        const endpoint = `${base}/api/schemas/${encodeURIComponent(domain)}/${encodeURIComponent(database)}/${encodeURIComponent(filename)}`;
        try {
          const r = await fetch(endpoint, { headers: { Accept: 'application/json' } });
          const ct = r.headers.get('content-type') || '';
          if (!r.ok || !ct.includes('application/json')) throw new Error('Bad response');
          const payload = await r.json();
          setPreview({ loading: false, error: '', domain, database, filename, content: payload.content || '' });
          return;
        } catch (e) { lastErr = e; }
      }
      setPreview({ loading: false, error: lastErr?.message || 'Failed', domain, database, filename, content: '' });
    },
    [apiBases],
  );

  // ── Navigate-to: jump Explorer to a specific domain/engine/table ────
  const navigateTo = useCallback(
    (domain, engine, table) => {
      pendingNav.current = { engine, table };
      if (selectedDomain === domain) {
        // domain already loaded — decide whether to trigger engine/table effects
        if (selectedEngine !== engine) {
          // engine change will trigger tables reload → pendingNav.table consumed there
          setSelectedEngine(engine);
        } else {
          // same engine: tables already loaded, set directly
          setSelectedTable(table);
          pendingNav.current = null;
        }
      } else {
        // domain change will cascade through engines → tables effects
        setSelectedDomain(domain);
      }
      setExplorerView('tables');
      setTimeout(() => explorerRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 80);
    },
    [selectedDomain, selectedEngine],
  );

  // ── Explorer tab ──────────────────────────────────────────────────────
  const [explorerView, setExplorerView] = useState('tables');

  // ── Search ────────────────────────────────────────────────────────────
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const searchTimer = useRef(null);
  // pendingNav holds { engine, table } set by navigateTo; consumed by downstream effects
  const pendingNav = useRef(null);
  const explorerRef = useRef(null);

  useEffect(() => {
    if (searchTimer.current) clearTimeout(searchTimer.current);
    const q = searchQuery.trim();
    if (!q) { setSearchResults([]); return; }
    searchTimer.current = setTimeout(async () => {
      setSearchLoading(true);
      try {
        const data = await requestJson(`/api/meta/search?q=${encodeURIComponent(q)}`);
        setSearchResults(Array.isArray(data) ? data : []);
      } catch (_) {
        setSearchResults([]);
      } finally {
        setSearchLoading(false);
      }
    }, 300);
    return () => clearTimeout(searchTimer.current);
  }, [searchQuery, requestJson]);

  // ── Count highlight matches after table detail / query changes ────────
  useEffect(() => {
    if (!tableDetailRef.current) return;
    const marks = tableDetailRef.current.querySelectorAll('mark.hl');
    setHlTotal(marks.length);
    setHlCursor(0);
  }, [tableDetail, searchQuery]);

  // ── Scroll to current highlight match ────────────────────────────────
  useEffect(() => {
    if (!tableDetailRef.current || hlTotal === 0) return;
    const marks = tableDetailRef.current.querySelectorAll('mark.hl');
    marks.forEach((m) => m.classList.remove('hl--current'));
    const target = marks[hlCursor];
    if (target) {
      target.classList.add('hl--current');
      target.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }, [hlCursor, hlTotal]);

  // ── Derived ───────────────────────────────────────────────────────────
  const hlQuery = searchQuery.trim();
  const statusClassName =
    health.state === 'up' ? 'status-pill status-pill--up'
    : health.state === 'down' ? 'status-pill status-pill--down'
    : 'status-pill status-pill--checking';

  const statusLabel =
    health.state === 'up' ? 'Online' : health.state === 'down' ? 'Offline' : 'Checking';

  // ── Render ────────────────────────────────────────────────────────────
  return (
    <div className="app-shell">

      {/* ── Hero ── */}
      <header className="hero">
        <div className="hero-top">
          <div className="hero-title">
            <img
              src="https://github.com/user-attachments/assets/4c464bed-9bb2-4780-821c-10ac483941fc"
              alt="TBDSP logo"
              className="hero-logo"
            />
            <div>
              <p className="eyebrow">TBDSP</p>
              <h1>Tabular Data &amp; Benchmarking Schema Playground</h1>
              <p className="hero-copy">
                Explore tables, columns, indexes, and foreign keys across multiple domains and database engines.
              </p>
            </div>
          </div>
          <span className={statusClassName} title={health.detail}>{statusLabel}</span>
        </div>
        <div className="search-bar-wrap">
          <input
            className="search-bar"
            type="search"
            placeholder="Search tables, columns, comments across all domains…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </header>

      {/* ── Search results ── */}
      {searchQuery.trim() && (
        <section className="panel panel--wide search-results-panel">
          <div className="panel-header">
            <h2>Search Results</h2>
            <span>
              {searchLoading
                ? 'Searching…'
                : `${searchResults.length} result${searchResults.length !== 1 ? 's' : ''} for "${searchQuery.trim()}"`}
            </span>
          </div>
          {!searchLoading && searchResults.length === 0 && (
            <p className="status-text muted">No matches found.</p>
          )}
          <div className="search-result-list">
            {searchResults.map((r, i) => (
              <button
                key={i}
                type="button"
                className="search-result-row"
                onClick={() => navigateTo(r.domain, r.engine, r.table_name)}
                title={`Go to ${r.domain} › ${r.engine} › ${r.table_name}`}
              >
                <span className="sr-breadcrumb">{r.domain} / {r.engine} / <strong>{r.table_name}</strong></span>
                <span className="sr-col">
                  {r.is_primary_key && <span className="badge badge--pk">PK</span>}
                  {!r.is_nullable && <span className="badge badge--nn">NN</span>}
                  <strong>{r.column_name}</strong> <code>{r.data_type}</code>
                </span>
                {r.column_comment && <span className="sr-comment">{r.column_comment}</span>}
              </button>
            ))}
          </div>
        </section>
      )}

      <main className="main-grid">

        {/* ── Domain selector ── */}
        <section className="panel">
          <div className="panel-header">
            <h2>Domains</h2>
            <span>{metaDomains.length} total</span>
          </div>
          <div className="domain-grid">
            {metaDomains.map((d) => (
              <button
                key={d.name}
                type="button"
                className={d.name === selectedDomain ? 'domain-card domain-card--selected' : 'domain-card'}
                onClick={() => setSelectedDomain(d.name)}
              >
                <h3>{d.name}</h3>
                <div className="domain-stats">
                  {d.table_count != null && <span>{d.table_count} table{d.table_count !== 1 ? 's' : ''}</span>}
                  {d.column_count != null && <span>{d.column_count} col{d.column_count !== 1 ? 's' : ''}</span>}
                  {d.engine_count != null && <span>{d.engine_count} engine{d.engine_count !== 1 ? 's' : ''}</span>}
                </div>
              </button>
            ))}
          </div>
          {domainsError && <p className="error-text">Could not load domains: {domainsError}</p>}
        </section>

        {/* ── API status ── */}
        <section className="panel">
          <div className="panel-header">
            <h2>API Status</h2>
            <span className={statusClassName}>{statusLabel}</span>
          </div>
          <p className="status-text">{health.detail}</p>
          {health.checkedAt && (
            <p className="status-timestamp">Last checked: {health.checkedAt.toLocaleString()}</p>
          )}
        </section>

        {/* ── Explorer ── */}
        <section className="panel panel--wide" ref={explorerRef}>
          <div className="panel-header">
            <h2>
              Explorer
              {selectedDomain && <span className="panel-sub"> — {selectedDomain}</span>}
            </h2>
            <div className="tab-bar">
              <button type="button" className={explorerView === 'tables' ? 'tab tab--active' : 'tab'} onClick={() => setExplorerView('tables')}>Tables</button>
              <button type="button" className={explorerView === 'files' ? 'tab tab--active' : 'tab'} onClick={() => setExplorerView('files')}>Files</button>
            </div>
          </div>

          {/* Engine selector (multi-engine domains only) */}
          {engines.length > 1 && (
            <div className="engine-tabs">
              {engines.map((e) => (
                <button
                  key={e.engine}
                  type="button"
                  className={e.engine === selectedEngine ? 'engine-tab engine-tab--active' : 'engine-tab'}
                  onClick={() => { setSelectedEngine(e.engine); setSelectedTable(''); }}
                >
                  {e.engine}
                  {e.version_note && <span className="engine-version">{e.version_note}</span>}
                </button>
              ))}
            </div>
          )}

          {/* ── Tables view ── */}
          {explorerView === 'tables' && (
            <>
              {!selectedDomain && <p className="status-text muted">Select a domain above to begin.</p>}
              {tablesLoading && <p className="status-text">Loading tables…</p>}
              {!tablesLoading && selectedDomain && tables.length === 0 && (
                <p className="status-text muted">No tables indexed for this engine yet.</p>
              )}
              {!tablesLoading && tables.length > 0 && (
                <div className="explorer-layout">
                  {/* Table list */}
                  <div className="table-list">
                    {tables.map((t) => (
                      <button
                        key={t.name}
                        type="button"
                        className={t.name === selectedTable ? 'table-row table-row--selected' : 'table-row'}
                        onClick={() => setSelectedTable(t.name)}
                      >
                        <div className="table-row-name">{t.name}</div>
                        <div className="table-row-stats">
                          <span title="columns">{t.column_count}c</span>
                          {t.index_count > 0 && <span title="indexes">{t.index_count}i</span>}
                          {t.fk_count > 0 && <span title="foreign keys">{t.fk_count}fk</span>}
                        </div>
                        {t.table_comment && <div className="table-row-comment">{t.table_comment}</div>}
                      </button>
                    ))}
                  </div>

                  {/* Table detail */}
                  <div className="table-detail" ref={tableDetailRef}>
                    {hlTotal > 0 && (
                      <div className="hl-nav">
                        <span className="hl-nav-count">{hlCursor + 1} / {hlTotal} match{hlTotal !== 1 ? 'es' : ''}</span>
                        <button
                          type="button"
                          className="hl-nav-btn"
                          onClick={() => setHlCursor((c) => (c - 1 + hlTotal) % hlTotal)}
                          aria-label="Previous match"
                        >↑ Prev</button>
                        <button
                          type="button"
                          className="hl-nav-btn"
                          onClick={() => setHlCursor((c) => (c + 1) % hlTotal)}
                          aria-label="Next match"
                        >Next ↓</button>
                      </div>
                    )}
                    {!selectedTable && (
                      <p className="status-text muted">Select a table to see columns, indexes, and foreign keys.</p>
                    )}
                    {tableDetailLoading && <p className="status-text">Loading…</p>}
                    {tableDetail && !tableDetailLoading && (
                      <>
                        <div className="td-header">
                          <h3><Highlight text={tableDetail.name} query={hlQuery} /></h3>
                          {tableDetail.comment && <p className="td-comment"><Highlight text={tableDetail.comment} query={hlQuery} /></p>}
                        </div>

                        <h4>Columns <span className="count-badge">{tableDetail.columns.length}</span></h4>
                        <div className="col-table-wrap">
                          <table className="col-table">
                            <thead>
                              <tr>
                                <th>#</th><th>Column</th><th>Type</th><th>Flags</th><th>Default</th><th>Notes</th>
                              </tr>
                            </thead>
                            <tbody>
                              {tableDetail.columns.map((col, i) => (
                                <tr key={col.name} className={col.is_primary_key ? 'col-row col-row--pk' : 'col-row'}>
                                  <td className="col-pos">{i + 1}</td>
                                  <td className="col-name"><Highlight text={col.name} query={hlQuery} /></td>
                                  <td><code><Highlight text={col.data_type} query={hlQuery} /></code></td>
                                  <td className="col-flags">
                                    {col.is_primary_key && <span className="badge badge--pk">PK</span>}
                                    {!col.is_nullable && !col.is_primary_key && <span className="badge badge--nn">NN</span>}
                                  </td>
                                  <td className="col-default">
                                    {col.default_value && <code><Highlight text={col.default_value} query={hlQuery} /></code>}
                                  </td>
                                  <td className="col-comment"><Highlight text={col.column_comment} query={hlQuery} /></td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>

                        {tableDetail.indexes.length > 0 && (
                          <>
                            <h4>Indexes <span className="count-badge">{tableDetail.indexes.length}</span></h4>
                            <div className="index-list">
                              {tableDetail.indexes.map((idx) => (
                                <div key={idx.name} className="index-row">
                                  <span className="index-name"><Highlight text={idx.name} query={hlQuery} /></span>
                                  <span className="index-meta">
                                    {idx.is_unique && <span className="badge badge--unique">UNIQUE</span>}
                                    {idx.is_partial && <span className="badge badge--partial">PARTIAL</span>}
                                    <code>{idx.index_type.toUpperCase()}</code>
                                    {' ('}
                                    <Highlight text={Array.isArray(idx.columns) ? idx.columns.join(', ') : idx.columns} query={hlQuery} />
                                    {')'}
                                  </span>
                                  {idx.where_clause && <span className="index-where">WHERE {idx.where_clause}</span>}
                                </div>
                              ))}
                            </div>
                          </>
                        )}

                        {tableDetail.foreign_keys.length > 0 && (
                          <>
                            <h4>Foreign Keys <span className="count-badge">{tableDetail.foreign_keys.length}</span></h4>
                            <div className="fk-list">
                              {tableDetail.foreign_keys.map((fk, i) => {
                                const fromCols = Array.isArray(fk.from_columns) ? fk.from_columns.join(', ') : fk.from_columns;
                                const toCols = Array.isArray(fk.to_columns) ? fk.to_columns.join(', ') : fk.to_columns;
                                return (
                                  <div key={i} className="fk-row">
                                    <span className="fk-from">(<Highlight text={fromCols} query={hlQuery} />)</span>
                                    <span className="fk-arrow">→</span>
                                    <span className="fk-to"><Highlight text={fk.to_table} query={hlQuery} /> (<Highlight text={toCols} query={hlQuery} />)</span>
                                    {fk.on_delete && <span className="fk-action">ON DELETE {fk.on_delete}</span>}
                                  </div>
                                );
                              })}
                            </div>
                          </>
                        )}
                      </>
                    )}
                  </div>
                </div>
              )}
            </>
          )}

          {/* ── Files view ── */}
          {explorerView === 'files' && (
            <div className="explorer-layout">
              <div className="component-list">
                {fileSchemas.length === 0 && selectedDomain && (
                  <p className="status-text muted">No files found.</p>
                )}
                {fileSchemas.map((schema) => {
                  const files = Object.entries(schema.files || {}).filter(([, v]) => v);
                  return (
                    <article className="component-card" key={`${schema.domain}-${schema.database}`}>
                      <div className="component-header">
                        <h3>{schema.database}</h3>
                        <span>{files.length} file{files.length !== 1 ? 's' : ''}</span>
                      </div>
                      <div className="chip-row">
                        {files.map(([key, filename]) => (
                          <button
                            className="file-chip"
                            type="button"
                            key={`${schema.database}-${filename}`}
                            onClick={() => openPreview(schema.domain, schema.database, filename)}
                          >
                            {FILE_LABELS[key] || filename}
                          </button>
                        ))}
                      </div>
                    </article>
                  );
                })}
              </div>
              <aside className="preview-panel">
                <h3>File Preview</h3>
                {!preview.loading && !preview.content && !preview.error && (
                  <p className="status-text muted">Select a file chip to preview content.</p>
                )}
                {preview.loading && <p className="status-text">Loading…</p>}
                {preview.error && <p className="error-text">{preview.error}</p>}
                {!preview.loading && preview.content && (
                  <>
                    <p className="preview-meta">{preview.domain} / {preview.database} / {preview.filename}</p>
                    <pre className="preview-content">{preview.content}</pre>
                  </>
                )}
              </aside>
            </div>
          )}

        </section>
      </main>
    </div>
  );
}

export default App;
