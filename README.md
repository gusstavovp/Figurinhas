# Álbum Pedro Víctor — Supabase + Vercel

Aplicação Vite com cadastro e login por e-mail e senha, coleção de 110 figurinhas do Pedro Víctor, pacote diário, missões com minijogos, moedas Suco de Caju e progresso persistente no Supabase.

## Segurança dos dados

- A senha é gerenciada pelo Supabase Auth e nunca é gravada nas tabelas públicas.
- `profiles` guarda nome e e-mail.
- `album_progress` guarda figurinhas, moedas, pacote diário e total de pacotes.
- Row Level Security impede que um usuário leia o álbum de outro.
- A abertura dos pacotes acontece na função PostgreSQL `open_album_pack`, evitando alterações de moedas pelo navegador.
- Use somente a chave **publishable** no frontend. Nunca exponha uma chave `secret` ou `service_role`.

## 1. Criar e configurar o Supabase

1. Crie um projeto em [supabase.com](https://supabase.com/).
2. Abra **SQL Editor** e execute, em ordem, os arquivos de `supabase/migrations/`.
3. Em **Authentication → Providers → Email**, mantenha e-mail e senha habilitados.
4. Em **Connect**, copie a URL do projeto e a chave `sb_publishable_...`.

Crie `.env.local` usando `.env.example`:

```env
VITE_SUPABASE_URL=https://seu-projeto.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_sua_chave
```

## 2. Executar e verificar

```bash
pnpm install
pnpm dev
```

Para gerar a versão de produção:

```bash
pnpm build
```

## 3. GitHub e Vercel

Envie o projeto para um repositório GitHub. Na Vercel, importe esse repositório e cadastre as variáveis:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

O arquivo `vercel.json` já define o build e a pasta de saída.
