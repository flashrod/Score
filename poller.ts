const API_KEY = Deno.env.get("FOOTBALL_DATA_API_KEY");
if (!API_KEY) {
  console.error("FOOTBALL_DATA_API_KEY not set");
  Deno.exit(1);
}

const BASE = "https://api.football-data.org/v4";
const kv = await Deno.openKv();

let refreshing = false;

function pollInterval(matches: any[]): number {
  const live = matches?.find((m: any) =>
    m.status === "IN_PLAY" || m.status === "PAUSED"
  );
  const upcoming = matches?.find((m: any) =>
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

let refreshPromise: Promise<void> | null = null;

async function refresh(): Promise<void> {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    try {
      const headers = { "X-Auth-Token": API_KEY };
      const [matchesRes, standingsRes] = await Promise.all([
        fetch(`${BASE}/competitions/PL/matches`, { headers }),
        fetch(`${BASE}/competitions/PL/standings`, { headers }),
      ]);
      const matchesData = await matchesRes.json();
      const standingsData = await standingsRes.json();
      console.log("API status:", matchesRes.status, "matches count:", matchesData?.count, "has matches array:", Array.isArray(matchesData?.matches));
      if (matchesRes.status !== 200) {
        console.error("matches API error:", matchesRes.status, JSON.stringify(matchesData).slice(0, 500));
        return;
      }
      if (standingsRes.status !== 200) {
        console.error("standings API error:", standingsRes.status, JSON.stringify(standingsData).slice(0, 500));
      }
      const ts = Date.now();
      await Promise.all([
        kv.set(["matches"], matchesData),
        kv.set(["standings"], standingsData),
        kv.set(["lastRefreshed"], ts),
      ]);
      console.log("refresh OK —", matchesData?.matches?.length ?? "?", "matches");
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
  const headers = { "content-type": "application/json; charset=utf-8" };

  if (url.pathname === "/matches") {
    const cached = await kv.get(["matches"]);
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    const matches = (cached.value as any)?.matches || [];
    if (!cached.value || Date.now() - last >= pollInterval(matches)) {
      await refresh();
    }
    const result = await kv.get(["matches"]);
    return new Response(JSON.stringify(result.value ?? { matches: [] }), { headers });
  }

  if (url.pathname === "/standings") {
    const cached = await kv.get(["standings"]);
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    if (!cached.value || Date.now() - last >= 60_000) {
      await refresh();
    }
    const result = await kv.get(["standings"]);
    return new Response(JSON.stringify(result.value ?? { standings: [{ table: [] }] }), { headers });
  }

  if (url.pathname === "/health") {
    const last = (await kv.get(["lastRefreshed"])).value;
    return new Response(JSON.stringify({ ok: true, lastRefreshed: last }), { headers });
  }

  return new Response(JSON.stringify({ error: "not found" }), { status: 404, headers });
});
