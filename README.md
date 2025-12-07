# ♻️ Reciclofácil

> Aplicativo mobile para localização e cadastro de pontos de coleta de resíduos recicláveis.

## 📱 Sobre o Projeto

**Reciclofácil** é um aplicativo desenvolvido com React Native e Expo que facilita a localização de pontos de coleta de materiais recicláveis próximos ao usuário. O app permite que qualquer pessoa cadastre novos pontos, adicione fotos, faça avaliações e utilize filtros avançados para encontrar os ecopontos mais adequados às suas necessidades.

### 🎯 Objetivo

Promover a conscientização ambiental e facilitar o descarte correto de resíduos recicláveis, contribuindo para um planeta mais sustentável.

---

## ✨ Funcionalidades

- 📍 **Localização GPS** - Encontra pontos de coleta próximos à sua localização
- 🗺️ **Mapa Interativo** - Visualização dos pontos em mapa do Google Maps
- ➕ **Cadastro de Pontos** - Qualquer usuário pode adicionar novos ecopontos
- 📸 **Upload de Fotos** - Adicione fotos dos pontos (câmera ou galeria)
- ⭐ **Sistema de Avaliações** - Avalie pontos com estrelas (1-5) e comentários
- 🔍 **Filtros Avançados** - Filtre por tipo de resíduo e distância
- 🔔 **Notificações** - Receba alertas sobre novos pontos cadastrados
- 📊 **Detalhes Completos** - Veja avaliações, fotos e informações de cada ponto

### 🗑️ Tipos de Resíduos Suportados

- 📄 Papel
- 🧴 Plástico
- 🔩 Metal
- 🍶 Vidro
- 💻 Eletrônicos
- 🌱 Orgânicos

---

## 🛠️ Tecnologias Utilizadas

- **[React Native](https://reactnative.dev/)** - Framework mobile
- **[Expo](https://expo.dev/)** - Plataforma de desenvolvimento
- **[TypeScript](https://www.typescriptlang.org/)** - Linguagem de programação
- **[Supabase](https://supabase.com/)** - Backend as a Service (banco de dados e storage)
- **[Expo Location](https://docs.expo.dev/versions/latest/sdk/location/)** - Geolocalização
- **[Expo Image Picker](https://docs.expo.dev/versions/latest/sdk/imagepicker/)** - Upload de fotos
- **[Expo Notifications](https://docs.expo.dev/versions/latest/sdk/notifications/)** - Notificações push
- **[React Native Maps](https://github.com/react-native-maps/react-native-maps)** - Mapas interativos
- **[Lucide React Native](https://lucide.dev/)** - Ícones modernos

---

## 📋 Pré-requisitos

Antes de começar, você precisa ter instalado:

- **[Node.js](https://nodejs.org/)** (versão 18 ou superior)
- **[npm](https://www.npmjs.com/)** ou **[yarn](https://yarnpkg.com/)**
- **[Git](https://git-scm.com/)**
- **[Expo Go](https://expo.dev/go)** no celular (para testes)

---

## 🚀 Como Executar o Projeto

### 1️⃣ Clone o repositório

```bash
git clone https://github.com/seu-usuario/reciclofacil.git
cd reciclofacil
```

### 2️⃣ Instale as dependências

```bash
npm install
```

### 3️⃣ Configure o Supabase

1. Crie uma conta gratuita em [Supabase](https://supabase.com/)
2. Crie um novo projeto
3. Copie as credenciais (URL e API Key)
4. Crie o arquivo `lib/supabase.ts` com suas credenciais:

```typescript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'SUA_SUPABASE_URL';
const supabaseAnonKey = 'SUA_SUPABASE_ANON_KEY';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

5. Execute o SQL abaixo no **SQL Editor** do Supabase:

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.pontos_coleta (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  endereco TEXT NOT NULL,
  tipos_residuos TEXT[] NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  observacoes TEXT,
  foto_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  created_by UUID REFERENCES auth.users(id)
);

ALTER TABLE public.pontos_coleta
  ADD COLUMN IF NOT EXISTS foto_url TEXT;

ALTER TABLE public.pontos_coleta ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Pontos são públicos para leitura" ON public.pontos_coleta;
CREATE POLICY "Pontos são públicos para leitura"
  ON public.pontos_coleta FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Qualquer um pode criar pontos" ON public.pontos_coleta;
CREATE POLICY "Qualquer um pode criar pontos"
  ON public.pontos_coleta FOR INSERT
  TO public
  WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_pontos_lat_lng ON public.pontos_coleta (latitude, longitude);

CREATE TABLE IF NOT EXISTS public.avaliacoes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ponto_id UUID NOT NULL REFERENCES public.pontos_coleta(id) ON DELETE CASCADE,
  usuario_id TEXT NOT NULL,
  estrelas INTEGER NOT NULL CHECK (estrelas >= 1 AND estrelas <= 5),
  comentario TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(ponto_id, usuario_id)
);

ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Avaliações são públicas para leitura" ON public.avaliacoes;
CREATE POLICY "Avaliações são públicas para leitura"
  ON public.avaliacoes FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Qualquer um pode criar avaliações" ON public.avaliacoes;
CREATE POLICY "Qualquer um pode criar avaliações"
  ON public.avaliacoes FOR INSERT
  TO public
  WITH CHECK (true);


CREATE INDEX IF NOT EXISTS idx_avaliacoes_ponto ON public.avaliacoes (ponto_id);

INSERT INTO storage.buckets (id, name, public)
VALUES ('pontos-fotos', 'pontos-fotos', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'objects' AND n.nspname = 'storage'
  ) THEN

    BEGIN
      EXECUTE 'DROP POLICY IF EXISTS "Fotos são públicas para leitura" ON storage.objects';
    EXCEPTION WHEN OTHERS THEN
    END;
    BEGIN
      EXECUTE 'DROP POLICY IF EXISTS "Qualquer um pode fazer upload" ON storage.objects';
    EXCEPTION WHEN OTHERS THEN
    END;

    EXECUTE $sql$
      CREATE POLICY "Fotos são públicas para leitura"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'pontos-fotos')
    $sql$;

    EXECUTE $sql2$
      CREATE POLICY "Qualquer um pode fazer upload"
        ON storage.objects FOR INSERT
        TO public
        WITH CHECK (bucket_id = 'pontos-fotos')
    $sql2$;
  END IF;
END
$$;

```

### 4️⃣ Inicie o servidor

#### Opção A - Usando o arquivo .bat (Windows):

Clique duas vezes em:
```
Start Server.bat
```

#### Opção B - Via terminal:

```bash
npm start
```

ou

```bash
npx expo start --clear
```

---

## 📱 Como Testar em Outros Celulares

### Para Desenvolvedores/Testadores

#### 1️⃣ Instale o Expo Go

**Android:**
- [Play Store - Expo Go](https://play.google.com/store/apps/details?id=host.exp.exponent)

**iOS:**
- [App Store - Expo Go](https://apps.apple.com/app/expo-go/id982107779)

#### 2️⃣ Conecte-se ao App

**Método 1 - QR Code (mesma rede Wi-Fi):**

1. Execute o servidor (veja seção anterior)
2. Um QR Code aparecerá no terminal
3. No celular:
   - **Android:** Abra o Expo Go → Clique em "Scan QR Code"
   - **iOS:** Abra a câmera nativa → Aponte para o QR Code

**Método 2 - Link Direto (qualquer lugar):**

1. Execute com tunnel:
   ```bash
   npx expo start --tunnel
   ```
2. Copie o link que aparece (formato: `exp://u.expo.dev/...`)
3. Envie o link para os testadores via WhatsApp/Email
4. Eles abrem o link no celular
5. O app abre automaticamente no Expo Go

---

## 📂 Estrutura do Projeto

```
reciclofacil/
├── app/
│   ├── (tabs)/
│   │   └── index.tsx          # Tela principal do app
│   ├── _layout.tsx            # Layout raiz
│   └── +not-found.tsx         # Tela 404
├── assets/
│   └── images/
│       ├── icon.png           # Ícone do app (1024x1024)
│       ├── splash-icon.png    # Splash screen
│       ├── favicon.png        # Favicon
│       └── adaptive-icon.png  # Ícone Android
├── lib/
│   └── supabase.ts            # Configuração Supabase
├── app.json                   # Configuração do Expo
├── package.json               # Dependências
├── tsconfig.json              # Configuração TypeScript
├── Start Server.bat           # Atalho para iniciar (Windows)
└── README.md                  # Este arquivo
```

---

## 🎨 Paleta de Cores

- **Verde Principal:** `#059669`
- **Verde Claro:** `#10b981`
- **Verde Muito Claro:** `#d1fae5`
- **Fundo:** `#f0fdf4`
- **Texto:** `#1f2937`

---

## 🐛 Problemas Conhecidos

- Notificações push remotas não funcionam no Expo Go (apenas locais)
- iOS requer conta Apple Developer para distribuição

---

## 🔄 Atualizações Futuras

- [ ] Sistema de autenticação de usuários
- [ ] Edição e exclusão de pontos
- [ ] Compartilhamento nas redes sociais
- [ ] Histórico de pontos visitados
- [ ] Gamificação (pontos por reciclagem)
- [ ] Modo offline

---

## 🤝 Como Contribuir

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autores

- **Eduardo Fernandes Mendonça**
- **Jackson Lima Pinto**
- **Patrick Moraes Souza**
- **Pedro Macedo De Souza**
- **Peterson Duarte Arara**

---

## 🙏 Agradecimentos

- [Expo](https://expo.dev/) pela excelente plataforma de desenvolvimento
- [Supabase](https://supabase.com/) pelo backend poderoso e gratuito
- Comunidade open source por todas as bibliotecas utilizadas

---

## 📞 Suporte

Se encontrar algum problema ou tiver sugestões:

1. Abra uma [issue](https://github.com/seu-usuario/reciclofacil/issues)
2. Entre em contato por email
3. Envie um pull request

---

<p align="center">
  Feito com ♻️ e 💚 para um mundo mais sustentável
</p>

<p align="center">
  <a href="#-reciclofácil">Voltar ao topo</a>
</p>
