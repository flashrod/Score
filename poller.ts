const API_KEY = Deno.env.get("FOOTBALL_DATA_API_KEY");
if (!API_KEY) {
  console.error("FOOTBALL_DATA_API_KEY not set");
  Deno.exit(1);
}

const BASE = "https://api.football-data.org/v4";
const kv = await Deno.openKv();

let refreshing = false;

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
        return;
      }
      const matchesArray = matchesData.matches ?? [];
      const ts = Date.now();
      await Promise.all([
        kv.set(["matches"], matchesArray),
        kv.set(["matchInfo"], { competition: matchesData.competition, season: matchesData.season, filters: matchesData.filters, resultSet: matchesData.resultSet }),
        kv.set(["standings"], standingsData.standings ?? standingsData),
        kv.set(["lastRefreshed"], ts),
      ]);
      console.log("refresh OK —", matchesArray.length, "matches");
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
    let matchesArr = (await kv.get(["matches"])).value as any[] | null;
    const matchInfo = (await kv.get(["matchInfo"])).value as any | null;
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    if (!matchesArr || Date.now() - last >= pollInterval(matchesArr)) {
      await refresh();
      matchesArr = (await kv.get(["matches"])).value as any[] | null;
    }
    return new Response(JSON.stringify({
      filters: matchInfo?.filters ?? {},
      resultSet: matchInfo?.resultSet ?? { count: matchesArr?.length ?? 0, played: 0 },
      competition: matchInfo?.competition ?? null,
      matches: matchesArr ?? [],
    }), { headers });
  }

  if (url.pathname === "/standings") {
    let standings = (await kv.get(["standings"])).value;
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    if (!standings || Date.now() - last >= 60_000) {
      await refresh();
      standings = (await kv.get(["standings"])).value;
    }
    return new Response(JSON.stringify({ standings }), { headers });
  }

  if (url.pathname === "/health") {
    const last = (await kv.get(["lastRefreshed"])).value;
    return new Response(JSON.stringify({ ok: true, lastRefreshed: last }), { headers });
  }

  if (url.pathname === "/raw") {
    const res = await fetch(`${BASE}/competitions/PL/matches`, {
      headers: { "X-Auth-Token": API_KEY, "Accept": "application/json" },
    });
    const text = await res.text();
    return new Response(JSON.stringify({ status: res.status, body: text.slice(0, 2000) }), { headers });
  }

  if (url.pathname === "/debug") {
    const matches = await kv.get(["matches"]);
    const standings = await kv.get(["standings"]);
    const last = await kv.get(["lastRefreshed"]);
    return new Response(JSON.stringify({
      hasMatches: !!matches.value,
      matchesType: typeof matches.value,
      matchesKeys: matches.value ? Object.keys(matches.value as any) : null,
      matchesCount: (matches.value as any)?.count,
      matchesArrayLen: (matches.value as any)?.matches?.length,
      lastRefreshed: last.value,
    }), { headers });
  }

  return new Response(JSON.stringify({ error: "not found" }), { status: 404, headers });
});
