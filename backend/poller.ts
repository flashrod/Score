import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const API_KEY = Deno.env.get("FOOTBALL_DATA_API_KEY")!;
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

async function refresh() {
  if (refreshing) return;
  refreshing = true;
  try {
    const headers = { "X-Auth-Token": API_KEY };
    const [matchesRes, standingsRes] = await Promise.all([
      fetch(`${BASE}/competitions/PL/matches?status=SCHEDULED,TIMED,IN_PLAY,PAUSED,FINISHED`, { headers }),
      fetch(`${BASE}/competitions/PL/standings`, { headers }),
    ]);
    const matches = await matchesRes.json();
    const standings = await standingsRes.json();
    const ts = Date.now();
    await Promise.all([
      kv.set(["matches"], matches),
      kv.set(["standings"], standings),
      kv.set(["lastRefreshed"], ts),
    ]);
  } catch (err) {
    console.error("refresh failed:", err);
  } finally {
    refreshing = false;
  }
}

serve(async (req) => {
  const url = new URL(req.url);

  if (url.pathname === "/matches") {
    const cached = await kv.get(["matches"]);
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    const matches = (cached.value as any)?.matches || [];
    const interval = pollInterval(matches);
    if (Date.now() - last >= interval) refresh();
    return Response.json(cached.value, {
      headers: { "content-type": "application/json" },
    });
  }

  if (url.pathname === "/standings") {
    const cached = await kv.get(["standings"]);
    const last = (await kv.get(["lastRefreshed"])).value as number || 0;
    if (Date.now() - last >= 60_000) refresh();
    return Response.json(cached.value, {
      headers: { "content-type": "application/json" },
    });
  }

  if (url.pathname === "/health") {
    const last = (await kv.get(["lastRefreshed"])).value;
    return Response.json({ ok: true, lastRefreshed: last });
  }

  return new Response("not found", { status: 404 });
});
