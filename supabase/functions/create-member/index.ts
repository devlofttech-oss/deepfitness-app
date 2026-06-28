import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader = req.headers.get('Authorization') ?? '';

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) throw new Error('Not authenticated.');

    const { data: trainerProfile, error: profileError } = await userClient
      .from('users')
      .select('id,name,role')
      .eq('id', user.id)
      .single();
    if (profileError || trainerProfile?.role !== 'trainer') {
      throw new Error('Only trainers can create members.');
    }

    const body = await req.json();
    const name = String(body.name ?? '').trim();
    const email = String(body.email ?? '').trim() || undefined;
    const phone = normalizePhone(String(body.phone ?? '').trim()) || undefined;
    const password = String(body.password ?? '');
    const goal = String(body.goal ?? '').trim();
    const age = Number(body.age ?? 0) || null;
    const heightCm = Number(body.height_cm ?? 0) || null;
    const weight = Number(body.weight ?? 0) || null;

    if (!name || (!email && !phone) || password.length < 6 || !goal) {
      throw new Error('Name, email or phone, goal, and a 6+ character password are required.');
    }

    const { data: authData, error: createError } =
      await adminClient.auth.admin.createUser({
        email,
        phone,
        password,
        email_confirm: Boolean(email),
        phone_confirm: Boolean(phone),
        user_metadata: {
          name,
          role: 'member',
          trainer_id: user.id,
          goal,
          age,
          height_cm: heightCm,
        },
      });
    if (createError) throw createError;

    const memberId = authData.user.id;
    await adminClient.from('users').upsert({
      id: memberId,
      name,
      email: email ?? null,
      phone: phone ?? null,
      role: 'member',
    });
    await adminClient.from('members').upsert({
      id: memberId,
      trainer_id: user.id,
      goal,
      age,
      height_cm: heightCm,
    });
    if (weight !== null) {
      await adminClient.from('measurements').insert({
        member_id: memberId,
        trainer_id: user.id,
        weight,
        notes: 'Initial measurement',
      });
    }

    const login = email ?? phone;
    const inviteText = [
      `Hi ${name}, your Deep Fitness account is ready.`,
      `Login: ${login}`,
      `Temporary password: ${password}`,
      'Open the Deep Fitness app and change your password after login.',
    ].join('\n');

    return json({
      member: {
        id: memberId,
        name,
        email: email ?? '',
        phone: phone ?? '',
        goal,
        age,
        height_cm: heightCm,
        weight,
        trainer_name: trainerProfile.name,
      },
      invite_text: inviteText,
    });
  } catch (error) {
    return json({ error: error.message ?? String(error) }, 400);
  }
});

function normalizePhone(value: string): string | null {
  if (!value) return null;
  const compact = value.replace(/\s+/g, '');
  return compact.startsWith('+') ? compact : `+91${compact}`;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
