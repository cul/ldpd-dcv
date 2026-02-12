import React, { useEffect, useState } from 'react';

interface Site {
  id: string;
  title?: string;
  slug?: string;
  [key: string]: any;
}

function AdminApp() {
  const [sites, setSites] = useState<Site[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchSites();
  }, []);

  const fetchSites = async () => {
    try {
      const response = await fetch('/api/v1/sites.json');
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }
      const data = await response.json();
      setSites(data.sites);
      setLoading(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch sites');
      setLoading(false);
    }
  };

  if (loading) return <div>Loading sites...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <h1>Sites</h1>
      {sites.length === 0 ? (
        <p>No sites found</p>
      ) : (
        <ul>
          {sites.map((site) => (
            <li key={site.id}>
              {site.title || site.slug || site.id}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default AdminApp;
