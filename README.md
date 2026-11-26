# Briefing de identidade visual — como publicar

Custo fixo: R$ 0 (GitHub Pages + Supabase gratuito). Tempo: cerca de 30 minutos, uma vez.

O que tem aqui:

| Arquivo | Para quê |
|---|---|
| `index.html` | O formulário que a cliente abre (`index.html?t=CÓDIGO`) |
| `admin.html` | Seu painel: criar links, ver respostas, ouvir áudios, baixar |
| `config.js` | Os dois dados de conexão com o Supabase |
| `schema.sql` | Cria o banco e as regras de segurança |
| `.github/workflows/keepalive.yml` | Evita que o Supabase gratuito pause por falta de uso |
| `img/`, `audio.mp3` | Imagens do termômetro e seu áudio de boas-vindas |

## 1. Supabase (banco e áudios)

1. Crie uma conta em supabase.com e um projeto novo. Escolha a região **South America (São Paulo)**. Guarde a senha do banco num gerenciador de senhas.
2. **Authentication → Users → Add user → Create new user.** Use o seu e-mail e uma senha forte, e marque "Auto Confirm User". Esse é o seu login do painel.
3. **Desligue o cadastro público.** Em Authentication → Sign In / Providers (ou "Settings"), desative **Allow new users to sign up**. Sem isso, qualquer pessoa poderia criar conta. O banco também só aceita o seu e-mail como admin, mas faça os dois.
4. Abra `schema.sql` num editor, troque `COLOQUE_SEU_EMAIL_AQUI` pelo e-mail do passo 2 (apenas esse texto, mantendo as aspas simples), copie tudo, cole em **SQL Editor → New query** e clique em **Run**. Deve aparecer "Success".
5. Em **Project Settings → API** copie o **Project URL** e a chave **publishable** (ou "anon"). Essas duas são públicas por desenho. **Nunca use** a chave `service_role` ou `secret`, e não cole nenhuma chave em conversas.

## 2. GitHub Pages (o site)

1. Crie um repositório novo e **público** (o GitHub Pages gratuito só publica repositórios públicos). Não há nada secreto aqui: os códigos dos links ficam só no banco.
2. Abra `config.js`, preencha `url` e `key` com os valores do passo 5 acima e envie todos os arquivos desta pasta para o repositório (inclusive a pasta `.github`).
3. **Settings → Pages → Build and deployment:** Source = *Deploy from a branch*, Branch = `main`, pasta `/ (root)`. Em alguns minutos o endereço aparece: `https://SEU-USUARIO.github.io/NOME-DO-REPO/`.
4. Se quiser usar um domínio próprio, configure em Settings → Pages → Custom domain.

## 3. Keep-alive (importante no plano gratuito)

O Supabase gratuito pausa o projeto depois de 7 dias com pouca atividade. Como você envia um briefing por mês, isso aconteceria. O agendamento diário resolve:

1. No repositório: **Settings → Secrets and variables → Actions → aba Variables → New repository variable.** Crie `SUPABASE_URL` e `SUPABASE_KEY` com os mesmos valores do `config.js`.
2. Aba **Actions → keepalive → Run workflow** para testar uma vez. Deve ficar verde.

Limite do GitHub: em repositório público, agendamentos são desligados se o repositório ficar 60 dias sem atividade. O próprio fluxo faz um commit vazio quando passam 45 dias parado, mas confira de vez em quando a aba Actions. Se aparecer o aviso de desativado, é só clicar em **Enable workflow**.

## 4. Uso no dia a dia

1. Abra `…/admin.html` e entre.
2. Escreva o nome da cliente (só você vê) → **Criar link**. O link é copiado.
3. Envie o link por WhatsApp. Ela pode pausar e voltar pelo mesmo link, em qualquer aparelho.
4. Volte ao painel quando quiser. Cada briefing mostra as respostas, os áudios para ouvir, **Copiar respostas como texto** e **Baixar (.zip)** com texto, dados e áudios.
5. **Cópia de segurança:** o plano gratuito não tem backup automático. Use "Baixar tudo (.zip)" no fim de cada briefing.

## Cuidados

- **Áudios:** ficam num armazenamento privado, só você ouve. O formulário avisa à cliente que você apaga se ela pedir. Para apagar: abra o briefing → **Excluir briefing e áudios**.
- **Regravações:** se ela regravar uma resposta, o arquivo anterior continua guardado até você excluir o briefing.
- **Link vazou ou foi enviado errado?** Crie outro link e exclua o antigo.
- **Painel mostra lista vazia mesmo com briefings?** O e-mail do `schema.sql` não é o mesmo do seu login. Corrija a função `is_admin` e rode de novo.
- **Limite do plano gratuito:** 1 GB de armazenamento. Um áudio de 1 minuto pesa cerca de 0,5 MB, então não é um problema para o seu volume.
- **Fontes:** o formulário carrega fontes do Google Fonts. Se quiser evitar essa conexão externa, hospede as fontes no repositório.
- **Transcrição:** não há. Os áudios ficam como áudio. Dá para acrescentar depois, com custo por minuto.
