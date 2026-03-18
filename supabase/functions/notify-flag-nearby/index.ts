// Keep Moving — Edge Function: notify-flag-nearby
// Triggered by database webhook on flags INSERT
// Finds drivers within RADIUS_MILES of the flagged stop and sends push notifications

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webPush from 'npm:web-push';

// Tune this based on real data — dense corridors may need smaller radius
const RADIUS_MILES = 50;

// Haversine distance in miles between two lat/lng points
function distanceMiles(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 3958.8;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180)
    * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const flag = body.record; // Supabase webhook sends { record, old_record, type }

    if (!flag || !flag.stop_lat || !flag.stop_lng) {
      return new Response(JSON.stringify({ skipped: 'no coordinates on flag' }), { status: 200 });
    }

    webPush.setVapidDetails(
      'mailto:keepmoving@coverwhale.com',
      Deno.env.get('VAPID_PUBLIC_KEY')!,
      Deno.env.get('VAPID_PRIVATE_KEY')!
    );

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch all push subscriptions with known locations
    const { data: subs } = await supabase
      .from('push_subscriptions')
      .select('user_id, subscription, last_lat, last_lng')
      .not('last_lat', 'is', null);

    if (!subs || subs.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    const flagLat = flag.stop_lat;
    const flagLng = flag.stop_lng;
    const flagType = flag.flag_type || 'Alert';
    const flagIcon = flag.flag_icon || '⚠️';
    const stopName = flag.stop_name || 'Nearby stop';

    let sent = 0;

    for (const sub of subs) {
      // Skip the driver who posted the flag
      if (sub.user_id === flag.user_id) continue;

      const dist = distanceMiles(flagLat, flagLng, sub.last_lat, sub.last_lng);
      if (dist > RADIUS_MILES) continue;

      const distLabel = dist < 1 ? 'less than 1 mi' : `${Math.round(dist)} mi`;
      const payload = JSON.stringify({
        title: `${flagIcon} ${flagType}`,
        body: `${stopName} — ${distLabel} from your last stop`,
        data: { stop_name: stopName, flag_type: flagType }
      });

      try {
        await webPush.sendNotification(sub.subscription, payload);
        sent++;
      } catch (e) {
        console.error('Push failed for sub', sub.user_id, e);
      }
    }

    return new Response(JSON.stringify({ sent }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
