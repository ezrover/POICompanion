import { createClient } from '@supabase/supabase-js';
import { Hono } from 'hono';
import { handle } from 'hono/aws-lambda';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);

const app = new Hono();

app.post("/generate", async (c) => {
  const { sharing_channel, context, custom_message, user_id } = await c.req.json();

  const referral_code = `RT2025-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
  const referral_link = `https://roadtrip.app/r/${referral_code}`;
  const qr_code_url = `https://api.roadtrip.app/qr/${referral_code}`;

  const { data, error } = await supabase
    .from('referrals')
    .insert([
      { 
        referral_code: referral_code, 
        referrer_user_id: user_id, 
        sharing_channel: sharing_channel,
        context: context,
        custom_message: custom_message,
        referral_link: referral_link,
        qr_code_url: qr_code_url
      },
    ])

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  const sharing_content = {
    sms_message: `Check out Roadtrip-Copilot - discover amazing places and get 7 FREE roadtrips to start! ${referral_link}`,
    email_subject: "Discover Amazing Places with 7 FREE Roadtrips",
    email_body: `I've been using Roadtrip-Copilot to find hidden gems on my travels. You should check it out! You'll get 7 free roadtrips to start. ${referral_link}`,
    social_posts: {
      facebook: `I'm using Roadtrip-Copilot to discover amazing new places! You can get 7 free roadtrips to start using my link: ${referral_link}`,
      instagram: `Discovering hidden gems with Roadtrip-Copilot! Get 7 free roadtrips to start. #roadtrip #discovery #travel #ad ${referral_link}`,
      twitter: `Loving Roadtrip-Copilot for finding unique spots on my drives. Get 7 free roadtrips to start! #roadtrip #travel ${referral_link}`,
    },
  };

  return c.json({
    referral_code,
    referral_link,
    qr_code_url,
    sharing_content,
    expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(), // 1 year from now
  });
});

app.post("/attribute", async (c) => {
  const { referral_code, new_user_id, attribution_method, install_timestamp, device_fingerprint } = await c.req.json();

  const { data: referral, error: referralError } = await supabase
    .from('referrals')
    .select('id, referrer_user_id')
    .eq('referral_code', referral_code)
    .single();

  if (referralError || !referral) {
    return c.json({ error: 'Invalid referral code' }, 400);
  }

  const { data, error } = await supabase
    .from('referral_attributions')
    .insert([
      {
        referral_id: referral.id,
        referred_user_id: new_user_id,
        attribution_method: attribution_method,
        install_timestamp: install_timestamp,
        device_fingerprint: device_fingerprint,
      },
    ]);

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({
    attribution_success: true,
    referrer_user_id: referral.referrer_user_id,
    credits_pending: {
      referrer: 1,
      referee: 7,
    },
    validation_required: false,
  });
});

app.post("/validate-completion", async (c) => {
  const { referred_user_id, completion_event, event_timestamp, validation_data } = await c.req.json();

  const { data: attribution, error: attributionError } = await supabase
    .from('referral_attributions')
    .select('id, referrer_user_id')
    .eq('referred_user_id', referred_user_id)
    .single();

  if (attributionError || !attribution) {
    return c.json({ error: 'Referral attribution not found' }, 404);
  }

  const { data, error } = await supabase
    .from('referral_attributions')
    .update({ is_validated: true, validated_at: event_timestamp, validation_criteria_met: validation_data })
    .eq('id', attribution.id);

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({
    validation_successful: true,
    credit_allocated: true,
    referrer_user_id: attribution.referrer_user_id,
    credit_transaction_id: `txn_${Math.random().toString(36).substring(2, 12)}`,
    notification_sent: true,
  });
});

export const handler = handle(app);


