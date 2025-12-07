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

-- FIM
