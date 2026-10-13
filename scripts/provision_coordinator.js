/**
 * SCRIPT ADMINISTRATIVO SERVER-SIDE DE PROVISIONAMENTO INICIAL
 * Uso no Windows PowerShell:
 *   $env:SUPABASE_URL="http://127.0.0.1:54321"
 *   $env:SUPABASE_SERVICE_ROLE_KEY="sua_chave_service_role"
 *   node scripts/provision_coordinator.js --email "coordenador@exemplo.com" --congregation "Congregação Central" --city "Salvador" --state "BA"
 *
 * AVISO: Nunca execute este script com chaves públicas (anon key).
 * Nunca inclua a service_role key no código-fonte ou no Flutter.
 */

const https = require('https');
const http = require('http');

function parseArgs() {
  const args = process.argv.slice(2);
  const params = {
    email: '',
    congregation: 'Congregação Central',
    city: 'Salvador',
    state: 'BA',
    code: 'BR-BA-001',
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--email' && args[i + 1]) {
      params.email = args[i + 1].trim().toLowerCase();
      i++;
    } else if (args[i] === '--congregation' && args[i + 1]) {
      params.congregation = args[i + 1].trim();
      i++;
    } else if (args[i] === '--city' && args[i + 1]) {
      params.city = args[i + 1].trim();
      i++;
    } else if (args[i] === '--state' && args[i + 1]) {
      params.state = args[i + 1].trim();
      i++;
    } else if (args[i] === '--code' && args[i + 1]) {
      params.code = args[i + 1].trim();
      i++;
    }
  }

  return params;
}

async function request(urlStr, options, data) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlStr);
    const client = url.protocol === 'https:' ? https : http;

    const req = client.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = body ? JSON.parse(body) : null;
          resolve({ status: res.statusCode, headers: res.headers, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, headers: res.headers, body });
        }
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(typeof data === 'string' ? data : JSON.stringify(data));
    }
    req.end();
  });
}

async function main() {
  const params = parseArgs();

  const supabaseUrl = process.env.SUPABASE_URL || 'http://127.0.0.1:54321';
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!params.email || !params.email.includes('@')) {
    console.error('❌ ERRO: Você deve informar um e-mail válido com --email "usuario@exemplo.com"');
    process.exit(1);
  }

  if (!serviceRoleKey) {
    console.error('❌ ERRO: A variável de ambiente SUPABASE_SERVICE_ROLE_KEY é obrigatória.');
    console.error('   Exemplo no PowerShell:');
    console.error('   $env:SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsIn..."');
    console.error('   node scripts/provision_coordinator.js --email "..."');
    process.exit(1);
  }

  console.log('🚀 Iniciando provisionamento administrativo...');
  console.log(`   E-mail autorizado: ${params.email}`);
  console.log(`   Congregação: ${params.congregation} (${params.city}/${params.state})`);

  const headers = {
    'apikey': serviceRoleKey,
    'Authorization': `Bearer ${serviceRoleKey}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // 1. Obter ou criar congregação
  let congregationId = null;
  const findCongregation = await request(
    `${supabaseUrl}/rest/v1/congregations?name=eq.${encodeURIComponent(params.congregation)}&select=id`,
    { method: 'GET', headers }
  );

  if (Array.isArray(findCongregation.body) && findCongregation.body.length > 0) {
    congregationId = findCongregation.body[0].id;
    console.log(`✅ Congregação encontrada com ID: ${congregationId}`);
  } else {
    const createCongregation = await request(
      `${supabaseUrl}/rest/v1/congregations`,
      { method: 'POST', headers },
      {
        name: params.congregation,
        code: params.code,
        city: params.city,
        state: params.state,
      }
    );
    if (Array.isArray(createCongregation.body) && createCongregation.body.length > 0) {
      congregationId = createCongregation.body[0].id;
      console.log(`✅ Congregação criada com ID: ${congregationId}`);
    } else {
      console.error('❌ Falha ao criar congregação:', createCongregation.body);
      process.exit(1);
    }
  }

  // 2. Verificar se o usuário já existe no Auth
  const findUser = await request(
    `${supabaseUrl}/auth/v1/admin/users`,
    { method: 'GET', headers }
  );

  let existingUser = null;
  if (findUser.body && Array.isArray(findUser.body.users)) {
    existingUser = findUser.body.users.find(
      (u) => (u.email || '').toLowerCase().trim() === params.email
    );
  }

  if (existingUser) {
    console.log(`ℹ️ Usuário já cadastrado encontrado com ID: ${existingUser.id}`);
    // Vincular diretamente
    const linkMember = await request(
      `${supabaseUrl}/rest/v1/congregation_members`,
      { method: 'POST', headers: { ...headers, 'Prefer': 'resolution=merge-duplicates' } },
      {
        congregation_id: congregationId,
        user_id: existingUser.id,
        role: 'COORDINATOR',
        status: 'ACTIVE',
      }
    );
    console.log('✅ Usuário vinculado com sucesso como COORDINATOR da congregação!');
  } else {
    console.log('ℹ️ Usuário ainda não efetuou o primeiro login. Gerando convite administrativo...');

    // Revogar convites pendentes antigos
    await request(
      `${supabaseUrl}/rest/v1/invitations?email=eq.${encodeURIComponent(params.email)}&congregation_id=eq.${congregationId}&status=eq.PENDING`,
      { method: 'PATCH', headers },
      { status: 'REVOKED' }
    );

    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    const createInvitation = await request(
      `${supabaseUrl}/rest/v1/invitations`,
      { method: 'POST', headers },
      {
        email: params.email,
        congregation_id: congregationId,
        role: 'COORDINATOR',
        status: 'PENDING',
        expires_at: expiresAt,
      }
    );

    if (Array.isArray(createInvitation.body) && createInvitation.body.length > 0) {
      console.log(`✅ Convite administrativo criado! ID: ${createInvitation.body[0].id}`);
      console.log(`   O usuário ${params.email} receberá o convite assim que efetuar o login com o Google.`);
    } else {
      console.error('❌ Falha ao criar convite:', createInvitation.body);
      process.exit(1);
    }
  }

  console.log('🎉 Provisionamento inicial concluído com sucesso.');
}

main().catch((err) => {
  console.error('❌ Erro inesperado:', err);
  process.exit(1);
});
