const API_KEY = Deno.env.get("FOOTBALL_DATA_API_KEY");
if (!API_KEY) {
  console.error("FOOTBALL_DATA_API_KEY not set");
  Deno.exit(1);
}

const BASE = "https://api.football-data.org/v4";

let cache: {
  matches: any[] | null;
  competitions: any;
  standings: any;
  lastRefreshed: number;
} = { matches: null, competitions: null, standings: null, lastRefreshed: 0 };

let refreshing = false;
let refreshPromise: Promise<void> | null = null;

function pollInterval(matches: any[] | null): number {
  if (!matches || matches.length === 0) return 60_000;
  const live = matches.find((m: any) =>
    m.status === "IN_PLAY" || m.status === "PAUSED"
  );
  const upcoming = matches.find((m: any) =>
    m.status === "SCHEDULED" || m.status === "TIMED"
  );
  const match = live || upcoming;
  if (!match) return 60_000;

  switch (match.status) {
    case "SCHEDULED":
    case "TIMED": {
      const delta = new Date(match.utcDate).getTime() - Date.now();
      if (delta <= 5 * 60_000) return 15_000;
      if (delta <= 15 * 60_000) return 30_000;
      return 60_000;
    }
    case "IN_PLAY": {
      const m = parseInt(match.minute) || 0;
      if (m >= 90) return 3_000;
      if (m >= 80) return 5_000;
      return 10_000;
    }
    case "PAUSED": return 15_000;
    case "FINISHED": return 60_000;
    case "POSTPONED": case "CANCELLED": return 300_000;
    case "SUSPENDED": return 30_000;
    default: return 60_000;
  }
}

async function refresh(): Promise<void> {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    try {
      const headers = { "X-Auth-Token": API_KEY };
      const [matchesRes, standingsRes] = await Promise.all([
        fetch(`${BASE}/competitions/PL/matches`, { headers }),
        fetch(`${BASE}/competitions/PL/standings`, { headers }),
      ]);
      if (matchesRes.status !== 200) {
        console.error("matches API error:", matchesRes.status);
        return;
      }
      if (standingsRes.status !== 200) {
        console.error("standings API error:", standingsRes.status);
        return;
      }
      const matchesData = await matchesRes.json();
      const standingsData = await standingsRes.json();
      cache = {
        matches: matchesData.matches ?? [],
        competitions: { competition: matchesData.competition, season: matchesData.season, filters: matchesData.filters, resultSet: matchesData.resultSet },
        standings: standingsData.standings ?? standingsData,
        lastRefreshed: Date.now(),
      };
      console.log("refresh OK —", cache.matches.length, "matches");
    } catch (err) {
      console.error("refresh failed:", err);
    } finally {
      refreshPromise = null;
    }
  })();
  return refreshPromise;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const json = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), {
      status,
      headers: { "content-type": "application/json; charset=utf-8" },
    });

  if (url.pathname === "/matches") {
    const elapsed = Date.now() - cache.lastRefreshed;
    if (!cache.matches || elapsed >= pollInterval(cache.matches)) {
      await refresh();
    }
    return json({
      filters: cache.competitions?.filters ?? {},
      resultSet: cache.competitions?.resultSet ?? { count: cache.matches?.length ?? 0, played: 0 },
      competition: cache.competitions?.competition ?? null,
      matches: cache.matches ?? [],
    });
  }

  if (url.pathname === "/standings") {
    const elapsed = Date.now() - cache.lastRefreshed;
    if (!cache.standings || elapsed >= 60_000) {
      await refresh();
    }
    return json({ standings: cache.standings ?? [] });
  }

  if (url.pathname === "/health") {
    return json({ ok: true, lastRefreshed: cache.lastRefreshed });
  }

  if (url.pathname === "/raw") {
    const res = await fetch(`${BASE}/competitions/PL/matches`, {
      headers: { "X-Auth-Token": API_KEY },
    });
    const text = await res.text();
    return json({ status: res.status, size: text.length, preview: text.slice(0, 500) });
  }

  return json({ error: "not found" }, 404);
});
