import { useEffect, useState } from "react";

interface AccountRow {
  user_id: string;
  display_name: string;
  account_status: string;
  roles: string[];
}

export default function OwnerAccountDirectory({ token }: { token: string }) {
  const [rows, setRows] = useState<AccountRow[]>([]);
  const [page, setPage] = useState(0);
  const [more, setMore] = useState(false);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [revision, setRevision] = useState(0);
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const abort = new AbortController();
    setLoading(true);
    setError("");
    fetch("/api/v1/admin/accounts?page=" + page, {
      headers: { Authorization: "Bearer " + token },
      signal: abort.signal,
      cache: "no-store",
    }).then(async response => {
      if (!response.ok) throw new Error(response.status === 403
        ? "Owner access with authenticator verification is required."
        : "Accounts could not be loaded.");
      return response.json() as Promise<{ accounts: AccountRow[]; has_more: boolean }>;
    }).then(data => {
      if (!abort.signal.aborted) { setRows(data.accounts); setMore(data.has_more); }
    }).catch(e => { if (!abort.signal.aborted) setError(String(e)); })
      .finally(() => { if (!abort.signal.aborted) setLoading(false); });
    return () => abort.abort();
  }, [token, page, revision]);

  async function revoke(userId: string, role: string) {
    if (!window.confirm("Revoke " + role + " access for this account?")) return;
    setBusy(true);
    setError("");
    try {
      const response = await fetch("/api/v1/admin/roles/revoke", {
        method: "POST",
        headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
        body: JSON.stringify({ target_user_id: userId, role, reason: "Owner revoked role through account directory" }),
      });
      if (!response.ok) {
        const result = await response.json() as { message?: string; error?: string };
        throw new Error(result.message ?? result.error ?? "Role revocation was not completed.");
      }
      setRevision(value => value + 1);
    } catch (e) { setError(e instanceof Error ? e.message : "Role revocation failed."); }
    finally { setBusy(false); }
  }

  const filtered = rows.filter(row => [row.display_name, row.user_id, ...row.roles]
    .some(value => value.toLowerCase().includes(search.trim().toLowerCase())));
  return <section className="proto-account-invitations" aria-labelledby="owner-directory-heading">
    <div className="proto-account-invitations-heading">
      <div><p className="proto-eyebrow"><span />OWNER CONTROLS</p>
        <h3 id="owner-directory-heading">Account directory</h3></div>
      <span className="proto-account-status">MFA verified</span>
    </div>
    <p>Find learner and staff accounts and review their access. Account IDs are unique.</p>
    <label>Search this page
      <input type="search" value={search} onChange={event => setSearch(event.target.value)}
        placeholder="Display name, account ID or role" />
    </label>
    {error && <p role="alert" className="proto-account-feedback error">{error}</p>}
    {loading ? <p role="status">Loading accounts…</p> :
      filtered.length === 0 ? <p>No matching accounts on this page.</p> :
      <div className="proto-account-invitation-list">
        {filtered.map(row => <article className="proto-account-invitation-row" key={row.user_id}>
          <div>
            <strong>{row.display_name}</strong>
            <small>Account ID: {row.user_id}</small>
            <small>Status: {row.account_status} · Roles: {row.roles.join(", ") || "None"}</small>
          </div>
          <div>{row.roles.filter(role => role !== "owner").map(role =>
            <button key={role} className="proto-account-toggle" type="button"
              disabled={busy} onClick={() => void revoke(row.user_id, role)}>Revoke {role}</button>)}</div>
        </article>)}
      </div>}
    <div>
      <button className="proto-account-toggle" type="button" disabled={loading || page === 0}
        onClick={() => setPage(p => p - 1)}>Previous</button>
      <span> Page {page + 1} </span>
      <button className="proto-account-toggle" type="button" disabled={loading || !more}
        onClick={() => setPage(p => p + 1)}>Next</button>
      <button className="proto-account-toggle" type="button" disabled={loading}
        onClick={() => setRevision(n => n + 1)}>Refresh</button>
    </div>
  </section>;
}
